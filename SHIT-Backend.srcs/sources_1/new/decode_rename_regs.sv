`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/16 00:14:32
// Design Name: 
// Module Name: decode_rename_regs
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
`include "defines/defines.svh"

module decode_rename_regs(
    input   wire        clk,
    input   wire        rst,

    Ctrl.slave          ctrl_decode_rename_regs,

    Decode_Regs.regs    decode0_regs,
    Decode_Regs.regs    decode1_regs,

    Regs_Dispatch.regs  regs_dispatch
);

    logic       full;
    logic       lastIsFull;
    uOPBundle   uOP0, uOP1, uOP2, uOP3;

    assign full = (uOP1.valid || uOP2.valid) && !lastIsFull;
    assign ctrl_decode_rename_regs.pauseReq = full;
    
    always_ff @ (posedge clk) begin
        if(rst || ctrl_decode_rename_regs.flush) begin
            uOP0.valid  <= `FALSE;
            uOP1.valid  <= `FALSE;
            uOP2.valid  <= `FALSE;
            uOP3.valid  <= `FALSE;
            lastIsFull  <= `FALSE;
        end else if(ctrl_decode_rename_regs.pause || lastIsFull) begin
            uOP0        <= uOP0;
            uOP1        <= uOP1;
            uOP2        <= uOP2;
            uOP3        <= uOP3;
            lastIsFull  <= lastIsFull;
        end else begin
            uOP0        <= decode0_regs.uOP0;
            uOP1        <= decode0_regs.uOP1;
            uOP2        <= decode1_regs.uOP0;
            uOP3        <= decode1_regs.uOP1;
            lastIsFull  <= full;
        end
    end

    always_comb begin
        if(lastIsFull) begin
            regs_dispatch.uOP0  = uOP2;
            regs_dispatch.uOP1  = uOP3;
        end else if(full) begin
            regs_dispatch.uOP0  = uOP0;
            regs_dispatch.uOP1  = uOP1;
        end else begin
            regs_dispatch.uOP0  = uOP0;
            regs_dispatch.uOP1  = uOP2;
        end
    end

endmodule
