`timescale 1ns / 1ps
`include "../defines/defines.svh"
module iq_entry_ALU(
    input clk,
    input rst,
    input flush,
    input Queue_Ctrl_Meta queue_ctrl,
    input ALU_Queue_Meta din0, din1, up0, up1,
    input busy_rs0, busy_rs1,
    input Arbitration_Info up0_rdy, up1_rdy, // 从上面输出的，下一个状态的ready
    output ALU_Queue_Meta dout,
    output PRFNum rs0, rs1,
    output Arbitration_Info rdy_next_state,     // 当前Slot中，下一个状态（不考虑移动的ready)
    output rdy
    );

    ALU_Queue_Meta up_data; 
    wire rs1waked, rs2waked, new_prs1_rdy, new_prs2_rdy;
    assign up_data = ( queue_ctrl.cmp_sel == 1'b0 ) ? up0 : up1;
    ALU_Queue_Meta enq_data; 
    assign enq_data = ( queue_ctrl.enq_sel == 1'b0 ) ? din0: din1;
    ALU_Queue_Meta next_data;
    assign next_data =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_data :
                        ( queue_ctrl.cmp_en ) ? up_data : dout;
    UOPBundle ops;
    assign ops = next_data.ops;

    Arbitration_Info up_rdy; 
    assign up_rdy = ( queue_ctrl.cmp_sel == 1'b0 ) ? up0_rdy : up1_rdy;
    Arbitration_Info enq_rdy; 
    assign enq_rdy = ( queue_ctrl.enq_sel == 1'b0 ) ? din0.rdys : din1.rdys;
    Arbitration_Info next_rdy;
    assign next_rdy =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_rdy :
                        ( queue_ctrl.cmp_en ) ? up_rdy : rdy_next_state;
    assign rdy_next_state.prs1_rdy = ~busy_rs0;
    assign rdy_next_state.prs2_rdy = ~busy_rs1;
    assign rs0 = dout.ops.op0PAddr;
    assign rs1 = dout.ops.op1PAddr;
    ALU_Queue_Meta next_data_with_wake;
    assign next_data_with_wake.ops = next_data.ops;
    assign next_data_with_wake.rdys = next_rdy;

    assign rdy = dout.rdys.prs1_rdy && dout.rdys.prs2_rdy;

    always_ff @(posedge clk)    begin
        if(rst || flush) begin
            dout <= 0;
        end else begin
            dout <= next_data_with_wake;
        end
    end

endmodule

module iq_alu(
    input clk,
    input rst,
    input flush, 
    input enq_req_0,
    input enq_req_1,
    input deq_req_0,
    input deq_req_1,
    input [`ALU_QUEUE_IDX_LEN-2:0] deq0_idx,
    input [`ALU_QUEUE_IDX_LEN-2:0] deq1_idx,
    input ALU_Queue_Meta din_0, din_1,
    output ALU_Queue_Meta dout_0,
    output ALU_Queue_Meta dout_1,
    output almost_full,
    output full,
    output empty,
    output almost_empty,
    output [`ALU_QUEUE_LEN-1:0] ready_vec,
    output [`ALU_QUEUE_LEN-1:0] valid_vec,
    output PRFNum [9:0] scoreboard_rd_num_l,
    output PRFNum [9:0] scoreboard_rd_num_r,
    input [9:0] busyvec_l,
    input [9:0] busyvec_r
    );
    reg [`ALU_QUEUE_IDX_LEN-1:0] tail;
    assign almost_full = (tail == `ALU_QUEUE_IDX_LEN'h`ALU_QUEUE_LEN_MINUS1);  // 差1位满，也不能写入
    assign empty = (tail == `ALU_QUEUE_IDX_LEN'h0);  // 差1位满，也不能写入
    assign full = (tail == `ALU_QUEUE_IDX_LEN'h`ALU_QUEUE_LEN);
    assign almost_empty = (tail == `ALU_QUEUE_IDX_LEN'h1);
    wire freeze = almost_full || full;

    // 唤醒信息
    PRFNum [`ALU_QUEUE_LEN-1:0] rs0_nums;
    PRFNum [`ALU_QUEUE_LEN-1:0] rs1_nums;
    Arbitration_Info [`ALU_QUEUE_LEN+1:0] rdy_next_state;
    wire [`ALU_QUEUE_LEN-1:0] rs0_busy;
    wire [`ALU_QUEUE_LEN-1:0] rs1_busy;

    // 入队使能信号
    wire [`ALU_QUEUE_LEN-1:0] deq, enq;
    wire [`ALU_QUEUE_LEN-1:0] cmp_sel, enq_sel;

    wire [`ALU_QUEUE_IDX_LEN-1:0] new_tail_0 = tail - deq_req_0 - deq_req_1 ; 
    wire [`ALU_QUEUE_IDX_LEN-1:0] new_tail_1 = tail - deq_req_0 - deq_req_1 + enq_req_0; 
    wire [`ALU_QUEUE_IDX_LEN-1:0] tail_update_val = $signed(new_tail_1) > 0 ? new_tail_1 : 0;

    wire [`ALU_QUEUE_LEN-1:0] wr_vec_0 = enq_req_0 ? ( 16'b1 << new_tail_0 ) : 16'b0;
    wire [`ALU_QUEUE_LEN-1:0] wr_vec_1 = enq_req_1 ? ( 16'b1 << new_tail_1 ) | wr_vec_0 : wr_vec_0;

    wire [`ALU_QUEUE_LEN-1:0] cmp_en;
    wire [`ALU_QUEUE_LEN-1:0] w_en = wr_vec_1;
    ALU_Queue_Meta dout[`ALU_QUEUE_LEN+1:0];
    Queue_Ctrl_Meta queue_ctrl[`ALU_QUEUE_LEN-1:0];
    assign dout[`ALU_QUEUE_LEN] = 0;
    assign dout[`ALU_QUEUE_LEN+1] = 0;
    assign rdy_next_state[`ALU_QUEUE_LEN] = 0;
    assign rdy_next_state[`ALU_QUEUE_LEN+1] = 0;
    assign valid_vec =  ( tail == `ALU_QUEUE_IDX_LEN'd0 ) ? `ALU_QUEUE_LEN'b0000_0000 : 
                        ( tail == `ALU_QUEUE_IDX_LEN'd1 ) ? `ALU_QUEUE_LEN'b0000_0001 : 
                        ( tail == `ALU_QUEUE_IDX_LEN'd2 ) ? `ALU_QUEUE_LEN'b0000_0011 : 
                        ( tail == `ALU_QUEUE_IDX_LEN'd3 ) ? `ALU_QUEUE_LEN'b0000_0111 : 
                        ( tail == `ALU_QUEUE_IDX_LEN'd4 ) ? `ALU_QUEUE_LEN'b0000_1111 : 
                        ( tail == `ALU_QUEUE_IDX_LEN'd5 ) ? `ALU_QUEUE_LEN'b0001_1111 : 
                        ( tail == `ALU_QUEUE_IDX_LEN'd6 ) ? `ALU_QUEUE_LEN'b0011_1111 : 
                        ( tail == `ALU_QUEUE_IDX_LEN'd7 ) ? `ALU_QUEUE_LEN'b0111_1111 : 
                        ( tail == `ALU_QUEUE_IDX_LEN'd8 ) ? `ALU_QUEUE_LEN'b1111_1111 : `ALU_QUEUE_LEN'b0000_0000;
    ALU_Queue_Meta din_0_with_rdy, din_1_with_rdy;
    assign din_0_with_rdy.rdys.prs1_rdy = ~busyvec_l[8] | din_0.rdys.prs1_rdy;
    assign din_0_with_rdy.rdys.prs2_rdy = ~busyvec_r[8] | din_0.rdys.prs2_rdy;
    assign din_1_with_rdy.rdys.prs1_rdy = ~busyvec_l[9] | din_1.rdys.prs1_rdy;
    assign din_1_with_rdy.rdys.prs2_rdy = ~busyvec_r[9] | din_1.rdys.prs2_rdy;
    assign din_0_with_rdy.ops = din_0.ops;
    assign din_1_with_rdy.ops = din_1.ops;
    genvar i;
    generate 
        for(i=0;i<`ALU_QUEUE_LEN;i++)   begin
            iq_entry_ALU u_iq_entry_ALU(
                .clk                (clk             ),
                .rst                (rst             ),
                .flush              (flush           ),
                .queue_ctrl         (queue_ctrl[i]   ),
                .din0               (din_0_with_rdy  ),
                .din1               (din_1_with_rdy  ),
                .up0                (dout[i+1]       ),
                .up0_rdy            (rdy_next_state[i+1]),
                .up1                (dout[i+2]       ),
                .up1_rdy            (rdy_next_state[i+2]),
                .dout               (dout[i]         ),
                .rdy                (ready_vec[i]    ),
                .rs0                (scoreboard_rd_num_l[i]     ),
                .rs1                (scoreboard_rd_num_r[i]     ),
                .busy_rs0           (busyvec_l[i]     ),
                .busy_rs1           (busyvec_r[i]     ),
                .rdy_next_state     (rdy_next_state[i])
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
            tail <= `ALU_QUEUE_IDX_LEN'b0;
        end else if(freeze)begin
            tail <= tail - deq_req_0 - deq_req_1;
        end else begin
            tail <= tail + enq_req_0 + enq_req_1 - deq_req_0 - deq_req_1;
        end
    end

endmodule

module issue_unit_ALU(
    input clk,
    input rst,
    input flush,        // 清除请求
    input ALU_Queue_Meta inst_Ops_0, inst_Ops_1,      // 从译码模块来的，指令的译码信息
    input enq_req_0, enq_req_1,                     // 指令入队请求
    output UOPBundle issue_info_0, issue_info_1,         // 输出给执行单元流水线的
    output issue_en_0, issue_en_1,
    output PRFNum wake_reg_0, wake_reg_1,
    output wake_reg_0_en, wake_reg_1_en,
    output ready,
    output PRFNum [9:0] scoreboard_rd_num_l,
    output PRFNum [9:0] scoreboard_rd_num_r,
    input [9:0] busyvec_l,
    input [9:0] busyvec_r
    );
    assign scoreboard_rd_num_l[8] = inst_Ops_0.ops.op0PAddr;
    assign scoreboard_rd_num_l[9] = inst_Ops_1.ops.op0PAddr;
    assign scoreboard_rd_num_r[8] = inst_Ops_0.ops.op1PAddr;
    assign scoreboard_rd_num_r[9] = inst_Ops_1.ops.op1PAddr;


    wire [`ALU_QUEUE_LEN-1:0] ready_vec, valid_vec;

    wire [`ALU_QUEUE_IDX_LEN-2:0]   sel0, sel1;
    wire                            sel0_valid, sel1_valid, sel_valid;
    ALU_Queue_Meta                  alu_queue_dout0, alu_queue_dout1;
    UOPBundle                       uops0, uops1;
    assign uops0                    = alu_queue_dout0.ops;
    assign uops1                    = alu_queue_dout1.ops;
    assign wake_reg_0               = uops0.dstPAddr;
    assign wake_reg_1               = uops1.dstPAddr;
    assign wake_reg_0_en            = uops0.dstwe && sel0_valid;
    assign wake_reg_1_en            = uops1.dstwe && sel1_valid;
    assign issue_info_0             = uops0;
    assign issue_info_1             = uops1;
    assign issue_en_0               = sel0_valid;
    assign issue_en_1               = sel1_valid;

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
        .full           (full           ),
        // Wake Info
        .scoreboard_rd_num_l(scoreboard_rd_num_l),
        .scoreboard_rd_num_r(scoreboard_rd_num_r),
        .busyvec_l(busyvec_l),
        .busyvec_r(busyvec_r)
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
