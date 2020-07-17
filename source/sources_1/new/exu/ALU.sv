`timescale 1ns / 1ps
`include "../defines/defines.svh"
`include "../defs.sv"
module ALU(
    input UOPBundle uops,       // 输入的微操作
    input PRFrData rdata,       // 寄存器读入的数据
    input BypassInfo bypass_alu0, bypass_alu1,  // 从下一级和下面的ALU旁路回来
    output PRFwInfo wbData,     // 计算回写的数据
    output uops_o               // 传递给下一级的
    );

// Result Select
Word move_res;
Word arithmetic_res;
Word branch_res;
logic bypass_alu0_src0_en = bypass_alu0.wen && (bypass_alu0.wrNum == uops.op0PAddr);
logic bypass_alu0_src1_en = bypass_alu0.wen && (bypass_alu0.wrNum == uops.op1PAddr);
logic bypass_alu1_src0_en = bypass_alu1.wen && (bypass_alu1.wrNum == uops.op0PAddr);
logic bypass_alu1_src1_en = bypass_alu1.wen && (bypass_alu1.wrNum == uops.op1PAddr);

Word src0, src1;
assign src0 = uops.op0re ? ( bypass_alu0_src0_en ?  bypass_alu0.wData : 
                            ( bypass_alu1_src0_en ? bypass_alu1.wData : rdata.rs0_data ) ) : rdata.rs0_data;
assign src1 = uops.op1re ? ( bypass_alu0_src1_en ?  bypass_alu0.wData : 
                            ( bypass_alu1_src1_en ? bypass_alu1.wData : rdata.rs0_data ) ) : uops.imm ;

uOP uop;
assign uop = uops.uOP;
assign uops_o = uops;

// 逻辑运算结果
assign logic_res =  ( uop == OR_U || uop == ORI_U || uop == LUI_U ) ? src0 | src1 :
                    ( uop == AND_U || uop == ANDI_U ) ? src0 & src1 :
                    ( uop == NOR_U ) ? ~(src0 | src1) :
                    ( uop == XOR_U || uop == XORI_U ) ? src0 ^ src1 : 32'b0;

// 移位运算结果
assign shift_res =  ( uop == SLL_U || uop == SLLV_U ) ? src1 << src0[4:0] :
                    ( uop == SRL_U || uop == SRLV_U) ? src1 >> src0[4:0] :
                    ( uop == SRA_U || uop == SRAV_U ) ? 
                    ( {32{src1[31]}} << (6'd32 - {1'b0, src0[4:0]}) ) | src1 >> src0[4:0] : 32'b0;

// 算术运算结果
wire [31:0] src1_complement;
wire [31:0] sum;
assign src1_complement = ( uop == SUB_U || uop == SUBU_U || uop == SLT_U || uop == SLTI_U ) ? ( ~src1 + 1'b1 ) : src1;
assign sum = src0 + src1_complement;
assign src0_lt_src1 =   ( uop == SLT_U || uop == SLTI_U ) ? // Signed compare
                        ( (src0[31] & !src1[31]) | 
                        ( !src0[31] & !src1[31] & sum[31]) | 
                        ( src0[31] & src1[31] & sum[31]) ) : 
                        ( src0 < src1 );                    // Unsigned Compare

assign arithmetic_res = ( uop == SLT_U || uop == SLTI_U || uop == SLTU_U || uop == SLTIU_U ) ? 
                        src0_lt_src1 : sum;
                        

// 移动指令结果
assign move_res = src0; // HILO寄存器被重命名，无论是MF还是MT，都是第一个操作数

// 分支指令结果
assign branch_res = uops.pc + 32'd8;

// 溢出的检查
wire overflow;
assign overflow =   ( (!src0[31] & !src1_complement[31] & sum[31]) | 
                    ( src0[31] & src1_complement[31] & !sum[31]) ) & 
                    ( ( uop == ADD_U ) || ( uop == ADDI_U ) || ( uop == SUB_U ) ) ? 
                    1'b1 : 1'b0; 

ALUType alutype = uops.aluType;

// 结果赋值
assign wbData.rd = uops.dstPAddr;
assign wbData.wen = uops.dstwe;
assign wbData.wdata =   ( alutype == ALU_LOGIC ) ? logic_res :
                        ( alutype == ALU_SHIFT ) ? shift_res :
                        ( alutype == ALU_ARITH ) ? arithmetic_res :
                        ( alutype == ALU_MOVE ) ? move_res :
                        ( alutype == ALU_BRANCH ) ? branch_res : 32'b0;


endmodule
