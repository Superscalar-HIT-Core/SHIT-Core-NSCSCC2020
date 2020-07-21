`timescale 1ns / 1ps
`include "../defines/defines.svh"
module iq_entry_MDU(
    input clk,
    input rst,
    input flush,
    input Queue_Ctrl_Meta queue_ctrl,
    input MDU_Queue_Meta din0, up0,
    input busy_rs0, busy_rs1,
    input Arbitration_Info up0_rdy,  // 从上面输出的，下一个状态的ready
    output MDU_Queue_Meta dout,
    output PRFNum rs0, rs1,
    output rdy,
    output Arbitration_Info rdy_next_state,     // 当前Slot中，下一个状态（不考虑移动的ready)
    output isMul
    );

MDU_Queue_Meta up_data; 
assign up_data = up0;
MDU_Queue_Meta enq_data; 
assign enq_data = din0;
MDU_Queue_Meta next_data;
assign next_data =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_data :
                    ( queue_ctrl.cmp_en ) ? up_data : dout;
UOPBundle ops;
assign ops = next_data.ops_hi;

Arbitration_Info up_rdy; 
assign up_rdy = up0_rdy;
Arbitration_Info enq_rdy; 
assign enq_rdy = din0.rdys;
Arbitration_Info next_rdy;
assign next_rdy =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_rdy :
                    ( queue_ctrl.cmp_en ) ? up_rdy : rdy_next_state;
assign rdy_next_state.prs1_rdy = ~busy_rs0;
assign rdy_next_state.prs2_rdy = ~busy_rs1;
assign rs0 = dout.ops_hi.op0PAddr;
assign rs1 = dout.ops_hi.op1PAddr;

MDU_Queue_Meta next_data_with_wake;
assign next_data_with_wake.ops_hi = next_data.ops_hi;
assign next_data_with_wake.ops_lo = next_data.ops_lo;
assign next_data_with_wake.rdys = next_rdy;
assign next_data_with_wake.isMul = next_data.isMul;

assign rdy = dout.rdys.prs1_rdy && dout.rdys.prs2_rdy;
assign isMul = dout.isMul;
always_ff @(posedge clk)    begin
    if(rst || flush) begin
        dout <= 0;
    end else begin
        dout <= next_data_with_wake;
    end
end

endmodule

module iq_mdu(
    input clk,
    input rst,
    input flush, 
    input enq_req_0,
    input deq_req_0,
    input [`MDU_QUEUE_IDX_LEN-2:0] deq0_idx,
    input MDU_Queue_Meta din_0, 
    output MDU_Queue_Meta dout_0,
    output full,
    output [`MDU_QUEUE_LEN-1:0] ready_vec,
    output [`MDU_QUEUE_LEN-1:0] valid_vec,
    output [`MDU_QUEUE_LEN-1:0] isMul_vec,
    output PRFNum [9:0] scoreboard_rd_num_l,
    output PRFNum [9:0] scoreboard_rd_num_r,
    input [9:0] busyvec_l,
    input [9:0] busyvec_r
    );

assign scoreboard_rd_num_l[8] = din_0.ops_hi.op0PAddr;
assign scoreboard_rd_num_r[8] = din_0.ops_hi.op1PAddr;
assign scoreboard_rd_num_l[9] = 0;
assign scoreboard_rd_num_r[9] = 0;

