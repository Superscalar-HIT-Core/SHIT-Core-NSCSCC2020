`timescale 1ns / 1ps
// TODO: Extract the fields in decode ops, then assign them to the output 
`include "defines/defines.svh"
module dispatch(
    input UOPBundle inst_0_ops, inst_1_ops,
    input pause,
    // input busy_dispatch_inst0_r0,
    // input busy_dispatch_inst0_r1,
    // input busy_dispatch_inst1_r0,
    // input busy_dispatch_inst1_r1,
    output rs_alu_wen_0, rs_alu_wen_1, 
    output rs_mdu_wen_0, 
    output rs_lsu_wen_0, rs_lsu_wen_1,
    output ALU_Queue_Meta rs_alu_dout_0, rs_alu_dout_1,
    output MDU_Queue_Meta rs_mdu_dout_0,
    output LSU_Queue_Meta rs_lsu_dout_0, rs_lsu_dout_1,
    // Dispatch阶段设置busy位，写Scoreboard
    output PRFNum dispatch_inst0_wnum,
    output PRFNum dispatch_inst1_wnum,
    output dispatch_inst0_wen,
    output dispatch_inst1_wen,
    Dispatch_ROB.dispatch dispatch_rob,
    output pause_req
    // output PRFNum dispatch_inst0_r0,
    // output PRFNum dispatch_inst0_r1,
    // output PRFNum dispatch_inst1_r0,
    // output PRFNum dispatch_inst1_r1
    );
