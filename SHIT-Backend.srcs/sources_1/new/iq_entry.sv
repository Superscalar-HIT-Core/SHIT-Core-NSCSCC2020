`timescale 1ns / 1ps
`include "defines/defines.svh"
module iq_entry_ALU(
    input clk,
    input rst,
    input Queue_Ctrl_Meta queue_ctrl,
    input ALU_Queue_Meta din0, din1, up0, up1,
    output ALU_Queue_Meta dout,
    output rdy
    );

ALU_Queue_Meta up_data = ( queue_ctrl.cmp_sel == 1'b0 ) ? up0 : up1;
ALU_Queue_Meta enq_data = ( queue_ctrl.enq_sel == 1'b0 ) ? din0: din1;

always_ff @(posedge clk)    begin
    if(rst) begin
        dout <= 0;
    end else if( queue_ctrl.cmp_en )    begin
        dout <= up_data;
    end else if( queue_ctrl.enq_en )    begin
        dout <= enq_data;
    end
end

// TODO:


endmodule
