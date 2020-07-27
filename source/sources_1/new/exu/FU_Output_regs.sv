`timescale 1ns / 1ps

`include "../defines/defines.svh"

module FU_Output_regs(
    input  wire     clk,
    input  wire     rst,

    Ctrl.slave      ctrl_fu_output_regs,

    input  PRFwInfo fuWbData,
    FU_ROB.rob      fuCommitInfo,

    output PRFwInfo prfWReq,
    FU_ROB.fu       commitInfo
);

    always_ff @ (posedge clk) begin
        if(rst || ctrl_fu_output_regs.flush) begin
            prfWReq                     <= 0;
            commitInfo.setFinish        <= 0;
            commitInfo.id               <= 0;
            commitInfo.setBranchStatus  <= 0;
            commitInfo.branchTaken      <= 0;
            commitInfo.branchAddr       <= 0;
        end else begin  // no pause
            prfWReq                     <= fuWbData;
            commitInfo.setFinish        <= fuCommitInfo.setFinish;
            commitInfo.id               <= fuCommitInfo.id;
            commitInfo.setBranchStatus  <= fuCommitInfo.setBranchStatus;
            commitInfo.branchTaken      <= fuCommitInfo.branchTaken;
            commitInfo.branchAddr       <= fuCommitInfo.branchAddr;
            commitInfo.setException     <= fuCommitInfo.setException;
            commitInfo.exceptionType    <= fuCommitInfo.exceptionType;
            commitInfo.BadVAddr         <= fuCommitInfo.BadVAddr;
        end
    end

endmodule
