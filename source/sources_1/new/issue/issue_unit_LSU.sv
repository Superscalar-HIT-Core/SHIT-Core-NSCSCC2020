`timescale 1ns / 1ps
`include "../defines/defines.svh"
module iq_entry_LSU(
    input clk,
    input rst,
    input flush,
    input Wake_Info wake_Info,
    input Queue_Ctrl_Meta queue_ctrl,
    input LSU_Queue_Meta din0, din1, up0, up1,
    output LSU_Queue_Meta dout,
    output rdy,
    output isStore
    );

    LSU_Queue_Meta up_data; 
    wire rs1waked, rs2waked, new_prs1_rdy, new_prs2_rdy;
    assign up_data = ( queue_ctrl.cmp_sel == 1'b0 ) ? up0 : up1;
    LSU_Queue_Meta enq_data; 
    assign enq_data = ( queue_ctrl.enq_sel == 1'b0 ) ? din0: din1;
    LSU_Queue_Meta next_data;
    assign next_data =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_data :
                        ( queue_ctrl.cmp_en ) ? up_data : dout;
    UOPBundle ops;
    assign ops = next_data.ops;

    assign rs1waked =   (wake_Info.wen_0 && (wake_Info.wb_num0_i == ops.op0PAddr)) || 
                        (wake_Info.wen_1 && (wake_Info.wb_num1_i == ops.op0PAddr)) || 
                        (wake_Info.wen_2 && (wake_Info.wb_num2_i == ops.op0PAddr)) || 
                        (wake_Info.wen_3 && (wake_Info.wb_num3_i == ops.op0PAddr));

    assign rs2waked =   (wake_Info.wen_0 && (wake_Info.wb_num0_i == ops.op1PAddr)) || 
                        (wake_Info.wen_1 && (wake_Info.wb_num1_i == ops.op1PAddr)) || 
                        (wake_Info.wen_2 && (wake_Info.wb_num2_i == ops.op1PAddr)) || 
                        (wake_Info.wen_3 && (wake_Info.wb_num3_i == ops.op1PAddr));

    assign new_prs1_rdy = next_data.rdys.prs1_rdy || rs1waked;
    assign new_prs2_rdy = next_data.rdys.prs2_rdy || rs2waked;

    Arbitration_Info rdys;
    assign rdys.prs1_rdy = new_prs1_rdy;
    assign rdys.prs2_rdy = new_prs2_rdy;

    ALU_Queue_Meta next_data_with_wake;
    assign next_data_with_wake.ops = next_data.ops;
    assign next_data_with_wake.rdys = rdys;

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
    input deq_req_1,
    input Wake_Info wake_Info,
    input [`LSU_QUEUE_IDX_LEN-2:0] deq0_idx,
    input [`LSU_QUEUE_IDX_LEN-2:0] deq1_idx,
    input LSU_Queue_Meta din_0, din_1,
    output LSU_Queue_Meta dout_0,
    output LSU_Queue_Meta dout_1,
    output almost_full,
    output full,
    output empty,
    output almost_empty,
    output [`LSU_QUEUE_LEN-1:0] valid_vec,
    output [`LSU_QUEUE_LEN-1:0] ready_vec,
    output [`LSU_QUEUE_LEN-1:0] isStore_vec
    );
    reg [`LSU_QUEUE_IDX_LEN-1:0] tail;
    assign almost_full = (tail == `LSU_QUEUE_IDX_LEN'h`LSU_QUEUE_LEN_MINUS1);  // 差1位满，也不能写入
    assign empty = (tail == `LSU_QUEUE_IDX_LEN'h0);  // 差1位满，也不能写入
    assign full = (tail == `LSU_QUEUE_IDX_LEN'h`LSU_QUEUE_LEN);
    assign almost_empty = (tail == `LSU_QUEUE_IDX_LEN'h1);
    wire freeze = almost_full || full;

    // 入队使能信号
    wire [`LSU_QUEUE_LEN-1:0] deq, enq;
    wire [`LSU_QUEUE_LEN-1:0] cmp_sel, enq_sel;

    wire [`LSU_QUEUE_IDX_LEN-1:0] new_tail_0 = tail - deq_req_0 - deq_req_1 ; 
    wire [`LSU_QUEUE_IDX_LEN-1:0] new_tail_1 = tail - deq_req_0 - deq_req_1 + enq_req_0; 
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

    genvar i;
    generate 
        for(i=0;i<`LSU_QUEUE_LEN;i++)   begin
            iq_entry_LSU u_iq_entry_LSU(
                .clk                (clk             ),
                .rst                (rst             ),
                .flush              (flush           ),
                .queue_ctrl         (queue_ctrl[i]   ),
                .din0               (din_0           ),
                .din1               (din_1           ),
                .up0                (dout[i+1]       ),
                .up1                (dout[i+2]       ),
                .dout               (dout[i]         ),
                .rdy                (ready_vec[i]    ),
                .wake_Info          (wake_Info       ),
                .isStore            (isStore_vec[i]  )
            );
            assign queue_ctrl[i].enq_sel    =   ( new_tail_0 != i );
            assign queue_ctrl[i].cmp_en     =   ( deq_req_0 && i>= deq0_idx );
            assign queue_ctrl[i].cmp_sel    =   ( deq_req_0 && ~deq_req_1 && i >= deq0_idx ) || 
                                                ( deq_req_0 && deq_req_1 && i >= deq0_idx && i < deq1_idx -1 ) ? 0 : 1;
            assign queue_ctrl[i].enq_en     =   w_en[i];
            assign queue_ctrl[i].freeze     =   freeze;
        end
    endgenerate

    assign dout_0 = dout[deq0_idx];
    assign dout_1 = dout[deq1_idx];

    always @(posedge clk)   begin
        if(rst) begin
            tail <= `LSU_QUEUE_IDX_LEN'b0;
        end else if(freeze)begin
            tail <= tail - deq_req_0 - deq_req_1;
        end else begin
            tail <= tail + enq_req_0 + enq_req_1 - deq_req_0 - deq_req_1;
        end
    end

endmodule

module issue_unit_LSU(
    input clk,
    input rst,
    input flush,        // 清除请求
    input Wake_Info wake_Info,      // TODO,外部输入唤醒信号,连接到队列中
    input LSU_Queue_Meta inst_Ops_0, inst_Ops_1,      // 从译码模块来的，指令的译码信息
    input enq_req_0, enq_req_1,                     // 指令入队请求
    // 此处，LSU没有准备好，是不能发射的
    input lsu_busy,
    output UOPBundle issue_info_0, issue_info_1,         // 输出给执行单元流水线的
    output issue_en_0, issue_en_1,
    output ready
    );

wire [`MDU_QUEUE_LEN-1:0] ready_vec, valid_vec;

wire [`MDU_QUEUE_IDX_LEN-2:0]   sel0, sel1;
wire                            sel0_valid, sel1_valid, sel_valid;
MDU_Queue_Meta                  lsu_queue_dout0, lsu_queue_dout1;
UOPBundle                       uops0, uops1;
assign uops0                    = lsu_queue_dout0.ops;
assign uops1                    = lsu_queue_dout1.ops;
assign wake_reg_0               = uops0.dstPAddr;
assign wake_reg_1               = uops1.dstPAddr;
assign wake_reg_0_en            = uops0.dstwe && sel0_valid;
assign wake_reg_1_en            = uops1.dstwe && sel1_valid;
assign issue_info_0             = uops0;
assign issue_info_1             = uops1;
assign issue_en_0               = sel0_valid;
assign issue_en_1               = sel1_valid;

// TODO!!
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
    .dout_0         (lsu_queue_dout0),
    .dout_1         (lsu_queue_dout1),
    // To Dispatch
    .almost_full    (almost_full    ),
    .full           (full           ),
    // Wake Info
    .wake_Info      (wake_Info)
);

assign ready = ~(almost_full | full);   // 如果满了，则不能继续接受

wire [`LSU_QUEUE_LEN-1:0] arbit_vec = ready_vec & valid_vec & { 8{~lsu_busy} };

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
