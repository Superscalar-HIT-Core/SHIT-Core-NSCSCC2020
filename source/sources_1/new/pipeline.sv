`timescale 1ns / 1ps
`include "defines/defines.svh"
module pipeline(
    input clk,
    input rst
    );

UOPBundle inst_0_ops, inst_1_ops;
UOPBundle rs_alu_dout_0, rs_alu_dout_1,
UOPBundle rs_mdu_dout_0, rs_mdu_dout_1,
UOPBundle rs_lsu_dout_0, rs_lsu_dout_1
reg [`PRF_NUM-1:0] busy_table;
wire rs_alu_wen_0, rs_alu_wen_1;
wire rs_mdu_wen_0, rs_mdu_wen_1;
wire rs_lsu_wen_0, rs_lsu_wen_1;
dispatch u_dispatch(.*);

endmodule
