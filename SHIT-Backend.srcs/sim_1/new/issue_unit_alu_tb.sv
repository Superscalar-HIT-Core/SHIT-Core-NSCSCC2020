`timescale 1ns / 1ps
`include "../defines/defines.svh"
module issue_unit_alu_tb(

    );

reg clk;
reg rst;
reg flush;        // 清除请求
Wake_Info wake_info;      // TODO,外部输入唤醒信号,连接到队列中
ALU_Queue_Meta inst_Ops_0, inst_Ops_1;      // 从译码模块来的，指令的译码信息
reg enq_req_0, enq_req_1;                     // 指令入队请求
// Output
UOPBundle issue_info_0, issue_info_1;         // 输出给执行单元流水线的
wire issue_en_0, issue_en_1;
PRFNum wake_reg_0, wake_reg_1;
wire wake_reg_0_en, wake_reg_1_en;
wire ready;

issue_alu is_alu(.*);


initial begin
    #0 clk = 0;
    flush = 0;
    wake_info = 0;
    inst_Ops_0  = 0;
    inst_Ops_1  = 0;
    enq_req_0 = 0;
    enq_req_1 = 0;
    rst = 1;
    #32 rst = 0;

    // Enqueue 2 uops
    #20 
    inst_Ops_0 = 0; inst_Ops_0.ops.pc = 0; inst_Ops_0.rdys = 2'b11; inst_Ops_0.ops.id = 0; enq_req_0 = 1;
    inst_Ops_1 = 0; inst_Ops_1.ops.pc = 1; inst_Ops_1.rdys = 2'b11; inst_Ops_1.ops.id = 1; enq_req_1 = 1;
    #20 
    inst_Ops_0 = 0; inst_Ops_0.ops.pc = 2; inst_Ops_0.rdys = 2'b11;inst_Ops_0.ops.id = 2; enq_req_0 = 1;
    inst_Ops_1 = 0; inst_Ops_1.ops.pc = 3; inst_Ops_1.ops.id = 3; enq_req_1 = 1;
    #20 
    inst_Ops_0 = 0; inst_Ops_0.ops.pc = 4; inst_Ops_0.ops.id = 4; enq_req_0 = 1;
    inst_Ops_1 = 0; inst_Ops_1.ops.pc = 5; inst_Ops_1.ops.id = 5; enq_req_1 = 1;
    #20 
    inst_Ops_0 = 0; inst_Ops_0.ops.pc = 2; inst_Ops_0.ops.id = 6; enq_req_0 = 1;
    inst_Ops_1 = 0; inst_Ops_1.ops.pc = 3; inst_Ops_1.ops.id = 5; enq_req_1 = 1;
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
