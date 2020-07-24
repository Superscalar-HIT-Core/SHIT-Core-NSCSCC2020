`timescale 1ns / 1ps
`include "defines/defines.svh"
module exception(
    input clk,
    input rst,
    CommitExce.exce exce_commit, 
    CP0Exception.exce exc_cp0,
    input [5:0] ext_interrupt
    );
    reg [5:0] ext_interrupt_signal;
    always @(posedge clk)   begin
        if(rst) begin
            ext_interrupt_signal <= 0;
        end else begin
            ext_interrupt_signal <= ext_interrupt;
        end
    end
    assign exc_cp0.interrupt = ext_interrupt_signal;
    assign exc_cp0.causeExce = exce_commit.causeExce;
    assign exc_cp0.exceType = exce_commit.exceType;
    assign exc_cp0.excePC = exce_commit.excePC;
    assign exc_cp0.isDS = exce_commit.isDS;
    assign exc_cp0.reserved = exce_commit.reserved;
    
    assign exce_commit.redirectReq = exce_commit.causeExce;
    assign exce_commit.redirectPC = ( exce_commit.exceType == ExcEret ) ? exc_cp0.EPc : 32'hBFC0_0380;
endmodule
