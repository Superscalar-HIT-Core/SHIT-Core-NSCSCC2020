`timescale 1ns / 1ps
`include "../defines/defines.svh"

module IF_3(
    input wire              clk,
    input wire              rst,

    ICache_Regs.regs        iCache_regs,
    Regs_IF3.if3            regs_if3,

    IF3_Regs.if3            if3_regs,
    IF3Redirect.if3         if3_0,
    NLPUpdate.if3           if3_nlp,
    Ctrl.slave              ctrl_if3,    // only care aboud flushReq

    input wire              pred_valid, // from bpd
    input wire              pred_taken, // from bpd
    input wire [31:0]       pred_target,
    input TAGEPred          pred_info
);
    logic           inst0Jr;
    logic           inst1Jr;
    logic           inst0J;
    logic           inst1J;
    logic           inst0Br;
    logic           inst1Br;

    logic           inst0IsCtrl;
    logic           inst1IsCtrl;

    logic           inst0NLPTaken;
    logic           inst1NLPTaken;

    logic [31:0]    decodeTarget0;
    logic [31:0]    decodeTarget1;

    logic           waitDS, lastWaitDS;
    logic [31:0]    waitDSRedirectTarget;

    Predecoder pre0(
        .pc     (regs_if3.inst0.pc      ),
        .inst   (regs_if3.inst0.inst    ),
        .valid  (regs_if3.inst0.valid   ),
        .isJ    (inst0J                 ),
        .isBr   (inst0Br                ),
        .target (decodeTarget0          ),
        .jr     (inst0Jr                )
    );

    Predecoder pre1(
        .pc     (regs_if3.inst1.pc      ),
        .inst   (regs_if3.inst1.inst    ),
        .valid  (regs_if3.inst1.valid   ),
        .isJ    (inst1J                 ),
        .isBr   (inst1Br                ),
        .target (decodeTarget1          ),
        .jr     (inst1Jr                )
    );

    assign inst0NLPTaken = (regs_if3.inst0.nlpInfo.valid && regs_if3.inst0.valid && regs_if3.inst0.nlpInfo.taken) ? `TRUE : `FALSE;   // eliminate X state
    assign inst1NLPTaken = (regs_if3.inst1.nlpInfo.valid && regs_if3.inst1.valid && regs_if3.inst1.nlpInfo.taken) ? `TRUE : `FALSE;

    always_comb begin
        if3_regs.inst0          = regs_if3.inst0;
        if3_regs.inst1          = regs_if3.inst1;

        // who is the real ctrl inst?
        inst0IsCtrl             = inst0J || inst0Br;
        inst1IsCtrl             = inst1J || inst1Br;

        if3_regs.inst0.bpdInfo  = inst0IsCtrl ? pred_info : 0;
        if3_regs.inst0.isJ      = inst0J;
        if3_regs.inst0.isBr     = inst0Br;
        if3_regs.inst0.jBadAddr = (inst0J && !inst0Jr) && |decodeTarget0[1:0]; // only handle j here

        if3_regs.inst1.bpdInfo  = inst1IsCtrl ? pred_info : 0;
        if3_regs.inst1.isJ      = inst1J;
        if3_regs.inst1.isBr     = inst1Br;
        if3_regs.inst1.jBadAddr = (inst1J && !inst1Jr) && |decodeTarget1[1:0]; // only handle j here

        if(!if3_regs.inst0.valid || !inst0IsCtrl) begin                  // invalid inst
            if3_regs.inst0.predTaken    = `FALSE;
            if3_regs.inst0.predAddr     = 0;
        end else if (if3_regs.inst0.isJ) begin
            if(inst0Jr) begin
                if(pred_valid) begin
                    if3_regs.inst0.predTaken    = `TRUE;
                    if3_regs.inst0.predAddr     = pred_target;
                end else if(if3_regs.inst0.nlpInfo.valid) begin
                    if3_regs.inst0.predTaken    = `TRUE;
                    if3_regs.inst0.predAddr     = if3_regs.inst0.nlpInfo.target;
                end else begin
                    if3_regs.inst0.predTaken    = `FALSE;
                    if3_regs.inst0.predAddr     = 0;
                end
            end else begin
                if3_regs.inst0.predTaken        = `TRUE;
                if3_regs.inst0.predAddr         = decodeTarget0;
            end
        end else begin  // isBr
            if(pred_valid) begin
                if3_regs.inst0.predTaken    = pred_taken;
                if3_regs.inst0.predAddr     = decodeTarget0;
            end
        end
        
        if(!if3_regs.inst1.valid || !inst1IsCtrl) begin                  // invalid inst
            if3_regs.inst1.predTaken    = `FALSE;
            if3_regs.inst1.predAddr     = 0;
        end else if (if3_regs.inst0.isJ) begin
            if(inst1Jr) begin
                if(pred_taken) begin
                    if3_regs.inst1.predTaken    = `TRUE;
                    if3_regs.inst1.predAddr     = pred_target;
                end else if(if3_regs.inst1.nlpInfo.valid) begin
                    if3_regs.inst1.predTaken    = `TRUE;
                    if3_regs.inst1.predAddr     = if3_regs.inst1.nlpInfo.target;
                end else begin
                    if3_regs.inst1.predTaken    = `FALSE;
                    if3_regs.inst1.predAddr     = 0;
                end
            end else begin
                if3_regs.inst1.predTaken        = `TRUE;
                if3_regs.inst1.predAddr         = decodeTarget1;
            end
        end

        // redirect control
        ctrl_if3.pauseReq   = `FALSE;
        ctrl_if3.flushReq   = `FALSE;
        if3_0.redirect      = `FALSE;
        if3_0.redirectPC    = 0;
        if (rst || ctrl_if3.flush || ctrl_if3.pause) begin
            ctrl_if3.flushReq   = `FALSE;
            if3_0.redirect      = `FALSE;
            if3_0.redirectPC    = 0;
        end else if(waitDS) begin
            ctrl_if3.flushReq   = if3_regs.inst0.valid;
            if3_0.redirect      = if3_regs.inst0.valid;
            if3_0.redirectPC    = waitDSRedirectTarget;
        end else if(if3_regs.inst0.predTaken && !inst0NLPTaken) begin
            ctrl_if3.flushReq   = `TRUE;
            if3_0.redirect      = `TRUE;
            if3_0.redirectPC    = if3_regs.inst0.predAddr;
        end else if(!if3_regs.inst0.predTaken && inst0NLPTaken) begin
            ctrl_if3.flushReq   = `TRUE;
            if3_0.redirect      = `TRUE;
            if3_0.redirectPC    = if3_regs.inst0.pc + 8;
        end else if(if3_regs.inst0.predTaken && inst0NLPTaken && if3_regs.inst0.predAddr != if3_regs.inst0.nlpInfo.target) begin
            ctrl_if3.flushReq   = `TRUE;
            if3_0.redirect      = `TRUE;
            if3_0.redirectPC    = if3_regs.inst0.predAddr;
        end else begin
            ctrl_if3.pauseReq   = `FALSE;
            ctrl_if3.flushReq   = `FALSE;
            if3_0.redirect      = `FALSE;
            if3_0.redirectPC    = 0;
        end

        if(waitDS || lastWaitDS) begin
            if3_regs.inst1.valid = `FALSE;
        end
    end

    // wait ds handle
    always_ff @ (posedge clk) begin
        if(rst || ctrl_if3.flush) begin
            waitDSRedirectTarget <= 0;
        end else if(if3_regs.inst1.predTaken && inst1NLPTaken && if3_regs.inst0.predAddr != if3_regs.inst0.nlpInfo.target) begin
            waitDSRedirectTarget <= if3_regs.inst1.predAddr;
        end else if(if3_regs.inst1.predTaken && !inst1NLPTaken) begin
            waitDSRedirectTarget <= if3_regs.inst1.predAddr;
        end else if(!if3_regs.inst1.predTaken && inst1NLPTaken) begin
            waitDSRedirectTarget <= if3_regs.inst1.pc + 8;
        end

        if(rst || ctrl_if3.flush) begin
            lastWaitDS           <= `FALSE;
        end else begin
            lastWaitDS           <= waitDS;
        end
        
        if (rst || ctrl_if3.flush) begin
            waitDS              <= `FALSE;
        end else if (ctrl_if3.pause) begin
            waitDS              <= waitDS;
        end else if (waitDS) begin
            waitDS              <= ~if3_regs.inst0.valid;
        end else if(if3_regs.inst0.predTaken && !inst0NLPTaken) begin
            waitDS              <= `FALSE;
        end else if(!if3_regs.inst0.predTaken && inst0NLPTaken) begin
            waitDS              <= `FALSE;
        end else if(if3_regs.inst1.predTaken && inst1NLPTaken && if3_regs.inst0.predAddr != if3_regs.inst0.nlpInfo.target) begin
            waitDS              <= `TRUE;
        end else if(if3_regs.inst1.predTaken && !inst1NLPTaken) begin
            waitDS              <= `TRUE;
        end else if(!if3_regs.inst1.predTaken && inst1NLPTaken) begin
            waitDS              <= inst1J || inst1Br;
        end else begin
            waitDS              <= `FALSE;
        end
    end

    // nlp update info
    always_comb begin
        if3_nlp.update = 0;
        if(if3_regs.inst0.valid && (if3_regs.inst0.bpdInfo.valid || (if3_regs.inst0.isJ && (!inst0Jr || (inst0Jr && if3_regs.inst0.nlpInfo.valid))))) begin
            if3_nlp.update.pc          = if3_regs.inst0.pc;
            if3_nlp.update.target      = if3_regs.inst0.predAddr;
            if3_nlp.update.bimState    = if3_regs.inst0.nlpInfo.valid ? if3_regs.inst0.nlpInfo.bimState : 2'b01;
            if3_nlp.update.shouldTake  = if3_regs.inst0.predTaken;
            if3_nlp.update.valid       = `TRUE;
        end else if(if3_regs.inst1.valid && (if3_regs.inst1.bpdInfo.valid || (if3_regs.inst1.isJ && (!inst1Jr || (inst1Jr && if3_regs.inst1.nlpInfo.valid))))) begin
            if3_nlp.update.pc          = if3_regs.inst1.pc;
            if3_nlp.update.target      = if3_regs.inst1.predAddr;
            if3_nlp.update.bimState    = if3_regs.inst1.nlpInfo.valid ? if3_regs.inst1.nlpInfo.bimState : 2'b01;
            if3_nlp.update.shouldTake  = if3_regs.inst1.predTaken;
            if3_nlp.update.valid       = `TRUE;
        end else begin
            if3_nlp.update.valid       = `FALSE;
        end
    end
endmodule