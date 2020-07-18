`timescale 1ns / 1ps
`include "../defines/defines.svh"
module issue_unit_alu_tb(

    );

reg clk;
reg rst;
reg flush;        // 清除请求
Wake_Info wake_Info;      // TODO,外部输入唤醒信号,连接到队列中
ALU_Queue_Meta inst_Ops_0, inst_Ops_1;      // 从译码模块来的，指令的译码信息
reg enq_req_0, enq_req_1;                     // 指令入队请求
// Output
UOPBundle issue_info_0, issue_info_1;         // 输出给执行单元流水线的
wire issue_en_0, issue_en_1;
PRFNum wake_reg_0, wake_reg_1, wake_reg_2, wake_reg_3;
wire wake_reg_0_en, wake_reg_1_en;
reg wake_reg_2_en, wake_reg_3_en;
wire ready;

issue_unit_ALU is_alu(.*);

wake_unit wku(.*);

initial begin
    #0 clk = 0;
    flush = 0;
    inst_Ops_0  = 0;
    inst_Ops_1  = 0;
    enq_req_0 = 0;
    enq_req_1 = 0;
    rst = 1;
    wake_reg_2 = 0;
    wake_reg_3 = 0;
    wake_reg_2_en = 0;
    wake_reg_3_en = 0;
    #32 rst = 0;

    // Enqueue 2 uops
    #20 
    inst_Ops_0 = 0; inst_Ops_0.ops.pc = 0; 
    inst_Ops_0.rdys.prs1_rdy = 1;       inst_Ops_0.rdys.prs2_rdy = 1;
    inst_Ops_0.ops.op0PAddr = 3;            inst_Ops_0.ops.op1PAddr = 4;
    inst_Ops_0.ops.dstPAddr = 5;            inst_Ops_0.ops.dstwe = 1;
    enq_req_0 = 1;

    inst_Ops_1 = 0; inst_Ops_1.ops.pc = 4; 
    inst_Ops_1.rdys.prs1_rdy = 1;       inst_Ops_1.rdys.prs2_rdy = 0;
    inst_Ops_1.ops.op0PAddr = 3;            inst_Ops_1.ops.op1PAddr = 5;
    inst_Ops_1.ops.dstPAddr = 6;            inst_Ops_1.ops.dstwe = 1;
    enq_req_1 = 1;
    #20 
    inst_Ops_0 = 0; inst_Ops_0.ops.pc = 8; 
    inst_Ops_0.rdys.prs1_rdy = 0;       inst_Ops_0.rdys.prs2_rdy = 0;
    inst_Ops_0.ops.op0PAddr = 7;            inst_Ops_0.ops.op1PAddr = 8;
    inst_Ops_0.ops.dstPAddr = 9;            inst_Ops_0.ops.dstwe = 1;
    enq_req_0 = 1;

    inst_Ops_1 = 0; inst_Ops_1.ops.pc = 12; 
    inst_Ops_1.rdys.prs1_rdy = 1;       inst_Ops_1.rdys.prs2_rdy = 1;
    inst_Ops_1.ops.op0PAddr = 0;            inst_Ops_1.ops.op1PAddr = 0;
    inst_Ops_1.ops.dstPAddr = 7;            inst_Ops_1.ops.dstwe = 1;
    enq_req_1 = 1;
    #20 
    inst_Ops_0 = 0; inst_Ops_0.ops.pc = 16; 
    inst_Ops_0.rdys.prs1_rdy = 1;       inst_Ops_0.rdys.prs2_rdy = 1;
    inst_Ops_0.ops.op0PAddr = 0;            inst_Ops_0.ops.op1PAddr = 0;
    inst_Ops_0.ops.dstPAddr = 8;            inst_Ops_0.ops.dstwe = 1;
    enq_req_0 = 1;

    inst_Ops_1 = 0; inst_Ops_1.ops.pc = 20; 
    inst_Ops_1.rdys.prs1_rdy = 1;       inst_Ops_1.rdys.prs2_rdy = 1;
    inst_Ops_1.ops.op0PAddr = 0;            inst_Ops_1.ops.op1PAddr = 0;
    inst_Ops_1.ops.dstPAddr = 0;            inst_Ops_1.ops.dstwe = 0;
    enq_req_1 = 0;
    #20 
    enq_req_0 = 0;
    enq_req_1 = 0;
    #50
    $finish;
end

integer i;
always @(posedge clk)   begin
    $strobe("Tail:",is_alu.u_iq_alu.tail);
    for(i=0;i<is_alu.u_iq_alu.tail;i++) begin
        $display("Slot:",i, "; PC: %x", is_alu.u_iq_alu.dout[i].ops.pc);
    end
end

always begin
    #10 clk = ~clk;
end

endmodule
