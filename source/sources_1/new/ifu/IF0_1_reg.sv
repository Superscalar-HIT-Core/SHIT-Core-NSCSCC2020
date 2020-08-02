`timescale 1ns / 1ps
`include "../defs.sv"

module IF0_1_reg(
    input wire clk,
    input wire rst,

    Ctrl.slave          ctrl_if0_1_regs,
    
    IF0_Regs.regs       if0_regs,

    Regs_NLP.regs       regs_nlp,
    Regs_BPD.regs       regs_bpd,
    Regs_ICache.regs    regs_iCache,

    NLP_IF0.if0         nlp_if0,
    IF3Redirect.if0     if3_0,
    BackendRedirect.if0 backend_if0
);

    logic           headIsDS;
    logic [31:0]    dsAddr;
    (* mark_debug = "yes" *)logic [31:0]    PC;

    assign if0_regs.PC      = PC;
    assign regs_nlp.PC      = PC;
    assign regs_bpd.PC      = PC;
    assign regs_iCache.PC   = PC;
    
    assign regs_iCache.inst0.nlpInfo    = nlp_if0.nlpInfo0;
    assign regs_iCache.inst1.nlpInfo    = nlp_if0.nlpInfo1;
    assign regs_iCache.inst0.pc         = PC & 32'hffff_fffc;
    assign regs_iCache.inst1.pc         = PC | 32'h0000_0004;

    assign ctrl_if0_1_regs.pauseReq     = `FALSE;

    assign backend_if0.ready = `TRUE;

    assign regs_iCache.onlyGetDS = headIsDS;

    always_ff @ (posedge clk) begin
        if(rst) begin
            PC          <=  32'hbfc00000;
            // PC          <=  32'hbfc17300;
            headIsDS    <=  `FALSE;
        end else if(backend_if0.redirect && backend_if0.valid) begin
            PC          <=  backend_if0.redirectPC;
            headIsDS    <=  `FALSE;
        end else if(if3_0.redirect) begin
            PC          <=  if3_0.redirectPC;
            headIsDS    <=  `FALSE;
        end else if(ctrl_if0_1_regs.pause) begin
            PC          <=  PC;
            headIsDS    <=  headIsDS;
            dsAddr      <=  dsAddr;
        end else if(headIsDS) begin
            PC          <=  dsAddr;
            headIsDS    <=  `FALSE;
        end else if(nlp_if0.nlpInfo0.valid && nlp_if0.nlpInfo0.taken && !PC[2]) begin
            PC          <=  nlp_if0.nlpInfo0.target;
            headIsDS    <=  `FALSE;
        end else if(nlp_if0.nlpInfo1.valid && nlp_if0.nlpInfo1.taken) begin
            PC          <=  if0_regs.nPC;
            headIsDS    <=  `TRUE;
            dsAddr      <=  nlp_if0.nlpInfo1.target;
        end else begin
            PC          <=  if0_regs.nPC;
            headIsDS    <=  `FALSE;
        end
    end

    // synopsys translate_off
    // always_ff @ (posedge clk) begin
    //     $display("pc: %h", PC);
    //     if(rst || ctrl_if0_1_regs.flush) begin
    //         $display("rst");
    //     end else if(backend_if0.redirect && backend_if0.valid) begin
    //         $display("backend redirect");
    //     end else if(if3_0.redirect) begin
    //         $display("if3 redirect");
    //     end else if(headIsDS) begin
    //         $display("delayed nlp redirect");
    //     end else if(nlp_if0.nlpInfo0.valid && nlp_if0.nlpInfo0.taken) begin
    //         $display("nlp0 redirect");
    //     end else if(nlp_if0.nlpInfo1.valid && nlp_if0.nlpInfo1.taken) begin
    //         $display("nlp1 delayed redirect");
    //     end else if(ctrl_if0_1_regs.pause) begin
    //         $display("pause");
    //     end else begin
    //         $display("npc");
    //     end
    // end
    // synopsys translate_on

endmodule
