`timescale 1ns / 1ps
`include "defines/defines.svh"

module Commit(
    input wire                  clk,
    input wire                  rst,

    Ctrl.slave                  ctrl_commit,
    ROB_Commit.commit           rob_commit,
    BackendRedirect.backend     backend_if0,
    BPDUpdate.backend           backend_bpd,
    NLPUpdate.backend           backend_nlp,

    output logic                commit_rename_valid_0,
    output logic                commit_rename_valid_1,
    output commit_info          commit_rename_req_0,
    output commit_info          commit_rename_req_1,

    output logic                fireStore
);

    logic           inst0Good;
    logic           inst1Good;
    logic           takePredFailed;
    logic           addrPredFailed;
    logic           predFailed;
    logic           waitDS;
    logic           lastWaitDs;
    logic [31:0]    target;
    logic [31:0]    lastTarget;
    logic           causeExec;
    ExceptionType   exception;
    logic [19:0]    excCode;
    logic           inst0Store;
    logic           inst1Store;

    assign inst0Good        = rob_commit.valid && rob_commit.uOP0.valid && !rob_commit.uOP0.committed && !rob_commit.uOP0.busy;
    assign inst1Good        = rob_commit.valid && rob_commit.uOP0.valid && !rob_commit.uOP0.committed && !rob_commit.uOP0.busy;
    assign takePredFailed   = inst0Good && rob_commit.uOP0.branchType != typeNormal && rob_commit.uOP0.branchTaken != rob_commit.uOP0.predTaken;
    assign addrPredFailed   = inst0Good && !takePredFailed && (rob_commit.uOP0.branchAddr != rob_commit.uOP0.predAddr);
    assign target           = rob_commit.uOP0.branchTaken ? rob_commit.uOP0.branchAddr : rob_commit.uOP0.pc + 32'h8;
    assign rob_commit.ready = `TRUE;
    assign inst0Store       = inst0Good&& (
        rob_commit.uOP0.uOP == SB_U  || 
        rob_commit.uOP0.uOP == SH_U  || 
        rob_commit.uOP0.uOP == SW_U
    );
    assign inst1Store       = inst1Good&& (
        rob_commit.uOP1.uOP == SB_U  || 
        rob_commit.uOP1.uOP == SH_U  || 
        rob_commit.uOP1.uOP == SW_U
    );
    assign fireStore        = inst0Store || inst1Store;

    always_ff @(posedge clk) begin
        if(rst) begin
            commit_rename_valid_0 <= 0;
            commit_rename_valid_1 <= 0;
            commit_rename_req_0 <= 0;
            commit_rename_req_1 <= 0;
        end else begin
            if( takePredFailed ||   // 只有预测跳转的时候，才需要检查地址
                (~takePredFailed && (rob_commit.uOP0.branchTaken == `TRUE) && addrPredFailed ) ) begin
                predFailed                      <= `TRUE;
                waitDS                          <= rob_commit.uOP1.uOP == MDBUBBLE_U;
            end else begin
                predFailed                      <= `FALSE;
                waitDS                          <= inst1Good ? `FALSE : waitDS;
            end

            lastWaitDs                          <= waitDS;
            lastTarget                          <= waitDS ? lastTarget : target;
            causeExec                           <= (rob_commit.uOP0.causeExc && inst0Good) || (rob_commit.uOP1.causeExc && inst1Good);
            exception                           <= rob_commit.uOP1.causeExc ? rob_commit.uOP1.exception : rob_commit.uOP0.exception;
            excCode                             <= rob_commit.uOP1.causeExc ? rob_commit.uOP1.excCode : rob_commit.uOP0.excCode;
            
            commit_rename_valid_0               <= inst0Good;
            commit_rename_valid_1               <= inst1Good;

            commit_rename_req_0.committed_arf   <= rob_commit.uOP0.dstLAddr;
            commit_rename_req_0.committed_prf   <= rob_commit.uOP0.dstPAddr;
            commit_rename_req_0.stale_prf       <= rob_commit.uOP0.dstPStale;

            commit_rename_req_1.committed_arf   <= rob_commit.uOP1.dstLAddr;
            commit_rename_req_1.committed_prf   <= rob_commit.uOP1.dstPAddr;
            commit_rename_req_1.stale_prf       <= rob_commit.uOP1.dstPStale;

            commit_rename_req_0.wr_reg_commit   <= rob_commit.uOP0.dstwe;
            commit_rename_req_1.wr_reg_commit   <= rob_commit.uOP1.dstwe;

            backend_nlp.update.valid            <= inst0Good && rob_commit.uOP0.branchType != typeNormal;
            backend_nlp.update.pc               <= rob_commit.uOP0.pc;
            backend_nlp.update.target           <= rob_commit.uOP0.branchAddr;
            backend_nlp.update.shouldTake       <= rob_commit.uOP0.branchTaken;
            backend_nlp.update.bimState         <= rob_commit.uOP0.nlpBimState;
        end
    end

    always_comb begin
        if( (predFailed && !waitDS) || (lastWaitDs && !waitDS) ) begin
            ctrl_commit.flushReq    = `TRUE;
            backend_if0.redirect    = `TRUE;
            backend_if0.valid       = `TRUE;
            backend_if0.redirectPC  = lastTarget;
        end else begin
            ctrl_commit.flushReq    = `FALSE;
            backend_if0.redirect    = `FALSE;
            backend_if0.valid       = `FALSE;
            backend_if0.redirectPC  = 32'h0;
        end
        // TODO: Exception handle if exception xxxxxx, 
    end

endmodule
