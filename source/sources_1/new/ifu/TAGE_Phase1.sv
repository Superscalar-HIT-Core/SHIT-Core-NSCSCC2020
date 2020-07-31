`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Tage分支预测器，历史长度10，20，40，80
//////////////////////////////////////////////////////////////////////////////////


module TAGE_Phase1(
    input clk,
    input rst,
    input pause,
    input recover,
    // 是否需要Flush Useful Bit
    input flush_ubits_hi, flush_ubits_lo,
    // 访问Tage的四个Index
    input TAGEIndex [3:0] index,
    // For branch prediction
    output TAGETag [3:0] PCTags,
    output TAGEPred TAGEResp,
    output PredTaken,
    // For branch prediction update
    input committed_branch_taken,
    input [31:0] committed_pc,
    input commit_valid,
    input TAGEPred committed_pred_info,
    input committed_branch_taken,
    input commited_mispred
    );

    // Predict Phase 1: Get the result and select the result
    TAGECtr [3:0] ctr;
    TAGEUseful[3:0] useful;
    TAGETag[3:0] tag;
    wire [3:0] TAGE_hit;
    wire [1:0] provider, alter;
    wire [3:0] update_en;
    TAGEPred [3:0] update_info;
    wire [3:0] inc_useful;
    wire [3:0] dec_useful;
    genvar i;
    generate;
        for(i = 0; i < 4; i++) begin
        TageBank hist(
            .clk(clk),
            .rst(rst),
            .index_in(index[i]),
            .tag_in(PCTags[i]),
            .ctr_out(ctr[i]),
            .useful_out(useful[i]),
            .hit_out(TAGE_hit[i]),
            .update_en(update_en[i]),
            .update_info(update_info[i]),
            .update_useful(update_useful[i]),
            .inc_useful(inc_useful[i]),
            .dec_useful(dec_useful[i]),
            .reset_useful(reset_useful[i]),
            .refreshUsefulHi(flush_ubits_hi),
            .refreshUsefulLo(flush_ubits_lo)
        );
        end
    endgenerate

    assign TAGE_hit = |hit ;

    assign provider =   hit[3] ? 3 :
                        hit[2] ? 2 :
                        hit[1] ? 1 :
                        hit[0] ? 0 : 0;
    wire [3:0] alter_mask;
    wire alter_hit;
    assign alter_mask = ( hit & ~(1 << provider) );
    assign alter_hit = |alter_mask;
    assign alter =      alter_mask[3] ? 3 :
                        alter_mask[2] ? 2 :
                        alter_mask[1] ? 1 :
                        alter_mask[0] ? 0 : 0;
    
    assign TAGEResp.hit                 = TAGE_hit;
    assign TAGEResp.ctr                 = ctr;
    assign TAGEResp.index               = index;
    assign TAGEResp.has_alter           = (hit && alter_hit);   // 决定是否更新Useful
    assign TAGEResp.provider            = provider;             // 提供预测的是哪个
    assign TAGEResp.useful              = useful;               // 四个Useful Bits
    assign PredTaken                    = ctr[provider][2];


    // Update when prediction is correct
    /*
    input committed_branch_taken,
    input [31:0] committed_pc,
    input commit_valid,
    input TAGEPred committed_pred_info,
    input committed_branch_taken,
    input commited_mispred
    */
    wire [7:0] random_num;
    // 线性反馈移位寄存器
    // Generate psudo random nums
    RandGen randgen(
        .clk(clk),
        .rst(rst),
        .random_seed(8'b11111111),
        .random_num(random_num)
    );

    wire prob_two_thirds = random_num < 8'd170; // Approximately 2/3


    // Update Logic
    // Update enable
    // At most one Line in one BANK will be updated
    // 对于Provider的更新
    wire not_useful_0 = committed_pred_info.useful[0] == 0;
    wire not_useful_1 = committed_pred_info.useful[1] == 0;
    wire not_useful_2 = committed_pred_info.useful[2] == 0;
    wire not_useful_3 = committed_pred_info.useful[3] == 0;
    wire [3:0] free_useful_vec = ~{ not_useful_3, not_useful_2, not_useful_1, not_useful_0 };
    wire [3:0] provider_mask =  committed_pred_info.provider == 2'b00 ? 4'b1110 : 
                                committed_pred_info.provider == 2'b01 ? 4'b1100 :
                                committed_pred_info.provider == 2'b10 ? 4'b1000 : 4'b0000 ;
    wire [3:0] allocate_mask = provider_mask & free_useful_vec;
    wire has_free_entry = |allocate_mask;
    reg [1:0] entry_to_allocate, alter_entry_to_allocate, major_entry_to_allocate;
    reg [3:0] allocate_mask_2;
    reg has_alter_free;

    always_comb begin
        entry_to_allocate = 0;
        has_alter_free = 1;
        major_entry_to_allocate = 0;
        alter_entry_to_allocate = 0;
        case(allocate_mask)
            4'b1110: major_entry_to_allocate = 2'b01;
            4'b1100: major_entry_to_allocate = 2'b10;
            4'b1000: major_entry_to_allocate = 2'b11;
            default: major_entry_to_allocate = 2'b00;
        endcase
        allocate_mask_2[major_entry_to_allocate] = 0;
        case(allocate_mask_2)
            4'b1110: alter_entry_to_allocate = 2'b01;
            4'b1100: alter_entry_to_allocate = 2'b10;
            4'b1000: alter_entry_to_allocate = 2'b11;
            default: begin
                alter_entry_to_allocate = 2'b00;
                has_alter_free = 0;
            end
        endcase
        if(has_alter_free) begin
            entry_to_allocate = prob_two_thirds ? major_entry_to_allocate : alter_entry_to_allocate;
        end else begin
            entry_to_allocate = major_entry_to_allocate;
        end
    end

    always_comb begin
        update_en = 0;
        inc_useful = 0;
        dec_useful = 0;
        update_info = 0;
        reset_useful = 0;
        if(commit_valid)    begin
            if(committed_pred_info.hit) begin           // 如果预测的结果是从预测器出来的
                // 对于Provider的更新
                update_en[committed_pred_info.provider] = 1;
                // Useful bit
                if(committed_pred_info.has_alter) begin // 需要更新useful bit
                    inc_useful[committed_pred_info.provider] = ~commited_mispred;
                    dec_useful[committed_pred_info.provider] = commited_mispred;
                end
                // Counter 
                if(commited_mispred)    begin   // 预测错误，减小计数器
                    update_info[committed_pred_info.provider].ctr = committed_pred_info.ctr == 2'b00 ? 2'b00 : committed_pred_info.ctr - 2'b01;
                end else begin                  // 预测正确，增大计数器
                    update_info[committed_pred_info.provider].ctr = committed_pred_info.ctr == 2'b11 ? 2'b11 : committed_pred_info.ctr + 2'b01;
                end
                // 如果预测失败，并且不是使用最长历史，还需要尝试分配一个新的项
            end
            if(commited_mispred && committed_pred_info.provider != 2'b11)    begin
                if(has_free_entry)  begin   // 分配一个新的项
                    update_en[entry_to_allocate] = 1;
                    reset_useful[entry_to_allocate] = 1;
                    update_info[entry_to_allocate].ctr = 3'b100;
                end else begin              // 对于i>j，将所有的useful减1，并不分配
                    dec_useful = dec_useful | provider_mask;
                end
            end
        end
    end

endmodule
