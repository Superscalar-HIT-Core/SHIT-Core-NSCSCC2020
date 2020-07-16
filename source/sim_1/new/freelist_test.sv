`timescale 1ns / 1ps
`define clk_off 2

module freelist_test(

    );
reg clk, rst, recover, inst_0_req, inst_1_req, free_0_req, free_1_req, commit_0_req, commit_1_req;
wire [5:0] inst_0_prf, inst_1_prf;
reg [5:0] free_0_num, free_1_num, commit_0_mark_num, commit_0_free_num,commit_1_mark_num, commit_1_free_num;
wire allocatable;
free_list ut(
    .clk(clk),
    .rst(rst),
    .recover(recover),
    // 来自指令的重命名请求
    .inst_0_req(inst_0_req),
    .inst_1_req(inst_1_req),
    .inst_0_prf(inst_0_prf),
    .inst_1_prf(inst_1_prf),
    // 如果不足以同时满足两条指令的重命名请求，则直接暂停
    .allocatable(allocatable), // 只有两个list都满足，才能够进行分配
    .free_0_req(free_0_req),
    .free_1_req(free_1_req),
    .free_0_num(free_0_num),
    .free_1_num(free_1_num),
    .commit_0_req(commit_0_req),
    .commit_0_mark_num(commit_0_mark_num),
    .commit_0_free_num(commit_0_free_num),
    .commit_1_req(commit_1_req),
    .commit_1_mark_num(commit_1_mark_num),
    .commit_1_free_num(commit_1_free_num)
);

initial begin
    #0 clk = 0; rst = 1;recover = 0; inst_0_req=1; inst_1_req=1 ;commit_0_req=0; commit_1_req=0;
    free_0_req = 0; free_1_req = 0; free_0_num = 0; free_1_num = 0;
    #22 rst = 0;
    #1000 free_0_req = 1; free_0_num = 20;
    #20 free_1_req = 1; free_1_num = 24;
    #20 free_0_req = 0; free_1_req = 0;
    #10 commit_0_mark_num=1; commit_0_free_num=2; commit_1_mark_num=3; commit_1_free_num=4;
    #10 commit_0_req = 1; 
    commit_1_req = 1;
    #10 recover = 1;
    #20 recover = 0;
end

always begin
    #10 clk = ~clk;
end


endmodule
