`include "defines.svh"
module free_list(
    input clk,
    input rst,
    input recover,
    // ����ָ�������������
    input inst_0_req,
    input inst_1_req,
    output [`PRF_NUM_WIDTH-1:0] inst_0_prf,
    output [`PRF_NUM_WIDTH-1:0] inst_1_prf,
    input free_0_req,
    input free_1_req,
    input [`PRF_NUM_WIDTH-1:0] free_0_num,
    input [`PRF_NUM_WIDTH-1:0] free_1_num,
    // ���������ͬʱ��������ָ���������������ֱ����ͣ
    output allocatable // ֻ������list�����㣬���ܹ����з���
);

// �����б���������ѷ��������
// 1��ռ�ã�0��free
reg [`PRF_NUM-1:0] free_list_1;
wire [`PRF_NUM-1:0] free_list_2, free_list_3, free_list_4, free_list_5;
reg [`PRF_NUM-1:0] allocated_list;
wire free_valid_0, free_valid_1;

wire [`PRF_NUM_WIDTH-1:0] free_num_0, free_num_1;

freelist_enc64 enc0(
    .free_list(free_list_1),
    .free_valid(free_valid_0),
    .free_num(free_num_0)
);

assign free_list_2 = inst_0_req ? (free_list_1 | (1'b1 << free_num_0)) : free_list_1; 

freelist_enc64 enc1(
    .free_list(free_list_2),
    .free_valid(free_valid_1),
    .free_num(free_num_1)
);

assign free_list_3 = inst_1_req ? (free_list_2 | (1'b1 << free_num_1)) : free_list_2;

// free_list after freeing the registers
wire [`PRF_NUM-1:0] free_list_after_alloc = allocatable ? free_list_3 : free_list_1;
assign free_list_4 = free_0_req ? (free_list_after_alloc & ~(`PRF_NUM'b1 << free_0_num)) : free_list_after_alloc;
assign free_list_5 = free_1_req ? (free_list_4 & ~(`PRF_NUM'b1 << free_1_num)) : free_list_4;

assign allocatable = free_valid_0 & free_valid_1;

always @(posedge clk)   begin
    if(rst) begin
        free_list_1 <= `PRF_NUM'b0;
        allocated_list <= `PRF_NUM'b0;
    end else if(recover)    begin
        // todo
    end else begin
        free_list_1 <= free_list_5;
    end
end
 
assign inst_0_prf = free_num_0;
assign inst_1_prf = free_num_1;

endmodule