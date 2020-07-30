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
    output TAGETag PCTag,
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
    TAGEPred update_info;
    genvar i;
    generate;
        for(i = 0; i < 4; i++) begin
        TageBank hist(
            .clk(clk),
            .rst(rst),
            .index(index[i]),
            .ctr(ctr[i]),
            .useful(useful[i]),
            .tag(tag[i]),
            .update_hist(update_en[i]),
            .update_info(update_info),
            .refreshUsefulHi(flush_ubits_hi),
            .refreshUsefulLo(flush_ubits_lo),
            .hit(TAGE_hit[i])
        );
        end
    endgenerate

    assign TAGE_hit = |hit ;

    assign provider =   hit[3] ? 3 :
                        hit[2] ? 2 :
                        hit[1] ? 1 :
                        hit[0] ? 0 : 0;
    wire [3:0] alter_mask;
    wire alter_hit
    assign alter_mask = ( hit & ~(1 << provider) );
    assign alter_hit = |alter_mask;
    assign alter =      alter_mask[3] ? 3 :
                        alter_mask[2] ? 2 :
                        alter_mask[1] ? 1 :
                        alter_mask[0] ? 0 : 0;
    
    assign TAGEResp.hit                 = TAGE_hit;
    assign TAGEResp.ctr                 = ctr;
    assign TAGEResp.index               = index;
    assign TAGEResp.has_alter           = (hit && alter_hit);
    assign TAGEResp.provider            = provider;
    assign TAGEResp.useful              = useful;
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

    // Update Logic
    // Update enable
    // At most one Line in one BANK will be updated
    always_comb begin
        
    end
    // Condition 1: Not allocated
    reg [1:0] new_provider_to_allocate;
    reg dec_all_ubits;
    


    wire [7:0] random_num;
    // 线性反馈移位寄存器
    // Generate psudo random nums
    RandGen rand(
        .clk(clk),
        .rst(rst),
        .random_seed(8'b11111111),
        .random_num(random_num)
    );

    wire prob_two_thirds = random_num < 8'd170; // Approximately 2/3

endmodule
