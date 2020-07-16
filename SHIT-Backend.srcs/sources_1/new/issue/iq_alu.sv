`timescale 1ns / 1ps
`include "../defines/defines.svh"

module iq_alu(
    input clk,
    input rst,
    input flush, 
    input enq_req_0,
    input enq_req_1,
    input deq_req_0,
    input deq_req_1,
    input Wake_Info wake_Info,
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
    output [`ALU_QUEUE_LEN-1:0] valid_vec
    );
reg [`ALU_QUEUE_IDX_LEN-1:0] tail;
assign almost_full = (tail == `ALU_QUEUE_IDX_LEN'h`ALU_QUEUE_LEN_MINUS1);  // 差1位满，也不能写入
assign empty = (tail == `ALU_QUEUE_IDX_LEN'h0);  // 差1位满，也不能写入
assign full = (tail == `ALU_QUEUE_IDX_LEN'h`ALU_QUEUE_LEN);
assign almost_empty = (tail == `ALU_QUEUE_IDX_LEN'h1);
wire freeze = almost_full || full;

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
assign valid_vec =  ( tail == `ALU_QUEUE_IDX_LEN'd0 ) ? `ALU_QUEUE_LEN'b0000_0000 : 
                    ( tail == `ALU_QUEUE_IDX_LEN'd1 ) ? `ALU_QUEUE_LEN'b0000_0001 : 
                    ( tail == `ALU_QUEUE_IDX_LEN'd2 ) ? `ALU_QUEUE_LEN'b0000_0011 : 
                    ( tail == `ALU_QUEUE_IDX_LEN'd3 ) ? `ALU_QUEUE_LEN'b0000_0111 : 
                    ( tail == `ALU_QUEUE_IDX_LEN'd4 ) ? `ALU_QUEUE_LEN'b0000_1111 : 
                    ( tail == `ALU_QUEUE_IDX_LEN'd5 ) ? `ALU_QUEUE_LEN'b0001_1111 : 
                    ( tail == `ALU_QUEUE_IDX_LEN'd6 ) ? `ALU_QUEUE_LEN'b0011_1111 : 
                    ( tail == `ALU_QUEUE_IDX_LEN'd7 ) ? `ALU_QUEUE_LEN'b0111_1111 : 
                    ( tail == `ALU_QUEUE_IDX_LEN'd8 ) ? `ALU_QUEUE_LEN'b1111_1111 : `ALU_QUEUE_LEN'b0000_0000;

genvar i;
generate 
    for(i=0;i<`ALU_QUEUE_LEN;i++)   begin
        iq_entry_ALU u_iq_entry_ALU(
            .clk                (clk             ),
            .rst                (rst             ),
            .flush              (flush           ),
            .queue_ctrl         (queue_ctrl[i]),
            .din0               (din_0  ),
            .din1               (din_1  ),
            .up0                (dout[i+1]),
            .up1                (dout[i+2]),
            .dout               (dout[i]),
            .rdy                (ready_vec[i]         ),
            .wake_Info          (wake_Info)
        );
        assign queue_ctrl[i].enq_sel = (new_tail_0 != i);
        assign queue_ctrl[i].cmp_en = ( deq_req_0 && i>= deq0_idx );
        assign queue_ctrl[i].cmp_sel = ( deq_req_0 && ~deq_req_1 && i >= deq0_idx ) 
                                        || (deq_req_0 && deq_req_1 && i >= deq0_idx && i < deq1_idx -1) ? 0 : 1;
        assign queue_ctrl[i].enq_en = w_en[i];
        assign queue_ctrl[i].freeze = freeze;
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
