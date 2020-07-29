`timescale 1ns / 1ps
// TODO: Extract the fields in decode ops, then assign them to the output 
`include "defines/defines.svh"
module dispatch(
    input clk,
    input rst,
    input pause,
    input UOPBundle inst_0_ops, inst_1_ops,
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
    );
// 分配判断
wire robEmpty = dispatch_rob.empty;
wire hasPrivInst =  (inst_0_ops.valid && inst_0_ops.isPriv) || 
                    (inst_1_ops.valid && inst_1_ops.isPriv);
wire slotsFull = inst_0_ops.valid && inst_1_ops.valid;
wire passThrough = ~hasPrivInst;                // 不需要暂停，直接传递过去
reg pause_req_cp0;
assign pause_req = pause_req_cp0;           // rob的已经在外面处理了
// 对ROB发来的ROB ID进行处理
wire [7:0] robID_0, robID_1;
assign robID_0 = { dispatch_rob.robID[6:0], 1'b0 } ;
assign robID_1 = { dispatch_rob.robID[6:0], 1'b1 } ;

// 根据当前的状态，对当前的两个ops进行reorder (TODO) //////////////////////////////
UOPBundle inst_0_ops_reordered, inst_1_ops_reordered;
// Handle CP0 Logic
typedef enum bit[2:0] { IDLE, WAIT_ROB_SLOT0, WR_ROB_SLOT0, WAIT_ROB_SLOT1, WR_ROB_SLOT1, DONE } dispatchState;
dispatchState current_state, next_state;

always @(posedge clk)   begin
    if(rst) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always_comb begin
    next_state = IDLE;
    case(current_state)
        IDLE:       begin
            if(hasPrivInst) next_state = WAIT_ROB_SLOT0;
            else            next_state = IDLE;
        end
        WAIT_ROB_SLOT0:   begin
            if(robEmpty)    next_state = WR_ROB_SLOT0;
            else            next_state = WAIT_ROB_SLOT0;
        end
        WR_ROB_SLOT0:     begin
            if(slotsFull)   next_state = WAIT_ROB_SLOT1;
            else            next_state = DONE;
        end
        WAIT_ROB_SLOT1:   begin
            if(robEmpty)    next_state = WR_ROB_SLOT1;
            else            next_state = WAIT_ROB_SLOT1;
        end
        WR_ROB_SLOT1:     begin
            next_state = DONE;
        end
        DONE:   begin
            next_state = IDLE;
        end
        default:    next_state = IDLE;
    endcase
end

always_comb begin   // 在此处完成reorder
    pause_req_cp0 = 0;
    inst_0_ops_reordered = 0;
    inst_1_ops_reordered = 0;
    case(current_state)
        IDLE:       begin
            if(~dispatch_rob.ready || hasPrivInst) begin
                pause_req_cp0 = 1;
                inst_0_ops_reordered = 0;
                inst_1_ops_reordered = 0;
            end else begin
                pause_req_cp0 = 0;
                inst_0_ops_reordered = inst_0_ops;
                inst_1_ops_reordered = inst_1_ops;
            end
        end
        WAIT_ROB_SLOT0:   begin
            pause_req_cp0 = 1;
            inst_0_ops_reordered = 0;
            inst_1_ops_reordered = 0;
        end
        WR_ROB_SLOT0:     begin
            pause_req_cp0 = 1;
            inst_0_ops_reordered = inst_0_ops.valid ? inst_0_ops : inst_1_ops;
            inst_1_ops_reordered = 0;
        end
        WAIT_ROB_SLOT1:   begin
            pause_req_cp0 = 1;
            inst_0_ops_reordered = 0;
            inst_1_ops_reordered = 0;
        end
        WR_ROB_SLOT1:     begin
            pause_req_cp0 = 1;
            inst_0_ops_reordered = inst_1_ops;
            inst_1_ops_reordered = 0;
        end
        DONE:     begin
            pause_req_cp0 = 0;
            inst_0_ops_reordered = 0;
            inst_1_ops_reordered = 0;
        end
        default:          begin
            pause_req_cp0 = 0;
            inst_0_ops_reordered = 0;
            inst_1_ops_reordered = 0;
        end
    endcase
    inst_0_ops_reordered.id = robID_0;
    inst_0_ops_reordered.busy = ( inst_0_ops_reordered.valid && inst_0_ops_reordered.uOP != NOP_U && inst_0_ops_reordered.uOP != MDBUBBLE_U );
    inst_1_ops_reordered.id = robID_1;
    inst_1_ops_reordered.busy = ( inst_1_ops_reordered.valid && inst_1_ops_reordered.uOP != NOP_U && inst_1_ops_reordered.uOP != MDBUBBLE_U );
end

wire inst0_isMul, inst1_isMul;
wire inst0_isStore, inst1_isStore;
assign inst0_isMul =    (inst_0_ops_reordered.uOP == MULTHI_U ) || 
                        (inst_0_ops_reordered.uOP == MULTLO_U ) || 
                        (inst_0_ops_reordered.uOP == MULTUHI_U) || 
                        (inst_0_ops_reordered.uOP == MULTULO_U);
assign inst0_isStore =  (inst_0_ops_reordered.uOP == SB_U ) || 
                        (inst_0_ops_reordered.uOP == SH_U ) || 
                        (inst_0_ops_reordered.uOP == SW_U ) || 
                        (inst_0_ops_reordered.uOP == SWL_U) || 
                        (inst_0_ops_reordered.uOP == SWR_U); 
assign inst1_isStore =  (inst_1_ops_reordered.uOP == SB_U ) || 
                        (inst_1_ops_reordered.uOP == SH_U ) || 
                        (inst_1_ops_reordered.uOP == SW_U ) || 
                        (inst_1_ops_reordered.uOP == SWL_U) || 
                        (inst_1_ops_reordered.uOP == SWR_U); 

// 给ROB的
assign dispatch_rob.uOP0 = inst_0_ops_reordered;
assign dispatch_rob.uOP1 = inst_1_ops_reordered;
assign dispatch_rob.valid = (inst_0_ops_reordered.valid | inst_1_ops_reordered.valid) && (~pause);

wire inst_0_is_alu = (inst_0_ops_reordered.rs_type == RS_ALU) && inst_0_ops_reordered.valid;
wire inst_1_is_alu = (inst_1_ops_reordered.rs_type == RS_ALU) && inst_1_ops_reordered.valid;
wire inst_0_is_mdu = (inst_0_ops_reordered.rs_type == RS_MDU) && inst_0_ops_reordered.valid;
wire inst_0_is_lsu = (inst_0_ops_reordered.rs_type == RS_LSU) && inst_0_ops_reordered.valid;
wire inst_1_is_lsu = (inst_1_ops_reordered.rs_type == RS_LSU) && inst_1_ops_reordered.valid;
// 每个指令的操作数是否已经准备好（这里只是设置是否读寄存器）
wire inst0_r0_ren = inst_0_ops_reordered.op0re && (|inst_0_ops_reordered.op0LAddr);
wire inst0_r1_ren = inst_0_ops_reordered.op1re && (|inst_0_ops_reordered.op1LAddr);
wire inst1_r0_ren = inst_1_ops_reordered.op0re && (|inst_1_ops_reordered.op0LAddr);
wire inst1_r1_ren = inst_1_ops_reordered.op1re && (|inst_1_ops_reordered.op1LAddr);
Arbitration_Info inst0_rdy, inst1_rdy;
assign inst0_rdy.prs1_rdy = ~(inst0_r0_ren);
assign inst0_rdy.prs2_rdy = ~(inst0_r1_ren);
assign inst1_rdy.prs1_rdy = ~(inst1_r0_ren);
assign inst1_rdy.prs2_rdy = ~(inst1_r1_ren);

// 分发出去的指令是否会写寄存器
// 用于分发阶段的setBusy(各个Scoreboard)
assign dispatch_inst0_wnum = inst_0_ops_reordered.dstPAddr;
assign dispatch_inst1_wnum = inst_1_ops_reordered.dstPAddr;
assign dispatch_inst0_wen = inst_0_ops_reordered.dstwe && inst_0_ops_reordered.valid;
assign dispatch_inst1_wen = inst_1_ops_reordered.dstwe && inst_1_ops_reordered.valid;




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
assign rs_alu_dout_0.ops =  ( (inst_0_is_alu && ~inst_1_is_alu) || (inst_0_is_alu && inst_1_is_alu) ) ? inst_0_ops_reordered : inst_1_ops_reordered;
assign rs_alu_dout_1.ops = inst_1_ops_reordered;
assign rs_alu_dout_0.rdys =  ( (inst_0_is_alu && ~inst_1_is_alu) || (inst_0_is_alu && inst_1_is_alu) ) ? inst0_rdy : inst1_rdy;
assign rs_alu_dout_1.rdys = inst1_rdy;

assign rs_mdu_wen_0 = inst_0_is_mdu;
assign rs_mdu_dout_0.ops_hi =  inst_0_ops_reordered;
assign rs_mdu_dout_0.ops_lo =  inst_1_ops_reordered;
assign rs_mdu_dout_0.rdys =  inst0_rdy;
assign rs_mdu_dout_0.isMul =  inst0_isMul;

assign rs_lsu_wen_0 = (inst_0_is_lsu || inst_1_is_lsu);
assign rs_lsu_wen_1 = inst_0_is_lsu && inst_1_is_lsu;
assign rs_lsu_dout_0.ops =  ( (inst_0_is_lsu && ~inst_1_is_lsu) || (inst_0_is_lsu && inst_1_is_lsu) ) ? inst_0_ops_reordered : inst_1_ops_reordered;
assign rs_lsu_dout_1.ops = inst_1_ops_reordered;
assign rs_lsu_dout_0.rdys =  ( (inst_0_is_lsu && ~inst_1_is_lsu) || (inst_0_is_lsu && inst_1_is_lsu) ) ? inst0_rdy : inst1_rdy;
assign rs_lsu_dout_1.rdys = inst1_rdy;
assign rs_lsu_dout_0.isStore =  ( (inst_0_is_lsu && ~inst_1_is_lsu) || (inst_0_is_lsu && inst_1_is_lsu) ) ? inst0_isStore : inst1_isStore;
assign rs_lsu_dout_1.isStore = inst1_isStore;



endmodule