reg [`MDU_QUEUE_IDX_LEN-1:0] tail;
assign full = (tail == `MDU_QUEUE_IDX_LEN'h`MDU_QUEUE_LEN);
wire freeze = full;

// 唤醒信息
Arbitration_Info [`MDU_QUEUE_LEN+1:0] rdy_next_state;
wire [`MDU_QUEUE_LEN-1:0] rs0_busy;
wire [`MDU_QUEUE_LEN-1:0] rs1_busy;
assign rdy_next_state[`MDU_QUEUE_LEN] = 0;
assign rdy_next_state[`MDU_QUEUE_LEN+1] = 0;

// 入队使能信号
wire [`MDU_QUEUE_LEN-1:0] deq, enq;

wire [`MDU_QUEUE_IDX_LEN-1:0] new_tail_0 = tail - deq_req_0; 
wire [`MDU_QUEUE_IDX_LEN-1:0] tail_update_val = $signed(new_tail_0) > 0 ? new_tail_0 : 0;

wire [`MDU_QUEUE_LEN-1:0] wr_vec_0 = enq_req_0 ? ( 16'b1 << new_tail_0 ) : 16'b0;

wire [`MDU_QUEUE_LEN-1:0] cmp_en;
wire [`MDU_QUEUE_LEN-1:0] w_en = wr_vec_0;
MDU_Queue_Meta dout[`MDU_QUEUE_LEN:0];
Queue_Ctrl_Meta queue_ctrl[`MDU_QUEUE_LEN-1:0];
assign dout[`MDU_QUEUE_LEN] = 0;
assign valid_vec =  ( tail == `MDU_QUEUE_IDX_LEN'd0 ) ? `MDU_QUEUE_LEN'b0000_0000 : 
                    ( tail == `MDU_QUEUE_IDX_LEN'd1 ) ? `MDU_QUEUE_LEN'b0000_0001 : 
                    ( tail == `MDU_QUEUE_IDX_LEN'd2 ) ? `MDU_QUEUE_LEN'b0000_0011 : 
                    ( tail == `MDU_QUEUE_IDX_LEN'd3 ) ? `MDU_QUEUE_LEN'b0000_0111 : 
                    ( tail == `MDU_QUEUE_IDX_LEN'd4 ) ? `MDU_QUEUE_LEN'b0000_1111 : 
                    ( tail == `MDU_QUEUE_IDX_LEN'd5 ) ? `MDU_QUEUE_LEN'b0001_1111 : 
                    ( tail == `MDU_QUEUE_IDX_LEN'd6 ) ? `MDU_QUEUE_LEN'b0011_1111 : 
                    ( tail == `MDU_QUEUE_IDX_LEN'd7 ) ? `MDU_QUEUE_LEN'b0111_1111 : 
                    ( tail == `MDU_QUEUE_IDX_LEN'd8 ) ? `MDU_QUEUE_LEN'b1111_1111 : `MDU_QUEUE_LEN'b0000_0000;
MDU_Queue_Meta din_0_with_rdy;
assign din_0_with_rdy.rdys.prs1_rdy = ~busyvec_l[8] | din_0.rdys.prs1_rdy;
assign din_0_with_rdy.rdys.prs2_rdy = ~busyvec_r[8] | din_0.rdys.prs2_rdy;
assign din_0_with_rdy.ops_hi = din_0.ops_hi;
assign din_0_with_rdy.ops_lo = din_0.ops_lo;
assign din_0_with_rdy.isMul = din_0.isMul;
genvar i;
generate 
    for(i=0;i<`MDU_QUEUE_LEN;i++)   begin
        iq_entry_MDU u_iq_entry_MDU(
            .clk                (clk             ),
            .rst                (rst             ),
            .flush              (flush           ),
            .queue_ctrl         (queue_ctrl[i]   ),
            .din0               (din_0_with_rdy  ),
            .up0                (dout[i+1]       ),
            .up0_rdy            (rdy_next_state[i+1]),
            .dout               (dout[i]         ),
            .rdy                (ready_vec[i]    ),
            .isMul              (isMul_vec[i]    ),
            .rs0                (scoreboard_rd_num_l[i]     ),
            .rs1                (scoreboard_rd_num_r[i]     ),
            .busy_rs0           (busyvec_l[i]               ),
            .busy_rs1           (busyvec_r[i]               ),
            .rdy_next_state     (rdy_next_state[i]          )
        );
        assign queue_ctrl[i].enq_sel    =   ( new_tail_0 != i );
        assign queue_ctrl[i].cmp_en     =   ( deq_req_0 && i>= deq0_idx );
        assign queue_ctrl[i].cmp_sel    =   0;
        assign queue_ctrl[i].enq_en     =   w_en[i];
        assign queue_ctrl[i].freeze     =   freeze;
    end
endgenerate

assign dout_0 = dout[deq0_idx];

always @(posedge clk)   begin
    if(rst) begin
        tail <= `MDU_QUEUE_IDX_LEN'b0;
    end else if(freeze)begin
        tail <= tail - deq_req_0;
    end else begin
        tail <= tail + enq_req_0 - deq_req_0;
    end
end

endmodule


module issue_unit_MDU(
    input clk,
    input rst,
    input flush,        // 清除请求
    input MDU_Queue_Meta inst_Ops_0,      // 从译码模块来的，指令的译码信息
    input enq_req_0,                     // 指令入队请求
    // 乘除法部件正忙，不能发射
    input mul_busy,
    input div_busy,
    output UOPBundle issue_info_hi,         // 输出给执行单元流水线的
    output UOPBundle issue_info_lo,         // 输出给执行单元流水线的
    output issue_en_0,
    output ready,
    output PRFNum [9:0] scoreboard_rd_num_l,
    output PRFNum [9:0] scoreboard_rd_num_r,
    input [9:0] busyvec_l,
    input [9:0] busyvec_r
    );

wire [`MDU_QUEUE_LEN-1:0] ready_vec, valid_vec, isMul_vec;

wire [`MDU_QUEUE_IDX_LEN-2:0]   sel0;
wire                            sel0_valid;
MDU_Queue_Meta                  mdu_queue_dout0;
assign issue_en_0            = sel0_valid;
always_comb begin
    issue_info_hi            = mdu_queue_dout0.ops_hi;
    issue_info_lo            = mdu_queue_dout0.ops_lo;
    issue_info_hi.valid      = sel0_valid;
    issue_info_lo.valid      = sel0_valid;
end

iq_mdu u_iq_mdu(
    // Global Signals
    .clk            (clk            ),
    .rst            (rst            ),
    .flush          (flush          ),
    // From Dispatch
    .enq_req_0      (enq_req_0      ),
    .din_0          (inst_Ops_0 ),
    // From Arbiter
    .deq_req_0      (sel0_valid      ),
    .deq0_idx       (sel0       ),
    // To Arbiter
    .ready_vec      (ready_vec),
    .valid_vec      (valid_vec),
    .isMul_vec      (isMul_vec),
    // To Exu
    .dout_0         (mdu_queue_dout0),
    // To Dispatch
    .full           (full           ),
    // Wake Info
    .scoreboard_rd_num_l(scoreboard_rd_num_l),
    .scoreboard_rd_num_r(scoreboard_rd_num_r),
    .busyvec_l(busyvec_l),
    .busyvec_r(busyvec_r)
);

assign ready = ~full;   // 如果满了，则不能继续接受
wire [`MDU_QUEUE_LEN-1:0] mul_valid_mask = mul_busy ? ~isMul_vec : isMul_vec;
wire [`MDU_QUEUE_LEN-1:0] div_valid_mask = div_busy ? isMul_vec : ~isMul_vec;

wire [`MDU_QUEUE_LEN-1:0] arbit_vec = ready_vec & valid_vec & (mul_valid_mask | div_valid_mask);

// 发射仲裁逻辑
issue_arbiter_8_sel1 arbit(
    .rdys       (arbit_vec  ),
    .sel0       (sel0       ),
    .sel0_valid (sel0_valid )
);

endmodule
