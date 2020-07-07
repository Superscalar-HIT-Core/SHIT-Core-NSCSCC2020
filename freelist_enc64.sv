`timescale 1ns / 1ps

module freelist_enc64(
    input [`PRF_NUM-1:0] free_list,
    output free_valid,
    output [`PRF_NUM_WIDTH-1:0] free_num
    );
wire [2:0] free_nums_low3[7:0];
wire [2:0] free_nums_hi3;
wire [7:0] free_valid_l1;
wire free_valid_l2;
// Encode a free list vector
// Level 1
// 8 * 8 -> 1 encoder
genvar i;
generate 
    for (i=0;i<8;i=i+1) begin
        fl_encoder_8 u1(.src(free_list[i*8+7: i*8]), .freenum(free_nums_low3[i]), .free_valid(free_valid_l1[i]));
    end
endgenerate
// Level 2
// 8 -> 1 encoder
fl_encoder_8 l2(.src(~free_valid_l1), .freenum(free_nums_hi3), .free_valid(free_valid_l2));
assign free_num = { free_nums_hi3, free_nums_low3[free_nums_hi3] };
assign free_valid = free_valid_l2;
endmodule
