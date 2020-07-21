`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/21 20:37:19
// Design Name: 
// Module Name: FU_Output_regs
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../defines/defines.svh"

module FU_Output_regs(
    input  wire     clk,
    input  wire     rst,

    Ctrl.slave      ctrl_fu_output_regs,

    input  PRFwInfo fuWbData,
    FU_ROB.rob      fuCommitInfo,

    output PRFwInfo prfWReq,
    FU_ROB.fu       commitInfo
);

    always_ff @ (posedge clk) begin
        if(rst || ctrl_fu_output_regs.flush) begin
            prfWReq.wen             <= `FALSE;
            commitInfo.setFinish    <= `FALSE;
        end else begin  // no pause
            prfWReq                 <= fuWbData;
            commitInfo              <= fuCommitInfo;
        end
    end

endmodule
