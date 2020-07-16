`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/09 18:41:29
// Design Name: 
// Module Name: IF_0
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
`include "defs.sv"

module IF_0(
    IF0_Regs.if0            if0_regs
);

    assign if0_regs.inst0.pc        = if0_regs.PC;
    assign if0_regs.inst1.pc        = if0_regs.PC | 32'h0000_0004;

    assign if0_regs.inst0.valid     = ~if0_regs.PC[2];
    assign if0_regs.inst1.valid     = `TRUE;

    always_comb begin
        if0_regs.nPC           =   (if0_regs.PC & 32'hFFFF_FFF8) + 32'h0000_0008;
    end

endmodule
