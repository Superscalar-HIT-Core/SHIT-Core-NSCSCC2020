`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Tage分支预测器，历史长度10，20，40，80
//////////////////////////////////////////////////////////////////////////////////


module TAGE(
    input clk,
    input rst,
    input pause,
    input recover,
    input branch_happen,
    // For branch prediction
    input [31:0] br_pc,
    output pred_taken,
    output TAGEPred pred_info,
    // For branch prediction update
    input [31:0] committed_pc,
    input TAGEPred committed_pred_info,
    input committed_taken
    );

    reg [9:0] hist_10;
    reg [19:0] hist_20;
    reg [39:0] hist_40;
    reg [79:0] hist_80;

    wire [9:0] folded_hist_10;
    wire [9:0] folded_hist_20;
    wire [9:0] folded_hist_30;
    wire [9:0] folded_hist_40;

    wire TAGE_hit;

    TAGEIndex [3:0] index;

    // Global: Useful bit refresh


    // Predict Phase 0: Index generation logic
    // TODO: Design the function to generate pc tag
    TAGETag PCTag;
    // TAGE Indexing Logic
    assign folded_hist_10 = hist_10;
    assign folded_hist_20 = hist_20[19:10] ^ hist_20[9:0];
    assign folded_hist_40 = ( hist_40[19:10] ^ hist_40[9:0] ) ^ 
                            ( hist_40[39:30] ^ hist_40[29:20] );
    assign folded_hist_80 = ( (hist_80[19:10] ^ hist_80[9:0] ) ^ 
                            ( hist_80[39:30] ^ hist_80[29:20] ) ) ^ 
                            ( (hist_80[49:40] ^ hist_80[59:50] ) ^ 
                            ( hist_80[69:60] ^ hist_80[79:70] ) );

    assign index[0] = folded_hist_10 ^ pc[13:4];
    assign index[1] = folded_hist_20 ^ pc[13:4];
    assign index[2] = folded_hist_40 ^ pc[13:4];
    assign index[3] = folded_hist_80 ^ pc[13:4];

    // Phase 0/1 Regs

    

    // Predict Phase 1: Get the result and select the result

    TAGECtr [3:0] ctr;
    TAGEUseful[3:0] useful;
    wire [3:0] hit;
    genvar i;
    generate;
        for(i = 0; i < 4; i++) begin
        TageBank hist(
            .clk(clk),
            .rst(rst),
            .index(index[i]),
            .ctr(ctr[i]),
            .useful(useful[i]),
            .update_hist(),
            .new_index(),
            .new_ctr(),
            .new_useful(),
            .new_tag(),
            .refreshUsefulHi(),
            .refreshUsefulLo()
        );
        end
    endgenerate

    assign TAGE_hit = hit[0] | hit[1] | hit[2] | hit[3];

endmodule
