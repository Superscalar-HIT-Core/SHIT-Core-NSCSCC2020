`timescale 1ns / 1ps

`include "../defines/defines.svh"

module RF_MDU_regs(
    input  wire         clk,
    input  wire         rst,
    
    Ctrl.slave          ctrl_rf_fu_regs,
    input  wire         primPauseReq,

    input  UOPBundle    rfBundleHi,
    input  UOPBundle    rfBundleLo,
    input  PRFrData     rfRes,

    output UOPBundle    fuBundleHi,
    output UOPBundle    fuBundleLo,
    output PRFrData     fuOprands
);

    always_ff @ (posedge clk) begin
        if(rst || ctrl_rf_fu_regs.flush) begin
            fuBundleHi          <= 0;
            fuBundleLo          <= 0;
            fuOprands           <= 0;
        end else if(primPauseReq || ctrl_rf_fu_regs.pause) begin
            fuBundleHi          <= fuBundleHi;
            fuBundleLo          <= fuBundleLo;
            fuOprands           <= fuOprands;
        end else begin
            fuBundleHi          <= rfBundleHi;
            fuBundleLo          <= rfBundleLo;
            fuOprands           <= rfRes;
        end
    end

endmodule
