`timescale 1ns / 1ps
`include "defines/defines.svh"
module iq_alu(
    input clk,
    input rst,
    input enq_req_0,
    input enq_req_1,
    input deq_req_0,
    input deq_req_1
    
    );
genvar i;
wire [`IQ_ALU_LENGTH-1:0] wen;
wire [31:0] pc_i[`IQ_ALU_LENGTH-1:0];
wire [5:0] prf_rs_1_i[`IQ_ALU_LENGTH-1:0];

endmodule
