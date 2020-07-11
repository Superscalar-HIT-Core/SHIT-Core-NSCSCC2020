`timescale 1ns / 1ps
`include "../defines/defines.svh"
// Compressed queue entry prototype ( compress by 2 )
module compress_queue_entry_prototype(
    input clk,
    input rst,
    input cmp_en,
    input [1:0] dsel,
    input enq_en,
    input enq_sel,
    input [3:0] din1,
    input [3:0] din2,
    input freeze,
    input [3:0] up2_data,
    input [3:0] up1_data,
    output reg [3:0] dout
    );

wire [3:0] new_data =   (dsel == `CMPQ_SEL_DIN1) ? din1 : 
                        (dsel == `CMPQ_SEL_DIN1) ? din2 : 
                        (dsel == `CMPQ_SEL_UP1) ? up1_data :
                        (dsel == `CMPQ_SEL_UP2) ? up2_data : dout;

wire [3:0] enq_data = (enq_sel == 0) ? din1 : din2;

always @(posedge clk) begin
    if(rst) begin
        dout <= 4'b0;
    end else if(cmp_en)    begin
        dout <= new_data;
    end else if(enq_en && ~freeze)     begin
        dout <= enq_data;
    end
end

endmodule
