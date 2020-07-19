`timescale 1ns / 1ps
`include "../defines/defines.svh"
module iq_entry_MDU(
    input clk,
    input rst,
    input flush,
    input Wake_Info wake_Info,
    input Queue_Ctrl_Meta queue_ctrl,
    input MDU_Queue_Meta din0, up0,
    output MDU_Queue_Meta dout,
    output rdy
    );

    MDU_Queue_Meta up_data; 
    wire rs1waked, rs2waked, new_prs1_rdy, new_prs2_rdy;
    assign up_data = up0;
    MDU_Queue_Meta enq_data; 
    assign enq_data = din0;
    MDU_Queue_Meta next_data;
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

    MDU_Queue_Meta next_data_with_wake;
    assign next_data_with_wake.ops_hi = next_data.ops_hi;
    assign next_data_with_wake.ops_lo = next_data.ops_lo;
    assign next_data_with_wake.rdys = rdys;
    assign next_data_with_wake.isMul = next_data.isMul;

    assign rdy = dout.rdys.prs1_rdy && dout.rdys.prs2_rdy;

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
    input Wake_Info wake_Info,
    input [`MDU_QUEUE_IDX_LEN-2:0] deq0_idx,
    input MDU_Queue_Meta din_0, 
    output MDU_Queue_Meta dout_0,
    output full,
    output [`MDU_QUEUE_LEN-1:0] ready_vec,
    output [`MDU_QUEUE_LEN-1:0] valid_vec
    );
    reg [`MDU_QUEUE_IDX_LEN-1:0] tail;
    assign empty = (tail == `MDU_QUEUE_IDX_LEN'h0);  // 差1位满，也不能写入
    assign full = (tail == `MDU_QUEUE_IDX_LEN'h`MDU_QUEUE_LEN);
    assign almost_empty = (tail == `MDU_QUEUE_IDX_LEN'h1);
    wire freeze = full;

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

    genvar i;
    generate 
        for(i=0;i<`MDU_QUEUE_LEN;i++)   begin
            iq_entry_MDU u_iq_entry_MDU(
                .clk                (clk             ),
                .rst                (rst             ),
                .flush              (flush           ),
                .queue_ctrl         (queue_ctrl[i]   ),
                .din0               (din_0           ),
                .up0                (dout[i+1]       ),
                .dout               (dout[i]         ),
                .rdy                (ready_vec[i]    ),
                .wake_Info          (wake_Info       )
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
    input Wake_Info wake_Info,      // TODO,外部输入唤醒信号,连接到队列中
    input MDU_Queue_Meta inst_Ops_0,      // 从译码模块来的，指令的译码信息
    input enq_req_0,                     // 指令入队请求
    // 乘除法部件正忙，不能发射
    input mul_busy,
    input div_busy,
    output UOPBundle issue_info_0,         // 输出给执行单元流水线的
    output issue_en_0,
    output ready
    );

    wire [`MDU_QUEUE_LEN-1:0] ready_vec, valid_vec;

    wire [`MDU_QUEUE_IDX_LEN-2:0]   sel0;
    wire                            sel0_valid;
    MDU_Queue_Meta                  mdu_queue_dout0;
    UOPBundle                       uops0;
    assign uops0                    = mdu_queue_dout0.ops;
    assign issue_info_0             = uops0;
    assign issue_en_0               = sel0_valid;

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
        // To Exu
        .dout_0         (mdu_queue_dout0),
        // To Dispatch
        .full           (full           ),
        // Wake Info
        .wake_Info      (wake_Info)
    );

    assign ready = ~full;   // 如果满了，则不能继续接受

    wire [`MDU_QUEUE_LEN-1:0] arbit_vec = ready_vec & valid_vec;

    // 发射仲裁逻辑
    issue_arbiter_8_sel1 arbit(
        .rdys       (arbit_vec  ),
        .sel0       (sel0       ),
        .sel0_valid (sel0_valid )
    );

endmodule
