`timescale 1ns / 1ps
`include "../defines/defines.svh"
module iq_entry_LSU(
    input clk,
    input rst,
    input flush,
    input Queue_Ctrl_Meta queue_ctrl,
    input LSU_Queue_Meta din0, din1, up0,
    input busy_rs0, busy_rs1,
    input Arbitration_Info up0_rdy,  // 从上面输出的，下一个状态的ready
    output LSU_Queue_Meta dout,
    output PRFNum rs0, rs1,
    output rdy,
    output Arbitration_Info rdy_next_state,     // 当前Slot中，下一个状态（不考虑移动的ready)
    output isStore
    );

LSU_Queue_Meta up_data; 
assign up_data = up0;
LSU_Queue_Meta enq_data; 
assign enq_data = ( queue_ctrl.enq_sel == 1'b0 ) ? din0: din1;
LSU_Queue_Meta next_data;
assign next_data =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_data :
                    ( queue_ctrl.cmp_en ) ? up_data : dout;
UOPBundle ops;
assign ops = next_data.ops;

Arbitration_Info up_rdy; 
assign up_rdy = up0_rdy;
Arbitration_Info enq_rdy; 
assign enq_rdy = ( queue_ctrl.enq_sel == 1'b0 ) ? din0.rdys : din1.rdys;
Arbitration_Info next_rdy;
assign next_rdy =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_rdy :
                    ( queue_ctrl.cmp_en ) ? up_rdy : rdy_next_state;
assign rdy_next_state.prs1_rdy = ~busy_rs0;
assign rdy_next_state.prs2_rdy = ~busy_rs1;
assign rs0 = dout.ops.op0PAddr;
assign rs1 = dout.ops.op1PAddr;


LSU_Queue_Meta next_data_with_wake;
assign next_data_with_wake.ops = next_data.ops;
assign next_data_with_wake.rdys = next_rdy;
assign next_data_with_wake.isStore = next_data.isStore;

assign rdy = dout.rdys.prs1_rdy && dout.rdys.prs2_rdy;
assign isStore = dout.isStore;
always_ff @(posedge clk)    begin
    if(rst || flush) begin
        dout <= 0;
    end else begin
        dout <= next_data_with_wake;
    end
end

endmodule

module iq_lsu(
    input clk,
    input rst,
    input flush, 
    input enq_req_0,
    input enq_req_1,
    input deq_req_0,
    input [`LSU_QUEUE_IDX_LEN-2:0] deq0_idx,
    input LSU_Queue_Meta din_0, din_1,
    output LSU_Queue_Meta dout_0,
    output almost_full,
    output full,
    output [`LSU_QUEUE_LEN-1:0] valid_vec,
    output [`LSU_QUEUE_LEN-1:0] ready_vec,
    output [`LSU_QUEUE_LEN-1:0] isStore_vec,
    output PRFNum [9:0] scoreboard_rd_num_l,
    output PRFNum [9:0] scoreboard_rd_num_r,
    input [9:0] busyvec_l,
    input [9:0] busyvec_r
    );

assign scoreboard_rd_num_l[8] = din_0.ops.op0PAddr;
assign scoreboard_rd_num_l[9] = din_1.ops.op0PAddr;
assign scoreboard_rd_num_r[8] = din_0.ops.op1PAddr;
assign scoreboard_rd_num_r[9] = din_1.ops.op1PAddr;

reg [`LSU_QUEUE_IDX_LEN-1:0] tail;
assign almost_full = (tail == `LSU_QUEUE_IDX_LEN'h`LSU_QUEUE_LEN_MINUS1);  // 差1位满，也不能写入
assign full = (tail == `LSU_QUEUE_IDX_LEN'h`LSU_QUEUE_LEN);
wire freeze = almost_full || full;

// 唤醒信息
Arbitration_Info [`LSU_QUEUE_LEN+1:0] rdy_next_state;
wire [`LSU_QUEUE_LEN-1:0] rs0_busy;
wire [`LSU_QUEUE_LEN-1:0] rs1_busy;
assign rdy_next_state[`LSU_QUEUE_LEN] = 0;
assign rdy_next_state[`LSU_QUEUE_LEN+1] = 0;

// 入队使能信号
wire [`LSU_QUEUE_LEN-1:0] deq, enq;
wire [`LSU_QUEUE_LEN-1:0] cmp_sel, enq_sel;

wire [`LSU_QUEUE_IDX_LEN-1:0] new_tail_0 = tail - deq_req_0 ; 
wire [`LSU_QUEUE_IDX_LEN-1:0] new_tail_1 = tail - deq_req_0 + enq_req_0; 
wire [`LSU_QUEUE_IDX_LEN-1:0] tail_update_val = $signed(new_tail_1) > 0 ? new_tail_1 : 0;

wire [`LSU_QUEUE_LEN-1:0] wr_vec_0 = enq_req_0 ? ( 16'b1 << new_tail_0 ) : 16'b0;
wire [`LSU_QUEUE_LEN-1:0] wr_vec_1 = enq_req_1 ? ( 16'b1 << new_tail_1 ) | wr_vec_0 : wr_vec_0;

wire [`LSU_QUEUE_LEN-1:0] cmp_en;
wire [`LSU_QUEUE_LEN-1:0] w_en = wr_vec_1;
LSU_Queue_Meta dout[`LSU_QUEUE_LEN+1:0];
Queue_Ctrl_Meta queue_ctrl[`LSU_QUEUE_LEN-1:0];
assign dout[`LSU_QUEUE_LEN] = 0;
assign dout[`LSU_QUEUE_LEN+1] = 0;
assign valid_vec =  ( tail == `LSU_QUEUE_IDX_LEN'd0 ) ? `LSU_QUEUE_LEN'b0000_0000 : 
                    ( tail == `LSU_QUEUE_IDX_LEN'd1 ) ? `LSU_QUEUE_LEN'b0000_0001 : 
                    ( tail == `LSU_QUEUE_IDX_LEN'd2 ) ? `LSU_QUEUE_LEN'b0000_0011 : 
                    ( tail == `LSU_QUEUE_IDX_LEN'd3 ) ? `LSU_QUEUE_LEN'b0000_0111 : 
                    ( tail == `LSU_QUEUE_IDX_LEN'd4 ) ? `LSU_QUEUE_LEN'b0000_1111 : 
                    ( tail == `LSU_QUEUE_IDX_LEN'd5 ) ? `LSU_QUEUE_LEN'b0001_1111 : 
                    ( tail == `LSU_QUEUE_IDX_LEN'd6 ) ? `LSU_QUEUE_LEN'b0011_1111 : 
                    ( tail == `LSU_QUEUE_IDX_LEN'd7 ) ? `LSU_QUEUE_LEN'b0111_1111 : 
                    ( tail == `LSU_QUEUE_IDX_LEN'd8 ) ? `LSU_QUEUE_LEN'b1111_1111 : `LSU_QUEUE_LEN'b0000_0000;
LSU_Queue_Meta din_0_with_rdy, din_1_with_rdy;
assign din_0_with_rdy.rdys.prs1_rdy = ~busyvec_l[8] | din_0.rdys.prs1_rdy;
assign din_0_with_rdy.rdys.prs2_rdy = ~busyvec_r[8] | din_0.rdys.prs2_rdy;
assign din_1_with_rdy.rdys.prs1_rdy = ~busyvec_l[9] | din_1.rdys.prs1_rdy;
assign din_1_with_rdy.rdys.prs2_rdy = ~busyvec_r[9] | din_1.rdys.prs2_rdy;
assign din_0_with_rdy.ops = din_0.ops;
assign din_1_with_rdy.ops = din_1.ops;
assign din_0_with_rdy.isStore = din_0.isStore;
assign din_1_with_rdy.isStore = din_1.isStore;
genvar i;
generate 
    for(i=0;i<`LSU_QUEUE_LEN;i++)   begin
        iq_entry_LSU u_iq_entry_LSU(
            .clk                (clk                        ),
            .rst                (rst                        ),
            .flush              (flush                      ),
            .queue_ctrl         (queue_ctrl[i]              ),
            .din0               (din_0_with_rdy             ),
            .din1               (din_1_with_rdy             ),
            .up0                (dout[i+1]                  ),
            .up0_rdy            (rdy_next_state[i+1]        ),
            .dout               (dout[i]                    ),
            .rdy                (ready_vec[i]               ),
            .isStore            (isStore_vec[i]             ),
            .rs0                (scoreboard_rd_num_l[i]     ),
            .rs1                (scoreboard_rd_num_r[i]     ),
            .busy_rs0           (busyvec_l[i]               ),
            .busy_rs1           (busyvec_r[i]               ),
            .rdy_next_state     (rdy_next_state[i]          )
        );
        assign queue_ctrl[i].enq_sel    =   ( new_tail_0 != i );
        assign queue_ctrl[i].cmp_en     =   ( deq_req_0 && i>= deq0_idx );
        assign queue_ctrl[i].cmp_sel    =   1;
        assign queue_ctrl[i].enq_en     =   w_en[i];
        assign queue_ctrl[i].freeze     =   freeze;
    end
endgenerate

assign dout_0 = dout[deq0_idx];

always @(posedge clk)   begin
    if(rst || flush) begin
        tail <= `LSU_QUEUE_IDX_LEN'b0;
    end else if(freeze)begin
        tail <= tail - deq_req_0;
    end else begin
        tail <= tail + enq_req_0 + enq_req_1 - deq_req_0;
    end
end

endmodule

module issue_unit_LSU(
    input clk,
    input rst,
    input flush,        // 清除请求
    input lsu_half_full,
    input LSU_Queue_Meta inst_Ops_0, inst_Ops_1,      // 从译码模块来的，指令的译码信息
    input enq_req_0, enq_req_1,                     // 指令入队请求
    // 此处，LSU没有准备好，是不能发射的
    input lsu_busy,
    output UOPBundle issue_info_0,         // 输出给执行单元流水线的
    output issue_en_0,
    output ready,
    output PRFNum [9:0] scoreboard_rd_num_l,
    output PRFNum [9:0] scoreboard_rd_num_r,
    input [9:0] busyvec_l,
    input [9:0] busyvec_r
    );

wire [`LSU_QUEUE_LEN-1:0] ready_vec, valid_vec, isStore_vec;
reg [`LSU_QUEUE_LEN-1:0] store_mask;
wire [`LSU_QUEUE_IDX_LEN-2:0]   sel0;
wire                            sel0_valid;
LSU_Queue_Meta                  lsu_queue_dout0;
UOPBundle                       uops0;
assign issue_en_0            = sel0_valid;
always_comb begin
    issue_info_0            = lsu_queue_dout0.ops;    
    issue_info_0.valid      = sel0_valid;
end

iq_lsu u_iq_lsu(
    // Global Signals
	.clk            (clk            ),
    .rst            (rst            ),
    .flush          (flush          ),
    // From Dispatch
    .enq_req_0      (enq_req_0      ),
    .enq_req_1      (enq_req_1      ),
    .din_0          (inst_Ops_0 ),
    .din_1          (inst_Ops_1 ),
    // From Arbiter
    .deq_req_0      (sel0_valid      ),
    .deq0_idx       (sel0       ),
    // To Arbiter
    .ready_vec      (ready_vec),
    .valid_vec      (valid_vec),
    .isStore_vec    (isStore_vec),
    // To Exu
    .dout_0         (lsu_queue_dout0),
    // To Dispatch
    .almost_full    (almost_full    ),
    .full           (full           ),
    // Wake Info
    .scoreboard_rd_num_l(scoreboard_rd_num_l),
    .scoreboard_rd_num_r(scoreboard_rd_num_r),
    .busyvec_l(busyvec_l),
    .busyvec_r(busyvec_r)
);

assign ready = ~(almost_full | full) && ~lsu_half_full;  // 如果满了，则不能继续接受

store_bitmask_gen u_mask(
    .store_vec(isStore_vec),
    .store_mask(store_mask)
);

wire [`LSU_QUEUE_LEN-1:0] arbit_vec =   ready_vec & 
                                        valid_vec & 
                                        { 8{~lsu_busy} } & 
                                        store_mask;

// 发射仲裁逻辑
issue_arbiter_8_sel1 u_issue_arbiter_8(
	.rdys       (arbit_vec  ),
    .sel0       (sel0       ),
    .sel0_valid (sel0_valid )
);

endmodule
