`timescale 1ns / 1ps
`include "../defs.sv"

module BPD(
    BPD_IF3.bpd         bpd_if3,
    BPDUpdate.bpd       backend_bpd
);
// fake BPD for now

    assign bpd_if3.bpdInfo0.valid = `FALSE;
    assign bpd_if3.bpdInfo1.valid = `FALSE;

    // npc >|PC|> input, bpd0 >|reg|> bpd1 >|reg|> bpd2, output
    // if0           if1              if2              if3

endmodule
