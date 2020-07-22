`timescale 1ns / 1ps

`include "../defines/defines.svh"

module Issue_RF_regs(
    input   wire        clk,
    input   wire        rst,

    Ctrl.slave          ctrl_issue_rf_regs,

    input   UOPBundle   issueBundle,
    input   wire        primPauseReq,
    output  UOPBundle   rfBundle,
    output  PRFrNums    prfRequest
);

    always_ff @ (posedge clk) begin
        if(rst || ctrl_issue_rf_regs.flush) begin
            rfBundle        <= 0;
            prfRequest      <= 0;
        end else if(primPauseReq || ctrl_issue_rf_regs.pause) begin
            rfBundle        <= rfBundle;
            prfRequest      <= prfRequest;
        end else begin
            rfBundle        <= issueBundle;
            prfRequest.rs0  <= issueBundle.op0PAddr;
            prfRequest.rs1  <= issueBundle.op1PAddr;
        end
    end

endmodule
