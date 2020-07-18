`timescale 1ns / 1ps
// 用于发射仲裁的逻辑(队列容量8)
module issue_arbiter_8_sel1(
    input [7:0] rdys,
    output reg [2:0] sel0,
    output reg sel0_valid
    );

wire [7:0] rdys_0 = rdys;
always_comb begin
    sel0_valid = 1;
    casez(rdys_0)    
        8'b???????1: sel0 = 3'b000;
        8'b??????10: sel0 = 3'b001;
        8'b?????100: sel0 = 3'b010;
        8'b????1000: sel0 = 3'b011;
        8'b???10000: sel0 = 3'b100;
        8'b??100000: sel0 = 3'b101;
        8'b?1000000: sel0 = 3'b110;
        8'b10000000: sel0 = 3'b111;
        default: begin
            sel0 = 3'b000 ;
            sel0_valid = 0;
        end
    endcase
end

endmodule
