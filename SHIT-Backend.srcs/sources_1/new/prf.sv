`timescale 1ns / 1ps
`include "defines.svh"
//////////////////////////////////////////////////////////////////////////////////
// 物理寄存器堆文件
// 
//////////////////////////////////////////////////////////////////////////////////

module prf(
    // ALU1
    input [`PRF_NUM_WIDTH-1:0] rnum_ALU0_0,
    input [`PRF_NUM_WIDTH-1:0] rnum_ALU0_1,
    input [`PRF_NUM_WIDTH-1:0] wnum_ALU0,
    input wen_ALU0,
    input [31:0] wdata_ALU0,
    output [31:0] rdata_ALU0_0,
    output [31:0] rdata_ALU0_1,
    // ALU2 
    input [`PRF_NUM_WIDTH-1:0] rnum_ALU1_0,
    input [`PRF_NUM_WIDTH-1:0] rnum_ALU1_1,
    input [`PRF_NUM_WIDTH-1:0] wnum_ALU1,
    input wen_ALU1,
    input [31:0] wdata_ALU1,
    output [31:0] rdata_ALU1_0,
    output [31:0] rdata_ALU1_1,
    // 1 * BRU
    input [`PRF_NUM_WIDTH-1:0] rnum_BRU_0,
    input [`PRF_NUM_WIDTH-1:0] rnum_BRU_1,
    input [`PRF_NUM_WIDTH-1:0] wnum_BRU,
    input wen_BRU,
    input [31:0] wdata_BRU,
    output [31:0] rdata_BRU_0,
    output [31:0] rdata_BRU_1,
    // 1 * LSU
    input [`PRF_NUM_WIDTH-1:0] rnum_LSU_0,
    input [`PRF_NUM_WIDTH-1:0] rnum_LSU_1,
    input [`PRF_NUM_WIDTH-1:0] wnum_LSU,
    input wen_LSU,
    input [31:0] wdata_LSU,
    output [31:0] rdata_LSU_0,
    output [31:0] rdata_LSU_1,
    // 1 * MDU (读2个寄存器，写寄存器固定是hi,lo)
    input [`PRF_NUM_WIDTH-1:0] rnum_MDU_0,
    input [`PRF_NUM_WIDTH-1:0] rnum_MDU_1,
    // 由于MDU一次会写2个寄存器,hilo
    input wen_MDU,
    input [31:0] wdata_MDU_hi,
    input [31:0] wdata_MDU_lo,
    output [31:0] rdata_MDU_0,
    output [31:0] rdata_MDU_1,

    // hi, lo
    output [31:0] hi,
    output [31:0] lo
    );
endmodule
