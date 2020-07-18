`timescale 1ns / 1ps
`include "defines/defines.svh"
module rename_dispatch_reg(
    input clk,
    input rst,
    input UOPBundle inst0_in, inst1_in,
    output UOPBundle inst0_out, inst1_out,
    input flush
    );

always @(posedge clk)   begin
    if( rst || flush ) begin
        inst0_out <= 0;
        inst1_out <= 0;
    end else begin
        inst0_out <= inst0_in;
        inst1_out <= inst1_in;
    end
end

endmodule
