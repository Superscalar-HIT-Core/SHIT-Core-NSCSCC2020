`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/09 18:41:29
// Design Name: 
// Module Name: IF_3
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
`include "../defs.sv"

module IF_3(
    Regs_IF3.if3            regs_if3,
    BPD_IF3.if3             bpd_if3,

    IF3_Regs.if3            if3_regs,
    IF3Redirect.if3         if3_0,
    NLPUpdate.if3           if3_nlp,
    Ctrl.slave              ctrl_if3    // only care aboud flushReq
);
    logic       inst0Jr;
    logic       inst1Jr;

    logic       inst0NLPTaken;
    logic       inst1NLPTaken;

    InstBundle  inst0;
    InstBundle  inst1;

    Predecoder pre0(
        .pc     (regs_if3.inst0.pc      ),
        .inst   (regs_if3.inst0.inst    ),
        .valid  (regs_if3.inst0.valid   ),
        .isJ    (if3_regs.inst0.isJ     ),
        .isBr   (if3_regs.inst0.isBr    ),
        .target (if3_regs.inst0.target  ),
        .jr     (inst0Jr                )
    );

    Predecoder pre1(
        .pc     (regs_if3.inst1.pc      ),
        .inst   (regs_if3.inst1.inst    ),
        .valid  (regs_if3.inst1.valid   ),
        .isJ    (if3_regs.inst1.isJ     ),
        .isBr   (if3_regs.inst1.isBr    ),
        .target (if3_regs.inst1.target  ),
        .jr     (inst1Jr                )
    );

    assign inst0 = if3_regs.inst0;
    assign inst1 = if3_regs.inst1;

    assign inst0NLPTaken = (inst0.nlpInfo.valid && inst0.nlpInfo.taken) ? `TRUE : `FALSE;   // eliminate X state
    assign inst1NLPTaken = (inst1.nlpInfo.valid && inst1.nlpInfo.taken) ? `TRUE : `FALSE;

    assign inst0.predTaken  = inst0.taken && !(inst0Jr && !inst0.nlpInfo.valid);
    assign inst0.predAddr   = inst0Jr ? inst0.nlpInfo.target : inst0.target;

    assign inst1.predTaken  = inst1.taken && !(inst1Jr && !inst1.nlpInfo.valid);
    assign inst1.predAddr   = inst1Jr ? inst1.nlpInfo.target : inst1.target;

    always_comb begin
        if3_regs.inst0.pc       = regs_if3.inst0.pc;
        if3_regs.inst0.inst     = regs_if3.inst0.inst;
        if3_regs.inst0.valid    = regs_if3.inst0.valid;
        if3_regs.inst0.nlpInfo  = regs_if3.inst0.nlpInfo;
        if3_regs.inst0.bpdInfo  = bpd_if3.bpdInfo0;
        
        if3_regs.inst1.pc       = regs_if3.inst1.pc;
        if3_regs.inst1.inst     = regs_if3.inst1.inst;
        if3_regs.inst1.valid    = regs_if3.inst1.valid;
        if3_regs.inst1.nlpInfo  = regs_if3.inst1.nlpInfo;
        if3_regs.inst1.bpdInfo  = bpd_if3.bpdInfo1;

        if(!inst0.valid) begin                  // invalid inst
            inst0.taken = `FALSE;
        end else if(inst0.isJ) begin            // unconditional
            inst0.taken = `TRUE;
        end else if(!inst0.isBr) begin          // normal
            inst0.taken = `FALSE;
        end else if(inst0.bpdInfo.valid) begin  // predict by bpd
            inst0.taken = inst0.bpdInfo.taken;
        end else if(inst0.nlpInfo.valid) begin  // predict by nlp
            inst0.taken = inst0.nlpInfo.taken;
        end else begin                          // both miss
            inst0.taken = `FALSE;
        end

        if(!inst1.valid) begin                  // invalid inst
            inst1.taken = `FALSE;
        end else if(inst1.isJ) begin            // unconditional
            inst1.taken = `TRUE;
        end else if(!inst1.isBr) begin          // normal
            inst1.taken = `FALSE;
        end else if(inst1.bpdInfo.valid) begin  // predict by bpd
            inst1.taken = inst1.bpdInfo.taken;
        end else if(inst1.nlpInfo.valid) begin  // predict by nlp
            inst1.taken = inst1.nlpInfo.taken;
        end else begin                          // both miss
            inst1.taken = `FALSE;
        end

        if(inst0.predTaken && !inst0NLPTaken) begin
            if3_0.redirect      = `TRUE;
            if3_0.redirectPC    = inst0.predAddr;
            ctrl_if3.flushReq   = `TRUE;
            regs_if3.rescueDS   = `FALSE;
        end else if(!inst0.predTaken && inst0NLPTaken) begin
            if3_0.redirect      = `TRUE;
            if3_0.redirectPC    = inst0.pc + 8;
            ctrl_if3.flushReq   = `TRUE;
            regs_if3.rescueDS   = `FALSE;
        end else if(inst1.predTaken && !inst1NLPTaken) begin
            if3_0.redirect      = `TRUE;
            if3_0.redirectPC    = inst1.predAddr;
            ctrl_if3.flushReq   = `TRUE;
            regs_if3.rescueDS   = `TRUE;
        end else if(!inst1.predTaken && inst1NLPTaken) begin
            if3_0.redirect      = `TRUE;
            if3_0.redirectPC    = inst1.pc + 8;
            ctrl_if3.flushReq   = `TRUE;
            regs_if3.rescueDS   = `TRUE;
        end else begin
            if3_0.redirect      = `FALSE;
            ctrl_if3.flushReq   = `FALSE;
            regs_if3.rescueDS   = `FALSE;
        end
    end

    always_comb begin
        if(inst0.bpdInfo.valid || (inst0.isJ && (!inst0Jr || (inst0Jr && inst0.nlpInfo.valid)))) begin
            if3_nlp.update0.target      = inst0.predAddr;
            if3_nlp.update0.bimState    = inst0.nlpInfo.valid ? inst0.nlpInfo.bimState : 2'b01;
            if3_nlp.update0.shouldTake  = inst0.predTaken;
            if3_nlp.update0.valid       = `TRUE;
        end else begin
            if3_nlp.update0.valid       = `FALSE;
        end
    end

    always_comb begin
        if(inst1.bpdInfo.valid || (inst1.isJ && (!inst1Jr || (inst1Jr && inst1.nlpInfo.valid)))) begin
            if3_nlp.update1.target      = inst1.predAddr;
            if3_nlp.update1.bimState    = inst1.nlpInfo.valid ? inst1.nlpInfo.bimState : 2'b01;
            if3_nlp.update1.shouldTake  = inst1.predTaken;
            if3_nlp.update1.valid       = `TRUE;
        end else begin
            if3_nlp.update1.valid       = `FALSE;
        end
    end

endmodule
