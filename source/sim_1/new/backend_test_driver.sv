`timescale 1ns / 1ps
`include "../../sources_1/new/defines/defines.svh"
module backend_test_driver(

    );
reg clk,rst;

Regs_Decode  regs_decode();
Decode_Regs  decode_regs();
decode dec0(.*);
integer fp;
integer count;
initial begin
    #0 fp = $fopen("../../../../source/instr.txt","r");
    #0 clk = 0;rst = 1;
    #22 rst = 0;
    #20 regs_decode.inst = 0; regs_decode.inst.valid = 1;
end

always @(posedge clk)   begin
        count <= $fscanf(fp,"%h" ,regs_decode.inst.inst);
        regs_decode.inst.pc <= regs_decode.inst.pc+4;
end

always begin
    #10 clk = ~clk;
end

endmodule
