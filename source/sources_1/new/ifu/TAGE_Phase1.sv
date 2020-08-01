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
    input TAGEIndex [3:0] indexes,
    // For branch prediction
    output TAGETag [3:0] PCTags,
    output TAGEPred TAGEResp,
    output PredTaken,
    // For branch prediction update
    input committed_branch_taken,
    input [31:0] committed_pc,
    input commit_valid,
    input TAGEPred committed_pred_info,
    input committed_mispred
    );
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


    // Predict Phase 1: Get the result and select the result
    TAGECtr [3:0] ctr;
    TAGEUseful[3:0] useful;
    TAGETag[3:0] tag;
    // 更新Tage的信号
    reg       [3:0] update_en;
    TAGETag   [3:0] update_tag;
    TAGECtr   [3:0] update_ctr;
    TAGEIndex [3:0] update_index;
    reg       [3:0] update_useful;
    reg       [3:0] reset_useful;
    reg       [3:0] inc_useful;
    reg       [3:0] dec_useful;

    wire [3:0] TAGE_hit;
    wire [1:0] provider, alter;

    genvar i;
    generate;
        for(i = 0; i < 4; i++) begin
        TageBank hist(
            .clk(clk),
            .rst(rst),
            .index_in(indexes[i]),
            .tag_in(PCTags[i]),
            .ctr_out(ctr[i]),
            .useful_out(useful[i]),
            .hit_out(TAGE_hit[i]),
            .update_en(update_en[i]),
            .update_index(update_index[i]),
            .update_tag(update_tag[i]),
            .update_ctr(update_ctr[i]),
            .update_useful(update_useful[i]),
            .inc_useful(inc_useful[i]),
            .dec_useful(dec_useful[i]),
            .reset_useful(reset_useful[i]),
            .refreshUsefulHi(flush_ubits_hi),
            .refreshUsefulLo(flush_ubits_lo)
        );
        end
    endgenerate

    assign hit = |TAGE_hit ;

    assign provider =   TAGE_hit[3] ? 3 :
                        TAGE_hit[2] ? 2 :
                        TAGE_hit[1] ? 1 :
                        TAGE_hit[0] ? 0 : 0;
    wire [3:0] alter_mask;
    wire alter_hit;
    assign alter_mask = ( hit & ~(1 << provider) );
    assign alter_hit = |alter_mask;
    assign alter =      alter_mask[3] ? 3 :
                        alter_mask[2] ? 2 :
                        alter_mask[1] ? 1 :
                        alter_mask[0] ? 0 : 0;
    // Update Logic
    // 在预测结果输出的时候，事先计算如果预测失败的时候分配的项
    // 对于Provider的更新，预先计算分配逻辑
    wire not_useful_0 = ( useful[0] == 0 );
    wire not_useful_1 = ( useful[1] == 0 );
    wire not_useful_2 = ( useful[2] == 0 );
    wire not_useful_3 = ( useful[3] == 0 );
    wire [3:0] free_useful_vec = ~{ not_useful_3, not_useful_2, not_useful_1, not_useful_0 };
    wire [3:0] provider_mask =  provider == 2'b00 ? 4'b1110 : 
                                provider == 2'b01 ? 4'b1100 :
                                provider == 2'b10 ? 4'b1000 : 4'b0000 ;
    wire [3:0] allocate_mask = provider_mask & free_useful_vec;
    wire has_free_entry = |allocate_mask;
    reg [1:0] entry_to_allocate, alter_entry_to_allocate, major_entry_to_allocate;
    reg [3:0] allocate_mask_2;
    reg has_alter_free;
    reg [1:0] new_to_allocate;
    always_comb begin
        entry_to_allocate = 0;
        has_alter_free = 1;
        major_entry_to_allocate = 0;
        alter_entry_to_allocate = 0;
        allocate_mask_2 = allocate_mask;
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
        if(!hit)    begin
            entry_to_allocate = 0;
        end
    end
    assign TAGEResp.hit                 = TAGE_hit;
    assign TAGEResp.ctr                 = ctr[provider];
    assign TAGEResp.hit_tag             = PCTags[provider];
    assign TAGEResp.hit_index           = indexes[provider];
    assign TAGEResp.on_mispred_tag      = PCTags[entry_to_allocate];
    assign TAGEResp.on_mispred_index    = indexes[entry_to_allocate];
    assign TAGEResp.on_mispred_bank     = entry_to_allocate;
    assign TAGEResp.has_free_to_alloc   = has_alter_free;
    assign TAGEResp.has_alter           = (hit && alter_hit);   // 决定是否更新Useful
    assign TAGEResp.provider            = provider;             // 提供预测的是哪个
    assign PredTaken                    = ctr[provider][2];


    // Update when prediction is correct

    always_comb begin
        update_en = 0;
        inc_useful = 0;
        dec_useful = 0;
        reset_useful = 0;
        new_to_allocate = 0;
        update_index = 0;
        update_tag = 0;
        if(commit_valid)    begin
            if(committed_pred_info.hit) begin           // 如果预测的结果是从预测器出来的
                // 对于Provider的更新
                update_en[committed_pred_info.provider] = 1;
                update_index[committed_pred_info.provider] = committed_pred_info.hit_index;
                // Useful bit
                if(committed_pred_info.has_alter) begin // 需要更新useful bit
                    inc_useful[committed_pred_info.provider] = ~committed_mispred;
                    dec_useful[committed_pred_info.provider] = committed_mispred;
                end
                // Counter 
                if(committed_mispred)    begin   // 预测错误，减小计数器
                    update_ctr[committed_pred_info.provider] = committed_pred_info.ctr == 2'b00 ? 2'b00 : committed_pred_info.ctr - 2'b01;
                end else begin                  // 预测正确，增大计数器
                    update_ctr[committed_pred_info.provider] = committed_pred_info.ctr == 2'b11 ? 2'b11 : committed_pred_info.ctr + 2'b01;
                end
                update_tag[committed_pred_info.provider] = committed_pred_info.hit_tag;
            end
            if(committed_mispred && committed_pred_info.provider != 2'b11)    begin
                // 如果预测失败，并且不是使用最长历史，还需要尝试分配一个新的项
                if(committed_pred_info.has_free_to_alloc)  begin   // 分配一个新的项
                    update_en[committed_pred_info.on_mispred_bank] = 1;
                    reset_useful[committed_pred_info.on_mispred_bank] = 1;
                    update_ctr[committed_pred_info.on_mispred_bank] = committed_branch_taken ? 3'b100 : 3'b011;
                end else begin              // 对于i>j，将所有的useful减1，并不分配
                    for( integer i = 0; i<4; i++ )  begin
                        if( i>committed_pred_info.provider )  dec_useful[i] = 1;
                    end
                end
            end
        end else begin                      // 如果没有Hit，就分配第0个
            update_en[0] = 1;
            update_ctr[0] = committed_branch_taken ? 3'b100 : 3'b011;
            update_index[0] = committed_pred_info.on_mispred_index;
            update_tag[0] = committed_pred_info.on_mispred_tag;
            reset_useful[0] = 1;
        end
    end

endmodule
