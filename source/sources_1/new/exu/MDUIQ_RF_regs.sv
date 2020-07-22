`timescale 1ns / 1ps
`include "../defines/defines.svh"

module MDUIQ_RF_regs(
    input   wire        clk,
    input   wire        rst,

    Ctrl.slave          ctrl_issue_mdu_regs,

    input   UOPBundle   issueBundleHi,
    input   UOPBundle   issueBundleLo,
    input   wire        primPauseReq,

    output  UOPBundle   rfBundleHi,
    output  UOPBundle   rfBundleLo,
    output  PRFrNums    prfRequest,

    output logic        mulBusy,
    output logic        divBusy
);

    logic [31:0]    mulTimeLine, nxtMulTimeLine;
    logic [31:0]    divTimeLine, nxtDivTimeLine;
    
    assign mulBusy      = mulTimeLine[0];
    assign divBusy      = divTimeLine[0];
    

    always_comb begin
        if(!mulBusy && (issueBundleHi.uOP == MULTHI_U || issueBundleHi.uOP == MULTUHI_U) && issueBundleHi.valid) begin
            nxtMulTimeLine = (mulTimeLine >> 1) | 32'b00000000_00000000_00000000_00000001;
            nxtDivTimeLine = (divTimeLine >> 1);
        end else if(!divBusy && (issueBundleHi.uOP ==  DIVHI_U || issueBundleHi.uOP ==  DIVUHI_U) && issueBundleHi.valid) begin
            nxtMulTimeLine = (mulTimeLine >> 1) | 32'b00000000_00000000_01110000_00000000;
            nxtDivTimeLine = (divTimeLine >> 1) | 32'b00000000_00000000_00000000_00000001;
        end else begin
            nxtMulTimeLine = (mulTimeLine >> 1);
            nxtDivTimeLine = (divTimeLine >> 1);
        end
    end

    always_ff @ (posedge clk) begin
        if(rst || ctrl_issue_mdu_regs.flush) begin
            rfBundleHi          <= 0;
            rfBundleLo          <= 0;
            prfRequest          <= 0;
            mulTimeLine         <= 32'h0;
            divTimeLine         <= 32'h0;
        end else if(primPauseReq || ctrl_issue_mdu_regs.pause) begin
            rfBundleHi          <= rfBundleHi;
            rfBundleLo          <= rfBundleLo;
            prfRequest          <= prfRequest;
            mulTimeLine         <= mulTimeLine;
            divTimeLine         <= divTimeLine;
        end else begin
            rfBundleHi          <= issueBundleHi;
            rfBundleLo          <= issueBundleLo;
            prfRequest.rs0      <= issueBundleHi.op0PAddr;
            prfRequest.rs1      <= issueBundleHi.op1PAddr;
            mulTimeLine         <= nxtMulTimeLine;
            divTimeLine         <= nxtDivTimeLine;
        end
    end

endmodule