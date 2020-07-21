`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/21 20:18:05
// Design Name: 
// Module Name: Issue_RF_regs
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

module Issue_RF_regs(
    input   wire        clk,
    input   wire        rst,

    Ctrl.slave          ctrl_issue_rf_regs,

    input   UOPBundle   issueBundle,
    input   wire        primPauseReq,
    output  UOPBundle   rfBundle,
    output  PRFrNums    prfRequest
);

    always_ff @ (posedge clk) begin
        if(rst || ctrl_issue_rf_regs.flush) begin
            rfBundle.valid  <= `FALSE;
            prfRequest      <= 0;
        end else if(primPauseReq || ctrl_issue_rf_regs.pause) begin
            rfBundle        <= rfBundle;
            prfRequest      <= prfRequest;
        end else begin
            rfBundle        <= issueBundle;
            prfRequest.rs0  <= issueBundle.op0PAddr;
            prfRequest.rs1  <= issueBundle.op1PAddr;
        end
    end

endmodule
