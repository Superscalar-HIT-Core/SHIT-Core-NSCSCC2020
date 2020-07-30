`timescale 1ns / 1ps
// 6位随机数生成器
module RandGen (
    input clk,
    input rst,
    input [7:0] random_seed,
    output reg [7:0] random_num
);
always @(posedge clk)   begin
    if(rst) begin
        random_num <= random_seed;
    end else begin
        random_num[0] <= random_num[7];
        random_num[1] <= random_num[0];
        random_num[2] <= random_num[1];
        random_num[3] <= random_num[2];
        random_num[4] <= random_num[3]^random_num[7];
        random_num[5] <= random_num[4]^random_num[7];
        random_num[6] <= random_num[5]^random_num[7];
        random_num[7] <= random_num[6];
    end
end

endmodule