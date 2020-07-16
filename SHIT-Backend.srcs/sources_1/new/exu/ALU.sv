`timescale 1ns / 1ps
`include "defines.svh"
module ALU(
    input UOPBundle uops,       // 输入的微操作
    input PRFrData rdata,       // 寄存器读入的数据
    input BypassInfo bypass_alu0, bypass_alu1,  // 从下一级和下面的ALU旁路回来
    output PRFwInfo wbData,     // 计算回写的数据
    output uops_o               // 传递给下一级的
    );

// TODO

endmodule
