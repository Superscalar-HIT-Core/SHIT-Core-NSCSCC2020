`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/21 20:18:05
// Design Name: 
// Module Name: RF_FU_regs
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

module RF_FU_regs(
    input  wire         clk,
    input  wire         rst,
    
    Ctrl.slave          ctrl_rf_fu_regs,
    input  wire         primPauseReq,

    input  UOPBundle    rfBundle,
    input  PRFrData     rfRes,

    output UOPBundle    fuBundle,
    output PRFrData     fuOprands
);

    always_ff @ (posedge clk) begin
        if(rst || ctrl_rf_fu_regs.flush) begin
            fuBundle        <= 0;
            fuOprands       <= 0;
        end else if(primPauseReq || ctrl_rf_fu_regs.pause) begin
            fuBundle        <= fuBundle;
            fuOprands       <= fuOprands;
        end else begin
            fuBundle        <= rfBundle;
            fuOprands       <= rfRes;
        end
    end

endmodule
