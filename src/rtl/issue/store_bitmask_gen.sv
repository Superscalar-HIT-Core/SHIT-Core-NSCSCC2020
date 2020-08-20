`timescale 1ns / 1ps

module store_bitmask_gen(
    input [7:0] store_vec,
    output reg [7:0] store_mask
);
always_comb begin
    store_mask = 8'b1111_1111;
    casez(store_vec) 
        8'b????_???1:  store_mask = 8'b0000_0001; // 只有store在队列首部的时候，才能发射
        // 否则需要等待前面的load指令都执行完
        // 其之后的load指令不能提前执行，因为可能造成RAW
        8'b????_??10:  store_mask = 8'b0000_0001;   
        8'b????_?100:  store_mask = 8'b0000_0011;
        8'b????_1000:  store_mask = 8'b0000_0111;
        8'b???1_0000:  store_mask = 8'b0000_1111;
        8'b??10_0000:  store_mask = 8'b0001_1111;
        8'b?100_0000:  store_mask = 8'b0011_1111;
        8'b1000_0000:  store_mask = 8'b0111_1111;
    endcase
end
endmodule
