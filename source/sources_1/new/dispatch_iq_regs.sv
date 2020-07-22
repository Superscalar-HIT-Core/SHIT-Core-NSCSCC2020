`timescale 1ns / 1ps
`include "defines/defines.svh"
module dispatch_iq_regs(
    input clk,
    input rst,
    input flush,
    input pausereq,
    input rs_alu_wen_0_i, rs_alu_wen_1_i, 
    input rs_mdu_wen_0_i, 
    input rs_lsu_wen_0_i, rs_lsu_wen_1_i,
    input ALU_Queue_Meta rs_alu_dout_0_i, rs_alu_dout_1_i,
    input MDU_Queue_Meta rs_mdu_dout_0_i,
    input LSU_Queue_Meta rs_lsu_dout_0_i, rs_lsu_dout_1_i,
    output rs_alu_wen_0, rs_alu_wen_1, 
    output rs_mdu_wen_0, 
    output rs_lsu_wen_0, rs_lsu_wen_1,
    output ALU_Queue_Meta rs_alu_dout_0, rs_alu_dout_1,
    output MDU_Queue_Meta rs_mdu_dout_0,
    output LSU_Queue_Meta rs_lsu_dout_0, rs_lsu_dout_1
    );
always @(posedge clk)   begin
    if(rst) begin
        rs_alu_wen_0    <= 0;
        rs_alu_wen_1    <= 0;
        rs_mdu_wen_0    <= 0;
        rs_lsu_wen_0    <= 0;
        rs_lsu_wen_1    <= 0;
        rs_alu_dout_0   <= 0;
        rs_alu_dout_1   <= 0;
        rs_mdu_dout_0   <= 0;
        rs_lsu_dout_0   <= 0;
        rs_lsu_dout_1   <= 0;
    end else if (pausereq)  begin
        rs_alu_wen_0    <= 0;
        rs_alu_wen_1    <= 0;
        rs_mdu_wen_0    <= 0;
        rs_lsu_wen_0    <= 0;
        rs_lsu_wen_1    <= 0;
    end else begin
        rs_alu_wen_0    <= rs_alu_wen_0_i;
        rs_alu_wen_1    <= rs_alu_wen_1_i;
        rs_mdu_wen_0    <= rs_mdu_wen_0_i;
        rs_lsu_wen_0    <= rs_lsu_wen_0_i;
        rs_lsu_wen_1    <= rs_lsu_wen_1_i;
        rs_alu_dout_0   <= rs_alu_dout_0_i;
        rs_alu_dout_1   <= rs_alu_dout_1_i;
        rs_mdu_dout_0   <= rs_mdu_dout_0_i;
        rs_lsu_dout_0   <= rs_lsu_dout_0_i;
        rs_lsu_dout_1   <= rs_lsu_dout_1_i;
    end
end
endmodule