// 分配判断
wire [7:0] robID_0, robID_1;
assign robID_0 = { dispatch_rob.robID[6:0], 1'b0 } ;
assign robID_1 = { dispatch_rob.robID[6:0], 1'b1 } ;
UOPBundle inst_0_ops_dispatch, inst_1_ops_dispatch;
always_comb begin
    inst_0_ops_dispatch = inst_0_ops;
    inst_0_ops_dispatch.id = robID_0;
    inst_0_ops_dispatch.busy = ( inst_0_ops.valid && inst_0_ops.uOP != NOP_U && inst_0_ops.uOP != MDBUBBLE_U );
    inst_1_ops_dispatch = inst_1_ops;
    inst_1_ops_dispatch.id = robID_1;
    inst_1_ops_dispatch.busy = ( inst_1_ops.valid && inst_1_ops.uOP != NOP_U && inst_1_ops.uOP != MDBUBBLE_U );
end
assign dispatch_rob.uOP0 = inst_0_ops_dispatch;
assign dispatch_rob.uOP1 = inst_1_ops_dispatch;
assign dispatch_rob.valid = (inst_0_ops.valid | inst_1_ops.valid) && (~pause);
assign pause_req = ~dispatch_rob.ready;

wire inst_0_is_alu = (inst_0_ops_dispatch.rs_type == RS_ALU) && inst_0_ops_dispatch.valid;
wire inst_1_is_alu = (inst_1_ops_dispatch.rs_type == RS_ALU) && inst_1_ops_dispatch.valid;
wire inst_0_is_mdu = (inst_0_ops_dispatch.rs_type == RS_MDU) && inst_0_ops_dispatch.valid;
// wire inst_1_is_mdu = (inst_1_ops_dispatch.rs_type == RS_MDU) && inst_1_ops_dispatch.valid;
wire inst_0_is_lsu = (inst_0_ops_dispatch.rs_type == RS_LSU) && inst_0_ops_dispatch.valid;
wire inst_1_is_lsu = (inst_1_ops_dispatch.rs_type == RS_LSU) && inst_1_ops_dispatch.valid;

// assign dispatch_inst0_r0 = inst_0_ops_dispatch.op0PAddr;
// assign dispatch_inst0_r1 = inst_0_ops_dispatch.op1PAddr;
// assign dispatch_inst1_r0 = inst_1_ops_dispatch.op0PAddr;
// assign dispatch_inst1_r1 = inst_1_ops_dispatch.op1PAddr;
assign dispatch_inst0_wnum = inst_0_ops_dispatch.dstPAddr;
assign dispatch_inst1_wnum = inst_1_ops_dispatch.dstPAddr;
assign dispatch_inst0_wen = inst_0_ops_dispatch.dstwe;
assign dispatch_inst1_wen = inst_1_ops_dispatch.dstwe;

wire inst0_r0_ren = inst_0_ops_dispatch.op0re && (|inst_0_ops_dispatch.op0LAddr);
wire inst0_r1_ren = inst_0_ops_dispatch.op1re && (|inst_0_ops_dispatch.op1LAddr);
wire inst1_r0_ren = inst_1_ops_dispatch.op0re && (|inst_1_ops_dispatch.op0LAddr);
wire inst1_r1_ren = inst_1_ops_dispatch.op1re && (|inst_1_ops_dispatch.op1LAddr);

wire inst0_r0_rdy = ~(inst0_r0_ren);
wire inst0_r1_rdy = ~(inst0_r1_ren);
wire inst1_r0_rdy = ~(inst1_r0_ren);
wire inst1_r1_rdy = ~(inst1_r1_ren);



assign dispatch_rob.uOP0 = inst_0_ops_dispatch;
assign dispatch_rob.uOP1 = inst_1_ops_dispatch;
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

Arbitration_Info inst0_rdy, inst1_rdy;
assign inst0_rdy.prs1_rdy = inst0_r0_rdy;
assign inst0_rdy.prs2_rdy = inst0_r1_rdy;
assign inst1_rdy.prs1_rdy = inst1_r0_rdy;
assign inst1_rdy.prs2_rdy = inst1_r1_rdy;
wire inst0_isMul, inst1_isMul;
wire inst0_isStore, inst1_isStore;
assign inst0_isMul =    (inst_0_ops_dispatch.uOP == MULTHI_U ) || 
                        (inst_0_ops_dispatch.uOP == MULTLO_U ) || 
                        (inst_0_ops_dispatch.uOP == MULTUHI_U) || 
                        (inst_0_ops_dispatch.uOP == MULTULO_U);

// assign inst1_isMul =    (inst_1_ops_dispatch.uOP == MULTHI_U ) || 
//                         (inst_1_ops_dispatch.uOP == MULTLO_U ) || 
//                         (inst_1_ops_dispatch.uOP == MULTUHI_U) || 
//                         (inst_1_ops_dispatch.uOP == MULTULO_U);

assign inst0_isStore =  (inst_0_ops_dispatch.uOP == SB_U ) || 
                        (inst_0_ops_dispatch.uOP == SH_U ) || 
                        (inst_0_ops_dispatch.uOP == SW_U ) || 
                        (inst_0_ops_dispatch.uOP == SWL_U) || 
                        (inst_0_ops_dispatch.uOP == SWR_U); 
assign inst1_isStore =  (inst_1_ops_dispatch.uOP == SB_U ) || 
                        (inst_1_ops_dispatch.uOP == SH_U ) || 
                        (inst_1_ops_dispatch.uOP == SW_U ) || 
                        (inst_1_ops_dispatch.uOP == SWL_U) || 
                        (inst_1_ops_dispatch.uOP == SWR_U); 

assign rs_alu_wen_0 = (inst_0_is_alu || inst_1_is_alu);
assign rs_alu_wen_1 = inst_0_is_alu && inst_1_is_alu;
assign rs_alu_dout_0.ops =  ( (inst_0_is_alu && ~inst_1_is_alu) || (inst_0_is_alu && inst_1_is_alu) ) ? inst_0_ops_dispatch : inst_1_ops_dispatch;
assign rs_alu_dout_1.ops = inst_1_ops_dispatch;
assign rs_alu_dout_0.rdys =  ( (inst_0_is_alu && ~inst_1_is_alu) || (inst_0_is_alu && inst_1_is_alu) ) ? inst0_rdy : inst1_rdy;
assign rs_alu_dout_1.rdys = inst1_rdy;

// assign rs_mdu_wen_0 = (inst_0_is_mdu || inst_1_is_mdu);
// assign rs_mdu_wen_1 = inst_0_is_mdu && inst_1_is_mdu;
// assign rs_mdu_dout_0.ops =  ( (inst_0_is_mdu && ~inst_1_is_mdu) || (inst_0_is_mdu && inst_1_is_mdu) ) ? inst_0_ops_dispatch : inst_1_ops_dispatch;
// assign rs_mdu_dout_1.ops = inst_1_ops_dispatch;
// assign rs_mdu_dout_0.rdys =  ( (inst_0_is_mdu && ~inst_1_is_mdu) || (inst_0_is_mdu && inst_1_is_mdu) ) ? inst0_rdy : inst1_rdy;
// assign rs_mdu_dout_1.rdys = inst1_rdy;
// assign rs_mdu_dout_0.isMul =  ( (inst_0_is_mdu && ~inst_1_is_mdu) || (inst_0_is_mdu && inst_1_is_mdu) ) ? inst0_isMul : inst1_isMul;
// assign rs_mdu_dout_1.isMul = inst1_isMul;

assign rs_mdu_wen_0 = inst_0_is_mdu;
assign rs_mdu_dout_0.ops_hi =  inst_0_ops_dispatch;
assign rs_mdu_dout_0.ops_lo =  inst_1_ops_dispatch;
assign rs_mdu_dout_0.rdys =  inst0_rdy;
assign rs_mdu_dout_0.isMul =  inst0_isMul;

assign rs_lsu_wen_0 = (inst_0_is_lsu || inst_1_is_lsu);
assign rs_lsu_wen_1 = inst_0_is_lsu && inst_1_is_lsu;
assign rs_lsu_dout_0.ops =  ( (inst_0_is_lsu && ~inst_1_is_lsu) || (inst_0_is_lsu && inst_1_is_lsu) ) ? inst_0_ops_dispatch : inst_1_ops_dispatch;
assign rs_lsu_dout_1.ops = inst_1_ops_dispatch;
assign rs_lsu_dout_0.rdys =  ( (inst_0_is_lsu && ~inst_1_is_lsu) || (inst_0_is_lsu && inst_1_is_lsu) ) ? inst0_rdy : inst1_rdy;
assign rs_lsu_dout_1.rdys = inst1_rdy;
assign rs_lsu_dout_0.isStore =  ( (inst_0_is_lsu && ~inst_1_is_lsu) || (inst_0_is_lsu && inst_1_is_lsu) ) ? inst0_isStore : inst1_isStore;
assign rs_lsu_dout_1.isStore = inst1_isStore;

endmodule
