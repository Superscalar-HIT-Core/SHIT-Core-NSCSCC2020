`timescale 1ns / 1ps
`include "defines/defines.svh"
module dispatch(
    input Decode_ops inst_0_ops, inst_1_ops,
    input [`PRF_NUM-1:0] busy_table,
    output rs_alu_wen_0, rs_alu_wen_1, rs_mdu_wen_0, rs_mdu_wen_1, rs_lsu_wen_0, rs_lsu_wen_1,
    output ALU_Queue_Meta rs_alu_dout_0, rs_alu_dout_1,
    output MDU_Queue_Meta rs_mdu_dout_0, rs_mdu_dout_1,
    output LSU_Queue_Meta rs_lsu_dout_0, rs_lsu_dout_1
    );
// 分配判断
wire inst_0_is_alu = inst_0_ops.rs_num == `RS_ALU;
wire inst_1_is_alu = inst_1_ops.rs_num == `RS_ALU;
wire inst_0_is_mdu = inst_0_ops.rs_num == `RS_MDU;
wire inst_1_is_mdu = inst_1_ops.rs_num == `RS_MDU;
wire inst_0_is_lsu = inst_1_ops.rs_num == `RS_LSU;
wire inst_1_is_lsu = inst_1_ops.rs_num == `RS_LSU;

Decode_ops adin0, adin1;
Decode_ops mdin0, mdin1;
Decode_ops ldin0, ldin1;


// 有两条都是ALU指令的时候，优先写第一个
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
