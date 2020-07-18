`timescale 1ns / 1ps
`include "../defs.sv"

module IFU(
    input wire          clk,
    input wire          rst,

    InstReq             instReq,
    InstResp            instResp,
    
    Ctrl                ctrl_if0_1_regs,
    Ctrl                ctrl_if2_3_regs,
    Ctrl                ctrl_iCache,
    Ctrl                ctrl_if3,
    Ctrl                ctrl_if3_output_regs,
    Ctrl                ctrl_nlp,

    ICache_TLB          iCache_tlb,
    BackendRedirect     backend_if0,
    BPDUpdate           backend_bpd,
    NLPUpdate           backend_nlp,

    IFU_InstBuffer      ifu_instBuffer
);
    
    NLP_IF0             nlp_if0();
    IF3Redirect         if3_0();
    IF0_Regs            if0_regs();

    //Regs_IF1            regs_if1();
    Regs_NLP            regs_nlp();
    Regs_BPD            regs_bpd();
    Regs_ICache         regs_iCache();

    ICache_Regs         iCache_regs();

    Regs_IF3            regs_if3();
    BPD_IF3             bpd_if3();

    IF3_Regs            if3_regs();
    NLPUpdate           if3_nlp();
    
    IF_0            if0(.*);
    IF0_1_reg       if01reg(.*);
    NLP             nlp(.*);
    BPD             bpd(.*);
    ICache          iCache(.*);
    IF2_3_reg       if23reg(.*);
    IF_3            if3(.*);
    IF3_Output_reg  if3OutputReg(.*);
    
endmodule