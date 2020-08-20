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
    Ctrl.master     ctrl_instBuffer,
    Ctrl.master     ctrl_bpd_s0,
    Ctrl.master     ctrl_bpd_s1
);

    logic delayIF3Flush, if3Flush, delayedbkdFlush;

    always_ff @ (posedge clk) delayIF3Flush <= ctrl_if3.flushReq;
    assign if3Flush = delayIF3Flush || ctrl_if3.flushReq;
    always_ff @(posedge clk) delayedbkdFlush <= backend_ctrl.flush;

    assign ctrl_if0_1_regs.pause        = ctrl_instBuffer.pauseReq || ctrl_iCache.pauseReq;
    assign ctrl_if2_3_regs.pause        = ctrl_instBuffer.pauseReq;
    assign ctrl_iCache.pause            = ctrl_instBuffer.pauseReq;
    assign ctrl_bpd_s0.pause            = ctrl_instBuffer.pauseReq || ctrl_iCache.pauseReq;
    assign ctrl_bpd_s1.pause            = ctrl_instBuffer.pauseReq;
    assign ctrl_if3.pause               = ctrl_instBuffer.pauseReq;
    assign ctrl_if3_output_regs.pause   = ctrl_instBuffer.pauseReq;

    assign ctrl_if0_1_regs.flush        = `FALSE; //backend_ctrl.flush || ctrl_if3.flushReq;
    assign ctrl_iCache.flush            = backend_ctrl.flush || ctrl_if3.flushReq;
    assign ctrl_bpd_s0.flush              = delayedbkdFlush;
    assign ctrl_bpd_s1.flush              = delayedbkdFlush;
    assign ctrl_if2_3_regs.flush        = backend_ctrl.flush || ctrl_if3.flushReq;
    assign ctrl_if3.flush               = backend_ctrl.flush;
    assign ctrl_if3_output_regs.flush   = backend_ctrl.flush;
    assign ctrl_instBuffer.flush        = backend_ctrl.flush;
endmodule
