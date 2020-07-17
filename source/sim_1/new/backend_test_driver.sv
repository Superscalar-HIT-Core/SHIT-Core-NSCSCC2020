`timescale 1ns / 1ps
`include "../../sources_1/new/defines/defines.svh"
module backend_test_driver(

    );
reg clk,rst;

Regs_Decode  regs_decode();
Decode_Regs  decode_regs();
decode dec0(.*);

initial begin
    #0 clk = 0;rst = 1;
    #22 rst = 0;
end

always begin
    #10 clk = ~clk;
end

endmodule
