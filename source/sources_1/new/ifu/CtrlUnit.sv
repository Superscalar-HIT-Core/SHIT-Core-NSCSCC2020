`timescale 1ns / 1ps
`include "../defs.sv"

module CtrlUnit(
    input wire      clk,
    Ctrl.slave      backend_ctrl,

    Ctrl.master     ctrl_if0_1_regs,
    Ctrl.master     ctrl_if2_3_regs,
    Ctrl.master     ctrl_iCache,
    Ctrl.master     ctrl_if3,
    Ctrl.master     ctrl_if3_output_regs,
    Ctrl.master     ctrl_instBuffer
);

    logic delayIBPause, ibPause;

    always_ff @ (posedge clk) delayIBPause <= ctrl_instBuffer.pauseReq;
    assign ibPause = delayIBPause || ctrl_instBuffer.pauseReq;


    assign ctrl_if0_1_regs.pause        = ibPause ||ctrl_iCache.pauseReq;
    assign ctrl_if2_3_regs.pause        = ibPause;
    assign ctrl_iCache.pause            = ibPause;
    assign ctrl_if3.pause               = ibPause;
    assign ctrl_if3_output_regs.pause   = ibPause;

    assign ctrl_if0_1_regs.flush        = `FALSE; //backend_ctrl.flush || ctrl_if3.flushReq;
    assign ctrl_iCache.flush            = backend_ctrl.flush || ctrl_if3.flushReq;
    assign ctrl_if2_3_regs.flush        = backend_ctrl.flush || ctrl_if3.flushReq;
    assign ctrl_if3_output_regs.flush   = backend_ctrl.flush;
    assign ctrl_instBuffer.flush        = backend_ctrl.flush;
endmodule
