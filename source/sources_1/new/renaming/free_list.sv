`timescale 1ns / 1ps
`include "../defines/defines.svh"
module free_list(
    input clk,
    input rst,
    input recover,      // recover �źŽ�֧��һ������
    input pause,
    // ����ָ�������������
    // ���Ŀ�ļĴ�����0������Ҫ����������
    input inst_0_req,
    input inst_1_req,
    output PRFNum inst_0_prf,
    output PRFNum inst_1_prf,
    // Info from commit
    input commit_valid_0,
    input commit_valid_1,
    input commit_info commit_info_0,
    input commit_info commit_info_1,
    // ���������ͬʱ��������ָ���������������ֱ����ͣ
    output allocatable // ֻ������list�����㣬���ܹ����з���
);

// �����б���������ѷ��������
// 1��ռ�ã�0��free
reg [`PRF_NUM-1:0] free_list_1, committed_fl;
wire [`PRF_NUM-1:0] free_list_2, free_list_3, free_list_4, free_list_5;
wire free_valid_0, free_valid_1;

wire [`PRF_NUM_WIDTH-1:0] free_num_0, free_num_1;

freelist_enc64 enc0(
    .free_list(free_list_1),
    .free_valid(free_valid_0),
    .free_num(free_num_0)
);

assign free_list_2 = inst_0_req ? (free_list_1 | (1'b1 << free_num_0)) : free_list_1;   // ��һ��ָ�����֮��
// assign free_list_2 = free_list_1;   // ��һ��ָ�����֮��

freelist_enc64 enc1(
    .free_list(free_list_2),
    .free_valid(free_valid_1),
    .free_num(free_num_1)
);

assign free_list_3 = inst_1_req ? (free_list_2 | (1'b1 << free_num_1)) : free_list_2;   // �ڶ���ָ�����֮��

// assign allocatable =    (free_valid_0 && inst_0_req && free_valid_1 && inst_1_req) ||
//                         (free_valid_0 && inst_0_req && ~inst_1_req) ||
//                         (free_valid_1 && inst_1_req && ~inst_0_req) || (~inst_0_req && ~inst_1_req); // ֻ��һ��ָ������������������˵����

reg [5:0] num_free_regs, committed_num_free_regs;
// Once an instruction is committed, the number of free regs will not increase
// Only need to consider the newly allocated regs(stale is zero)
// For newly allocated register, if the stale is 0, it has no register to free
wire commit_allocate_new_0 = commit_info_0.wr_reg_commit && commit_valid_0 && commit_info_0.stale_prf == 0;
wire commit_allocate_new_1 = commit_info_1.wr_reg_commit && commit_valid_1 && commit_info_1.stale_prf == 0;
// The committed instruction has a register to free
wire commit_free_0 = commit_info_0.wr_reg_commit && commit_valid_0 && commit_info_0.stale_prf != 0;
wire commit_free_1 = commit_info_1.wr_reg_commit && commit_valid_1 && commit_info_1.stale_prf != 0;
assign allocatable =    ( inst_0_req ^ inst_1_req ) ? num_free_regs >=1 : 
                        ( inst_0_req & inst_1_req ) ? num_free_regs >=2 : 1;
always_ff @(posedge clk) begin
    if(rst) begin
        num_free_regs <= 63;
    end else if(recover) begin
        num_free_regs <= committed_num_free_regs;
    end else if(allocatable && ~pause) begin
        num_free_regs <= num_free_regs - inst_0_req - inst_1_req + commit_free_0 + commit_free_1;
    end else begin
        num_free_regs <= num_free_regs + commit_free_0 + commit_free_1;
    end
end

always_ff @(posedge clk) begin
    if(rst) begin
        committed_num_free_regs <= 63;
    end else begin
        committed_num_free_regs <= committed_num_free_regs - commit_allocate_new_0 - commit_allocate_new_1;
    end
end



// free_list after freeing the registers
wire [`PRF_NUM-1:0] free_list_after_alloc = allocatable ? free_list_3 : free_list_1;    // ����һ���ܹ�����������������ͣ

// ���Free֮����commit�׶ε����룬�ͷ�stale
assign free_list_4 = commit_info_0.wr_reg_commit && commit_valid_0 ? (free_list_after_alloc & ~(`PRF_NUM'b1 << commit_info_0.stale_prf)) : free_list_after_alloc;
assign free_list_5 = commit_info_1.wr_reg_commit && commit_valid_1 ? (free_list_4 & ~(`PRF_NUM'b1 << commit_info_1.stale_prf)) : free_list_4;

wire [`PRF_NUM-1:0] free_list1_after_free = commit_valid_0 ? (free_list_1 & ~(`PRF_NUM'b1 << commit_info_0.stale_prf)) : free_list_1;
wire [`PRF_NUM-1:0] free_list2_after_free = commit_valid_1 ? (free_list1_after_free & ~(`PRF_NUM'b1 << commit_info_1.stale_prf)) : free_list1_after_free;

always @(posedge clk)   begin
    if(rst) begin
        free_list_1 <= `PRF_NUM'b1;     // 0�żĴ�����Զ�������ȥ
    end else if(recover)    begin
        free_list_1 <= committed_fl | `PRF_NUM'b1;
    end else if(pause)  begin
        free_list_1 <= free_list2_after_free | `PRF_NUM'b1;   // ��ͣʱ��ֻ�����ͷţ������з���
    end else begin
        free_list_1 <= free_list_5 | `PRF_NUM'b1;
    end
end

wire [`PRF_NUM-1:0] committed_fl_0, committed_fl_1;
assign committed_fl_0 = commit_info_0.wr_reg_commit && commit_valid_0 ? (committed_fl & ~(`PRF_NUM'b1 << commit_info_0.stale_prf) | (`PRF_NUM'b1 << commit_info_0.committed_prf)) : committed_fl;
assign committed_fl_1 = commit_info_1.wr_reg_commit && commit_valid_1 ? (committed_fl_0 & ~(`PRF_NUM'b1 << commit_info_1.stale_prf) | (`PRF_NUM'b1 << commit_info_1.committed_prf)) : committed_fl_0;


always @(posedge clk)   begin
    if(rst) begin
        committed_fl <= `PRF_NUM'b1;    // 0�żĴ�����Զ�������ȥ
    end else begin
        committed_fl <= committed_fl_1 | `PRF_NUM'b1;
    end
end



assign inst_0_prf = free_num_0;
assign inst_1_prf = free_num_1;

// synopsys_translate_off
reg [5:0] debug_commit_free_regs, debug_free_regs;
always_comb begin
    debug_commit_free_regs = 0;
    debug_free_regs = 0;
    for(integer i = 0;i<64;i++) begin
        if(committed_fl[i] == 0) debug_commit_free_regs = debug_commit_free_regs + 1;
        if(free_list_1[i] == 0) debug_free_regs = debug_free_regs + 1;
    end
end
// synopsys_translate_on

endmodule