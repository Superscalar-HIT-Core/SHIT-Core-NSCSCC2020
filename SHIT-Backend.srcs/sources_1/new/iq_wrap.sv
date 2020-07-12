`timescale 1ns / 1ps
`include "defines/defines.svh"
module iq_wrap(
    input clk,
    input rst,
    output ALU_Queue_Meta a,b
    );
reg enq_req_0, enq_req_1, deq_req_0, deq_req_1;
reg [2:0] deq_0_idx, deq_1_idx;
ALU_Queue_Meta d[1:0];

always @(posedge clk)   begin
    if(rst) begin
        {enq_req_0, enq_req_1, deq_req_0, deq_req_1, deq_0_idx, deq_1_idx,d[0],d[1]} <= 0;
    end else begin
        {enq_req_0, enq_req_1, deq_req_0, deq_req_1, deq_0_idx, deq_1_idx,d[0],d[1]} <= 1111111;
    end
end
wire dout0_valid, dout1_valid, almost_full, full, empty, almost_empty;
    iq_alu u_iq_alu(
        .clk            (clk            ),
        .rst            (rst            ),
        .enq_req_0      (enq_req_0      ),
        .enq_req_1      (enq_req_1      ),
        .deq_req_0      (deq_req_0      ),
        .deq_req_1      (deq_req_1      ),
        .deq0_idx       (deq0_idx       ),
        .deq1_idx       (deq1_idx       ),
        .din_0 (d[0] ),
        .din_1 (d[1] ),
        .dout_0 (a ),
        .dout_1 (b ),
        .dout0_valid    (dout0_valid    ),
        .dout1_valid    (dout1_valid    ),
        .almost_full    (almost_full    ),
        .full           (full           ),
        .empty          (empty          ),
        .almost_empty   (almost_empty   )
    );
    
endmodule
