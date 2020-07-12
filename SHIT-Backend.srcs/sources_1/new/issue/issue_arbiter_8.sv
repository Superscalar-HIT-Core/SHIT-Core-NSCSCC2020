`timescale 1ns / 1ps
// 用于发射仲裁的逻辑(队列容量8)
module issue_arbiter_8(
    input [7:0] rdys,
    output reg [2:0] sel0,
    output reg [2:0] sel1,
    output reg sel0_valid,
    output reg sel1_valid,
    output sel_valid
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

wire [7:0] rdys_1 = rdys_0 & ~(sel0_valid << sel0);
always_comb begin
    sel1_valid = 1;
    casez(rdys_1)    
        8'b???????1: sel1 = 3'b000;
        8'b??????10: sel1 = 3'b001;
        8'b?????100: sel1 = 3'b010;
        8'b????1000: sel1 = 3'b011;
        8'b???10000: sel1 = 3'b100;
        8'b??100000: sel1 = 3'b101;
        8'b?1000000: sel1 = 3'b110;
        8'b10000000: sel1 = 3'b111;
        default: begin
            sel1 = 3'b000 ;
            sel1_valid = 0;
        end
    endcase
end

assign sel_valid = sel0_valid | sel1_valid;
endmodule
