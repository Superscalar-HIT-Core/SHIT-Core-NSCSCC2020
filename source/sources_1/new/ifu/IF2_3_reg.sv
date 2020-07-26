`timescale 1ns / 1ps
`include "../defs.sv"

module IF2_3_reg(
    input wire          clk,
    input wire          rst,

    Ctrl.slave          ctrl_if2_3_regs,

    ICache_Regs.regs    iCache_regs,
    Regs_IF3.regs       regs_if3
);
    logic saveOverrun;
    logic delayPause;
    logic postPause;
    InstBundle inst0;
    InstBundle inst1;

    assign ctrl_if2_3_regs.pauseReq = saveOverrun;
    always_ff @ (posedge clk) delayPause = ctrl_if2_3_regs.pause;
    assign postPause = delayPause && !ctrl_if2_3_regs.pause;

    always_ff @ (posedge clk) begin
        if(rst) begin
            regs_if3.inst0          <= 0;
            regs_if3.inst1          <= 0;
        end else if(ctrl_if2_3_regs.flush && regs_if3.rescueDS) begin
            regs_if3.inst0          <= iCache_regs.inst0;
            regs_if3.inst1          <= 0;
        end else if(ctrl_if2_3_regs.flush) begin
            regs_if3.inst0          <= 0;
            regs_if3.inst1          <= 0;
        end else if(ctrl_if2_3_regs.pause && iCache_regs.overrun && !saveOverrun) begin
            regs_if3.inst0          <= regs_if3.inst0;
            regs_if3.inst1          <= regs_if3.inst1;
            inst0                   <= iCache_regs.inst0;
            inst1                   <= iCache_regs.inst1;
        end else if(ctrl_if2_3_regs.pause) begin
            regs_if3.inst0          <= regs_if3.inst0;
            regs_if3.inst1          <= regs_if3.inst1;
        end else if(saveOverrun && postPause) begin
            regs_if3.inst0          <= inst0;
            regs_if3.inst1          <= inst1;
        end else begin
            regs_if3.inst0          <= iCache_regs.inst0;
            regs_if3.inst1          <= iCache_regs.inst1;
        end
    end
endmodule
