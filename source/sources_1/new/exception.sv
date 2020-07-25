`timescale 1ns / 1ps
`include "defines/defines.svh"
module exception(
    input clk,
    input rst,
    CommitExce.exce exce_commit, 
    CP0Exception.exce exceInfo,
    input [5:0] ext_int
    );
    reg [5:0] ext_interrupt_signal;
    always @(posedge clk)   begin
        if(rst) begin
            ext_interrupt_signal <= 0;
        end else begin
            ext_interrupt_signal <= { exceInfo.Counter_Int, ext_int[4:0] };
        end
    end
    // 触发硬件中断
    always_comb begin
        if( | ({ext_interrupt_signal, exceInfo.Cause_IP_SW} & {exceInfo.Status_IM, exceInfo.Status_IM_SW}) &&   
            ( exceInfo.Status_IE == 1 ) && ( exceInfo.Status_EXL = 0 ) )   begin
            exceInfo.causeExce = 1'b1;
            exceInfo.exceType = ExcInterrupt;
        end else begin
            exceInfo.causeExce = exce_commit.causeExce;
            exceInfo.exceType = exce_commit.exceType;
        end
    end
    assign exceInfo.interrupt = ext_interrupt_signal;
    assign exceInfo.excePC = exce_commit.excePC;
    assign exceInfo.isDS = exce_commit.isDS;
    assign exceInfo.reserved = exce_commit.reserved;
    
    assign exce_commit.redirectReq = exce_commit.causeExce;
    assign exce_commit.redirectPC = ( exce_commit.exceType == ExcEret ) ? exceInfo.EPc : 32'hBFC0_0380;
endmodule
