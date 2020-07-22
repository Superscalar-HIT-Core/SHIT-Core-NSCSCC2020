`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/22 02:27:18
// Design Name: 
// Module Name: Commit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines/defines.svh"

module Commit(
    input wire                  clk,
    input wire                  rst,

    Ctrl.slave                  ctrl_commit,
    ROB_Commit.commit           rob_commit,
    BackendRedirect.backend     backend_if0,
    BPDUpdate.backend           backend_bpd,
    NLPUpdate.backend           backend_nlp
);

    logic           takePredFailed;
    logic           addrPredFailed;
    logic           predFailed;
    logic           waitDS;
    logic           lastWaitDs;
    logic [31:0]    target;
    logic [31:0]    lastTarget;

    assign takePredFailed   = rob_commit.uOP0.branchType != typeNormal && rob_commit.uOP0.branchTaken != rob_commit.uOP0.predTaken;
    assign addrPredFailed   = !takePredFailed && rob_commit.uOP0.branchAddr != rob_commit.uOP0.predAddr;
    assign target           = rob_commit.uOP0.branchTaken ? rob_commit.uOP0.branchAddr : rob_commit.uOP0.pc + 32'h8;

    always_ff @(posedge clk) begin
        if(takePredFailed || addrPredFailed) begin
            predFailed  <= `TRUE;
            waitDS      <= rob_commit.uOP1.uOP == MDBUBBLE_U;
        end else begin
            predFailed  <= `FALSE;
            waitDS      <= `FALSE;
        end
        lastWaitDs      <= waitDS;
        lastTarget      <= target;
    end

    always_comb begin
        if((predFailed && !waitDS) || lastWaitDs) begin
            ctrl_commit.flushReq    = `TRUE;
            backend_if0.redirect    = `TRUE;
            backend_if0.valid       = `TRUE;
            backend_if0.redirectPC  = target;
        end else begin
            ctrl_commit.flushReq    = `FALSE;
            backend_if0.redirect    = `FALSE;
            backend_if0.valid       = `FALSE;
            backend_if0.redirectPC  = 32'h0;
        end
    end

endmodule
