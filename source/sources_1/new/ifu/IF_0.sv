`timescale 1ns / 1ps
`include "../defs.sv"

module IF_0(
    IF0_Regs.if0            if0_regs
);

    assign if0_regs.inst0.pc        = if0_regs.PC;
    assign if0_regs.inst1.pc        = if0_regs.PC | 32'h0000_0004;

    assign if0_regs.inst0.valid     = ~if0_regs.PC[2];
    assign if0_regs.inst1.valid     = `TRUE;

    always_comb begin
        if0_regs.nPC           =   (if0_regs.PC & 32'hFFFF_FFF8) + 32'h0000_0008;
    end

endmodule
