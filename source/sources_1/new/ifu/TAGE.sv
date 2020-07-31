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
    

endmodule
