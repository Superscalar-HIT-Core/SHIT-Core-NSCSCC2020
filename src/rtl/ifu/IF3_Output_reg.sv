`timescale 1ns / 1ps
`include "../defs.sv"

module IF3_Output_reg(
    input wire          clk,
    input wire          rst,

    IF3_Regs.regs       if3_regs,
    IFU_InstBuffer.ifu  ifu_instBuffer,
    Ctrl.slave          ctrl_if3_output_regs
);
    always_ff @ (posedge clk) begin
        if(ctrl_if3_output_regs.flush || rst) begin
            ifu_instBuffer.inst0.valid  <= `FALSE;
            ifu_instBuffer.inst1.valid  <= `FALSE;
        end else if(ctrl_if3_output_regs.pause) begin
            ifu_instBuffer.inst0        <= ifu_instBuffer.inst0;
            ifu_instBuffer.inst1        <= ifu_instBuffer.inst1;
        end else begin
            ifu_instBuffer.inst0        <= if3_regs.inst0;
            ifu_instBuffer.inst1        <= if3_regs.inst1;
        end
    end

endmodule
