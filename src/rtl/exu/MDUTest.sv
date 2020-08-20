`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/21 00:12:38
// Design Name: 
// Module Name: MDUTest
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../defines/defines.svh"


module MDUTest(

);

    logic               clk;
    logic               rst;
    UOPBundle           uopHi;
    UOPBundle           uopLo;
    PRFrData            rdata;
    PRFwInfo            wbData;
    logic               mulBusy;
    logic               divBusy;

    FU_ROB               mdu_rob();
    MDUTestInterface_MUL mul();
    MDUTestInterface_DIV div();

    assign mul.clk        = clk;
    assign div.clk        = clk;
    assign uopHi.uOP      = mul.uopHi.valid === `TRUE ? mul.uopHi.uOP : div.uopHi.uOP;
    assign uopLo.uOP      = mul.uopLo.valid === `TRUE ? mul.uopLo.uOP : div.uopLo.uOP;
    assign uopHi.id       = mul.uopHi.valid === `TRUE ? mul.uopHi.id  : div.uopHi.id ;
    assign uopLo.id       = mul.uopLo.valid === `TRUE ? mul.uopLo.id  : div.uopLo.id ;
    assign uopHi.valid    = mul.uopHi.valid === `TRUE | div.uopHi.valid === `TRUE;
    assign uopLo.valid    = mul.uopLo.valid === `TRUE | div.uopLo.valid === `TRUE;
    assign rdata          = mul.uopLo.valid === `TRUE ? mul.rdata : div.rdata;
    assign mul.mulBusy    = mulBusy;
    assign div.divBusy    = divBusy;

    always #10 clk = ~clk;

    MDU mdu(.*);

    initial begin
        mul.init();
        div.init();
        clk = 1'b0;
        rst = 1'b1;
        #115
        rst = 1'b0;

        mul.sendMul(        2,          3, 12'h000);
        mul.sendMul(  2000000,    3000000, 12'h002);
        mul.sendMul(        2,          3, 12'h004);
        mul.sendMul(  2000000,    3000000, 12'h006);
        mul.sendMul(        2,          3, 12'h008);
        mul.sendMul(  2000000,    3000000, 12'h00a);
        mul.sendMul(        2,          3, 12'h00c);
        mul.sendMul(  2000000,    3000000, 12'h01e);
        mul.sendMul(        2,          3, 12'h010);
        mul.sendMul(  2000000,    3000000, 12'h012);
        mul.sendMul(        2,          3, 12'h014);
        mul.sendMul(  2000000,    3000000, 12'h016);
        mul.sendMul(        2,          3, 12'h018);
        mul.sendMul(  2000000,    3000000, 12'h01a);
        mul.sendMul(        2,          3, 12'h01c);
        mul.sendMul(  2000000,    3000000, 12'h01e);
        mul.sendMul(        2,          3, 12'h020);
        mul.sendMul(  2000000,    3000000, 12'h022);
        mul.sendMul(        2,          3, 12'h024);
        mul.sendMul(  2000000,    3000000, 12'h026);
        mul.sendMul(        2,          3, 12'h028);
        mul.sendMul(  2000000,    3000000, 12'h02a);
        mul.sendMul(        2,          3, 12'h02c);
        mul.sendMul(  2000000,    3000000, 12'h02e);
        mul.sendMul(        2,          3, 12'h030);
        mul.sendMul(  2000000,    3000000, 12'h032);
        mul.sendMul(        2,          3, 12'h034);
        mul.sendMul(  2000000,    3000000, 12'h036);
        mul.sendMul(        2,          3, 12'h038);
        mul.sendMul(  2000000,    3000000, 12'h03a);
        mul.sendMul(        2,          3, 12'h03c);
        mul.sendMul(  2000000,    3000000, 12'h03e);
        mul.sendMul(        2,          3, 12'h040);
        mul.sendMul(  2000000,    3000000, 12'h042);
        mul.sendMul(        2,          3, 12'h044);
        mul.sendMul(  2000000,    3000000, 12'h046);
        mul.sendMul(        2,          3, 12'h048);
        mul.sendMul(  2000000,    3000000, 12'h04a);
        mul.sendMul(        2,          3, 12'h04c);
        mul.sendMul(  2000000,    3000000, 12'h04e);
    end

    initial begin
        #115

        div.sendDiv(23, 7, 12'h100, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h102, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h104, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h106, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h108, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h10a, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h10c, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h11e, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h110, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h112, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h114, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h116, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h118, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h11a, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h11c, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h11e, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h120, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h122, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h124, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h126, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h128, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h12a, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h12c, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h12e, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h130, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h132, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h134, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h136, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h138, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h13a, mul.uopHi.valid);
        div.sendDiv(23, 7, 12'h13c, mul.uopHi.valid);
        div.sendDiv(51, 9, 12'h13e, mul.uopHi.valid);
    end

endmodule
