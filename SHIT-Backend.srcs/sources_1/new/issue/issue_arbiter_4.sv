`timescale 1ns / 1ps
// 用于发射仲裁的逻辑（队列容量4）
module issue_arbiter_4(
    input [3:0] rdys,
    output reg [1:0] sel0,
    output reg [1:0] sel1,
    output reg sel0_valid,
    output reg sel1_valid,
    output sel_valid
    );

wire [3:0] rdys_0 = rdys;
always_comb begin
    sel0_valid = 1;
    casez(rdys_0)    
        4'b???1: sel0 = 2'b00;
        4'b??10: sel0 = 2'b01;
        4'b?100: sel0 = 2'b10;
        4'b1000: sel0 = 2'b11;
        default: begin
            sel0 = 2'b00 ;
            sel0_valid = 0;
        end
    endcase
end

wire [3:0] rdys_1 = rdys_0 & ~(sel0_valid << sel0);
always_comb begin
    sel1_valid = 1;
    casez(rdys_1)    
        4'b???1: sel0 = 2'b00;
        4'b??10: sel0 = 2'b01;
        4'b?100: sel0 = 2'b10;
        4'b1000: sel0 = 2'b11;
        default: begin
            sel1 = 2'b00 ;
            sel1_valid = 0;
        end
    endcase
end

assign sel_valid = sel0_valid | sel1_valid;
endmodule