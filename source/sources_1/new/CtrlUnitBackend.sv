`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/18 15:00:50
// Design Name: 
// Module Name: CtrlUnitBackend
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


module CtrlUnitBackend(
    Ctrl.master     ctrl_instBuffer_decode_regs,
    Ctrl.master     ctrl_decode_rename_regs,
    Ctrl.master     ctrl_rob,
    Ctrl.master     ctrl_iq_alu0,
    Ctrl.master     ctrl_iq_alu1,
    Ctrl.master     ctrl_iq_lsu,
    Ctrl.master     ctrl_iq_mdu,
    Ctrl.master     ctrl_commit
);

    assign ctrl_instBuffer_decode_regs.pause =
        ctrl_decode_rename_regs.pauseReq    ||
        ctrl_rob.pauseReq                   ||
        ctrl_iq_alu0.pauseReq               ||
        ctrl_iq_alu1.pauseReq               ||
        ctrl_iq_lsu.pauseReq                ||
        ctrl_iq_mdu.pauseReq;

    assign ctrl_decode_rename_regs.pause =
        ctrl_rob.pauseReq                   ||
        ctrl_iq_alu0.pauseReq               ||
        ctrl_iq_alu1.pauseReq               ||
        ctrl_iq_lsu.pauseReq                ||
        ctrl_iq_mdu.pauseReq;
    
    assign  ctrl_instBuffer_decode_regs.flush   = ctrl_commit.flushReq;
    assign  ctrl_rob.flush                      = ctrl_commit.flushReq;
    assign  ctrl_iq_alu0.flush                  = ctrl_commit.flushReq;
    assign  ctrl_iq_alu1.flush                  = ctrl_commit.flushReq;
    assign  ctrl_iq_lsu.flush                   = ctrl_commit.flushReq;
    assign  ctrl_iq_mdu.flush                   = ctrl_commit.flushReq;

endmodule