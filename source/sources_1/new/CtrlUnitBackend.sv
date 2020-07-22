`timescale 1ns / 1ps
`include "defines/defines.svh"

module CtrlUnitBackend(
    Ctrl.master     backend_ctrl,

    Ctrl.master     ctrl_instBuffer_decode_regs,
    Ctrl.master     ctrl_decode_rename_regs,
    Ctrl.master     ctrl_rob,
    Ctrl.master     ctrl_issue_alu0_regs,
    Ctrl.master     ctrl_issue_alu1_regs,
    Ctrl.master     ctrl_issue_mdu_regs,
    Ctrl.master     ctrl_issue_lsu_regs,
    Ctrl.master     ctrl_rf_alu0_regs,
    Ctrl.master     ctrl_rf_alu1_regs,
    Ctrl.master     ctrl_rf_mdu_regs,
    Ctrl.master     ctrl_rf_lsu_regs,
    Ctrl.master     ctrl_alu0_output_regs,
    Ctrl.master     ctrl_alu1_output_regs,
    Ctrl.master     ctrl_mdu_output_regs,
    Ctrl.master     ctrl_lsu_output_regs,
    Ctrl.master     ctrl_commit,

    input wire           aluIQReady,
    input wire           lsuIQReady,
    input wire           mduIQReady,
    input wire           renameAllocatable,

    output wire           renameRecover,
    output wire           aluIQFlush,
    output wire           lsuIQFlush,
    output wire           mduIQFlush,

    output wire           pauseRename,
    output wire           pauseRename_dispatch_reg
);

    assign ctrl_instBuffer_decode_regs.pause =
        ctrl_rob.pauseReq                   ||
        ctrl_decode_rename_regs.pauseReq    ||
        !aluIQReady                         ||
        !lsuIQReady                         ||
        !mduIQReady                         ||
        !renameAllocatable;

    assign ctrl_decode_rename_regs.pause =
        ctrl_rob.pauseReq                   ||
        !aluIQReady                         ||
        !lsuIQReady                         ||
        !mduIQReady                         ||
        !renameAllocatable;

    assign pauseRename =
        ctrl_rob.pauseReq                   ||
        !aluIQReady                         ||
        !lsuIQReady                         ||
        !mduIQReady;

    assign pauseRename_dispatch_reg =
        ctrl_rob.pauseReq                   ||
        !aluIQReady                         ||
        !lsuIQReady                         ||
        !mduIQReady;
    
    assign  ctrl_instBuffer_decode_regs.flush   = ctrl_commit.flushReq;
    assign  ctrl_decode_rename_regs.flush       = ctrl_commit.flushReq;
    assign  ctrl_rob.flush                      = ctrl_commit.flushReq;
    assign  ctrl_issue_alu0_regs.flush          = ctrl_commit.flushReq;
    assign  ctrl_issue_alu1_regs.flush          = ctrl_commit.flushReq;
    assign  ctrl_issue_lsu_regs.flush           = ctrl_commit.flushReq;
    assign  ctrl_issue_mdu_regs.flush           = ctrl_commit.flushReq;
    assign  ctrl_rf_alu0_regs.flush             = ctrl_commit.flushReq;
    assign  ctrl_rf_alu1_regs.flush             = ctrl_commit.flushReq;
    assign  ctrl_rf_mdu_regs.flush              = ctrl_commit.flushReq;
    assign  ctrl_rf_lsu_regs.flush              = ctrl_commit.flushReq;
    assign  ctrl_alu0_output_regs.flush         = ctrl_commit.flushReq;
    assign  ctrl_alu1_output_regs.flush         = ctrl_commit.flushReq;
    assign  ctrl_mdu_output_regs.flush          = ctrl_commit.flushReq;
    assign  ctrl_lsu_output_regs.flush          = ctrl_commit.flushReq;
    assign  renameRecover                       = ctrl_commit.flushReq;
    assign  aluIQFlush                          = ctrl_commit.flushReq;
    assign  lsuIQFlush                          = ctrl_commit.flushReq;
    assign  mduIQFlush                          = ctrl_commit.flushReq;
    assign  backend_ctrl.flush                  = ctrl_commit.flushReq;
    assign  backend_ctrl.pause                  = `FALSE;

endmodule