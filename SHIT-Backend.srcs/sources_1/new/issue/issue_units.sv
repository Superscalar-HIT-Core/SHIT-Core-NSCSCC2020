`timescale 1ns / 1ps
`include "../defines/defines.svh"
module issue_alu(
    input clk,
    input rst,
    input flush,        // 清除请求
    input Wake_Info wake_info,      // TODO,外部输入唤醒信号,连接到队列中
    input ALU_Queue_Meta inst_Ops_0, inst_Ops_1,      // 从译码模块来的，指令的译码信息
    input enq_req_0, enq_req_1,                     // 指令入队请求
    output ALU_Inst_Ops issue_info_0, issue_info_1,         // 输出给执行单元流水线的
    output issue_en_0, issue_en_1,
    output PRFNum wake_reg_0, wake_reg_1,
    output wake_reg_0_en, wake_reg_1_en,
    output ready
    );

wire [`ALU_QUEUE_LEN-1:0] ready_vec, valid_vec;

wire [`ALU_QUEUE_IDX_LEN-1:0] sel0, sel1;
wire sel0_valid, sel1_valid, sel_valid;
ALU_Queue_Meta alu_queue_dout0, alu_queue_dout1;
ALU_Inst_Ops uops0, uops1;
assign uops0 = alu_queue_dout0.ops;
assign uops1 = alu_queue_dout1.ops;
assign wake_reg_0 = uops0.prd;
assign wake_reg_1 = uops1.prd;
assign wake_reg_0_en = uops0.wen && sel0_valid;
assign wake_reg_1_en = uops1.wen && sel1_valid;
assign issue_info_0 = uops0;
assign issue_info_1 = uops1;
assign issue_en_0 = sel0_valid;
assign issue_en_1 = sel1_valid;

iq_alu u_iq_alu(
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
    .deq_req_1      (sel1_valid      ),
    .deq0_idx       (sel0       ),
    .deq1_idx       (sel1       ),
    // To Arbiter
    .ready_vec      (ready_vec),
    .valid_vec      (valid_vec),
    // To Exu
    .dout_0         (alu_queue_dout0),
    .dout_1         (alu_queue_dout1),
    // To Dispatch
    .almost_full    (almost_full    ),
    .full           (full           )
);

assign ready = ~(almost_full | full);   // 如果满了，则不能继续接受

wire [`ALU_QUEUE_LEN-1:0] arbit_vec = ready_vec & valid_vec;

// 发射仲裁逻辑
issue_arbiter_8 u_issue_arbiter_8(
	.rdys       (arbit_vec  ),
    .sel0       (sel0       ),
    .sel1       (sel1       ),
    .sel0_valid (sel0_valid ),
    .sel1_valid (sel1_valid ),
    .sel_valid  (sel_valid  )
);



endmodule
