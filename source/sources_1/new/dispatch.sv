`timescale 1ns / 1ps
// TODO: Extract the fields in decode ops, then assign them to the output 
`include "defines/defines.svh"
module dispatch(
    input UOPBundle inst_0_ops, inst_1_ops,
    input [`PRF_NUM-1:0] busy_table,
    input busy_dispatch_inst0_r0,
    input busy_dispatch_inst0_r1,
    input busy_dispatch_inst1_r0,
    input busy_dispatch_inst1_r1,
    output rs_alu_wen_0, rs_alu_wen_1, 
    output rs_mdu_wen_0, rs_mdu_wen_1, 
    output rs_lsu_wen_0, rs_lsu_wen_1,
    output UOPBundle rs_alu_dout_0, rs_alu_dout_1,
    output UOPBundle rs_mdu_dout_0, rs_mdu_dout_1,
    output UOPBundle rs_lsu_dout_0, rs_lsu_dout_1,
    output PRFNum dispatch_inst0_r0,
    output PRFNum dispatch_inst0_r1,
    output PRFNum dispatch_inst1_r0,
    output PRFNum dispatch_inst1_r1
    );
// 分配判断
wire inst_0_is_alu = inst_0_ops.rs_type == RS_ALU;
wire inst_1_is_alu = inst_1_ops.rs_type == RS_ALU;
wire inst_0_is_mdu = inst_0_ops.rs_type == RS_MDU;
wire inst_1_is_mdu = inst_1_ops.rs_type == RS_MDU;
wire inst_0_is_lsu = inst_1_ops.rs_type == RS_LSU;
wire inst_1_is_lsu = inst_1_ops.rs_type == RS_LSU;

UOPBundle adin0, adin1;
UOPBundle mdin0, mdin1;
UOPBundle ldin0, ldin1;

assign dispatch_inst0_r0 = inst_0_ops.op0PAddr;
assign dispatch_inst0_r1 = inst_0_ops.op1PAddr;
assign dispatch_inst1_r0 = inst_1_ops.op0PAddr;
assign dispatch_inst1_r1 = inst_1_ops.op1PAddr;

wire inst0_r0_ren = inst_0_ops.op0re || (|inst_0_ops.op0LAddr);
wire inst0_r1_ren = inst_0_ops.op1re || (|inst_0_ops.op1LAddr);
wire inst1_r0_ren = inst_1_ops.op0re || (|inst_1_ops.op0LAddr);
wire inst1_r1_ren = inst_1_ops.op1re || (|inst_1_ops.op1LAddr);

wire inst0_r0_rdy = ~(inst0_r0_ren) || ~(busy_dispatch_inst0_r0);
wire inst0_r1_rdy = ~(inst0_r1_ren) || ~(busy_dispatch_inst0_r1);
wire inst1_r0_rdy = ~(inst1_r0_ren) || ~(busy_dispatch_inst1_r0);
wire inst1_r1_rdy = ~(inst1_r1_ren) || ~(busy_dispatch_inst1_r1);

// Truth Table
//                      RS_ALU_WEN_0     RS_ALU_WEN_1
//  isALU_0, isALU_1        
//       00                   0               0
//      10,01                 1               0
//       11                   1               1

//  ________________| RS_ALU_dout_0     RS_ALU_dout_1
//  isALU_0, isALU_1| -------------------------------       
//       00         |         x               x
//       10         |         din0            x
//       01         |         din1            x
//       11         |         din0           din1

assign rs_alu_wen_0 = (inst_0_is_alu || inst_1_is_alu);
assign rs_alu_wen_1 = inst_0_is_alu && inst_1_is_alu;
assign adin0 =  ( (inst_0_is_alu && ~inst_1_is_alu ) || ( inst_0_is_alu && inst_1_is_alu ) ) ? inst_0_ops : inst_1_ops;
assign adin1 = inst_1_ops;

assign rs_mdu_wen_0 = (inst_0_is_mdu || inst_1_is_mdu);
assign rs_mdu_wen_1 = inst_0_is_mdu && inst_1_is_mdu;
assign mdin0 =  ( (inst_0_is_mdu && ~inst_1_is_mdu ) || ( inst_0_is_mdu && inst_1_is_mdu ) ) ? inst_0_ops : inst_1_ops;
assign mdin1 = inst_1_ops;

assign rs_lsu_wen_0 = (inst_0_is_lsu || inst_1_is_lsu);
assign rs_lsu_wen_1 = inst_0_is_lsu && inst_1_is_lsu;
assign ldin0 =  ( (inst_0_is_lsu && ~inst_1_is_lsu ) || ( inst_0_is_lsu && inst_1_is_lsu ) ) ? inst_0_ops : inst_1_ops;
assign ldin1 = inst_1_ops;

endmodule
