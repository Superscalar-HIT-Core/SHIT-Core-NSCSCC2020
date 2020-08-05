`timescale 1ns / 1ps
`include "../defs.sv"
`include "../defines/defines.svh"

module RAS(
    input                   clk,
    input                   rst,
    input                   pause,
    input                   recover,
    input   logic           valid,
    input   logic           isLink,
    input   logic           isReturn,
    output  logic [31:0]    target
    input   logic           commit_valid,
    input   logic           committed_isLink,
    input   logic           committed_isReturn,
    input   logic [31:0]    committed_pc
);

    reg [31:0] ras [15:0];  // 16 Depth ras
    reg [3:0] ras_top, committed_ras_top;
    always @(posedge clk)   begin
        if(rst) begin
            for(integer i=0;i<16;i++)   begin
                ras[i] <= 0;
            end
            ras_top <= 0;
        end else if(recover)    begin
            for(integer i=0;i<16;i++)   begin
                ras[i] <= committed_ras[i];
            end
            ras_top <= committed_ras_top;
        end else if(isLink && ~pause)    begin
            ras[ras_top] <= pc + 32'h8;
            ras_top <= ras_top + 1;
        end else if(isReturn && ~pause)  begin
            ras_top <= ras_top - 1;
        end
    end

    assign target = ras[ras_top];
    
    reg [31:0] committed_ras [15:0];  // 16 Depth ras(committed)

    always @(posedge clk)   begin
        if(rst) begin
            for(integer i=0;i<16;i++)   begin
                committed_ras[i] <= 0;
            end
            committed_ras_top <= 0;
        end else if(commit_valid && committed_isLink)    begin
            committed_ras[committed_ras_top] <= pc + 32'h8;
            committed_ras_top <= committed_ras_top + 1;
        end else if(commit_valid && committed_isReturn)  begin
            committed_ras_top <= committed_ras_top - 1;
        end
    end

    
endmodule
