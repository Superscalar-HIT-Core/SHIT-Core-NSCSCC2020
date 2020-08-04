`timescale 1ns / 1ps
`include "defines/defines.svh"

module Commit(
    input wire                  clk,
    input wire                  rst,
    input [5:0]                 ext_int,
    Ctrl.slave                  ctrl_commit,
    ROB_Commit.commit           rob_commit,
    BackendRedirect.backend     backend_if0,
    BPDUpdate.backend           backend_bpd,
    NLPUpdate.backend           backend_nlp,
    CP0Exception.exce           exceInfo,
    output logic                commit_rename_valid_0,
    output logic                commit_rename_valid_1,
    output commit_info          commit_rename_req_0,
    output commit_info          commit_rename_req_1,

    output logic                fireStore,
    output logic                fireStore1
);
    logic           inst0Good;
    logic           inst1Good;
    logic           takePredFailed;
    logic           addrPredFailed;
    logic           predFailed;
    logic           waitDS;
    logic           lastWaitDs;
    logic [31:0]    target;
    logic [31:0]    lastTarget;
    logic           causeExce;
    ExceptionType   exception;
    logic [31:0]    BadVAddr;
    Word            excPC;
    logic           isDS;
    logic           inst0Store;
    logic           inst1Store;
    (* mark_debug = "yes" *) reg [5:0] ext_interrupt_signal;
    (* mark_debug = "yes" *) logic causeInt;
    (* mark_debug = "yes" *) logic           pendingInt;
    (* mark_debug = "yes" *) wire [31:0] debug_rob_pc0 = rob_commit.uOP0.pc;
    (* mark_debug = "yes" *) wire [31:0] debug_rob_pc1 = rob_commit.uOP1.pc;
    (* mark_debug = "yes" *) wire busy_pc0 = rob_commit.uOP0.busy;
    (* mark_debug = "yes" *) wire busy_pc1 = rob_commit.uOP1.busy;
    always @(posedge clk)   begin
        if(rst) begin
            ext_interrupt_signal <= 0;
        end else begin
            ext_interrupt_signal <= { exceInfo.Counter_Int, ext_int[4:0] };
        end
    end
    // Ext Interrupt
    wire [5:0] int_sig = {ext_interrupt_signal, exceInfo.Cause_IP_SW};
    wire [5:0] int_mask = {exceInfo.Status_IM, exceInfo.Status_IM_SW};
    wire [5:0] int_gen = int_sig & int_mask;

    always_ff @(posedge clk) begin
        if(rst) begin
            pendingInt <= `FALSE;
        end else if (causeInt) begin
            pendingInt <= `FALSE;
        end else if( (|int_gen)  &&   
            ( exceInfo.Status_IE == 1 ) && ( exceInfo.Status_EXL == 0 ) && 
            ( inst0Good || inst1Good ))   begin
            pendingInt <= 1'b1;
        end else begin
            pendingInt <= pendingInt;
        end
    end

    assign causeInt = pendingInt && (inst0Good || inst1Good);

    assign inst0Good        = rob_commit.valid && rob_commit.uOP0.valid && !rob_commit.uOP0.committed && !rob_commit.uOP0.busy;
    assign inst1Good        = rob_commit.valid && rob_commit.uOP1.valid && !rob_commit.uOP1.committed && !rob_commit.uOP1.busy;
    assign takePredFailed   = inst0Good && rob_commit.uOP0.branchType != typeNormal && rob_commit.uOP0.branchTaken != rob_commit.uOP0.predTaken;
    assign addrPredFailed   = inst0Good && !takePredFailed && (rob_commit.uOP0.branchAddr != rob_commit.uOP0.predAddr);
    assign target           = rob_commit.uOP0.branchTaken ? rob_commit.uOP0.branchAddr : rob_commit.uOP0.pc + 32'h8;
    assign rob_commit.ready = `TRUE;
    assign inst0Store       = inst0Good&& (
        rob_commit.uOP0.uOP == SB_U  || 
        rob_commit.uOP0.uOP == SH_U  || 
        rob_commit.uOP0.uOP == SW_U
    );
    assign inst1Store       = inst1Good&& (
        rob_commit.uOP1.uOP == SB_U  || 
        rob_commit.uOP1.uOP == SH_U  || 
        rob_commit.uOP1.uOP == SW_U
    );
    // always_comb begin
    //     if(inst0Store) begin
    //         fireStore = `TRUE;
    //     end else if(inst1Store && !causeInt && !(rob_commit.uOP0.causeExc && inst0Good)) begin
    //         fireStore = `TRUE;
    //     end else begin
    //         fireStore = `FALSE;
    //     end
    // end 
    assign fireStore  = inst0Store && !rob_commit.uOP0.causeExc;
    assign fireStore1 = inst1Store && !causeInt && !(rob_commit.uOP0.causeExc && inst0Good) && !rob_commit.uOP1.causeExc;


    always_ff @(posedge clk) begin
        if(rst || causeInt) begin
            commit_rename_valid_0 <= 0;
            commit_rename_valid_1 <= 0;
            commit_rename_req_0 <= 0;
            commit_rename_req_1 <= 0;
            waitDS              <= 0;
            lastWaitDs          <= 0;
        end else begin
            if( !predFailed && !(lastWaitDs && !waitDS) && !causeExce &&
                (takePredFailed ||   // ??????????????????????????
                (~takePredFailed && (rob_commit.uOP0.branchTaken == `TRUE) && addrPredFailed ))
            ) begin
                predFailed                      <= `TRUE;
                waitDS                          <= rob_commit.uOP1.uOP == MDBUBBLE_U;
            end else begin
                predFailed                      <= `FALSE;
                // waitDS                          <= inst1Good ? `FALSE : waitDS;
                if (inst1Good)  waitDS <= `FALSE;
                else            waitDS <= waitDS;
            end

            lastWaitDs                          <= waitDS;
            // lastTarget                          <= waitDS ? lastTarget : target;
            if(waitDS) lastTarget <= lastTarget;
            else       lastTarget <= target;

            // ???????????????????????????
            // if( causeInt )    begin
            //     causeExce <= `TRUE;
            //     exception <= ExcInterrupt;
            // end else 
            if (backend_if0.redirect) begin
                causeExce <= `FALSE;
            end else if (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid && rob_commit.uOP0.exception != ExcAddressErrIF) begin
                causeExce <= `TRUE;
                exception <= rob_commit.uOP0.exception;
                BadVAddr  <= rob_commit.uOP0.BadVAddr;
            end else if (rob_commit.uOP1.causeExc && inst1Good && rob_commit.uOP1.valid) begin
                causeExce <= `TRUE;
                exception <= rob_commit.uOP1.exception;
                BadVAddr  <= rob_commit.uOP1.BadVAddr;
            end else if (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid && rob_commit.uOP0.exception == ExcAddressErrIF) begin
                causeExce <= `TRUE;
                exception <= ExcAddressErrIF;
                BadVAddr  <= rob_commit.uOP0.branchAddr;
            end else begin
                causeExce <= `FALSE;
            end

            if(causeInt) begin
                if( inst0Good ) begin
                    excPC <= rob_commit.uOP0.pc;
                end else if (inst1Good) begin
                    excPC <= rob_commit.uOP1.pc;
                end
            end else if (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid && rob_commit.uOP0.exception != ExcAddressErrIF) begin
                excPC <= rob_commit.uOP0.pc;
            end else if (rob_commit.uOP1.causeExc && inst1Good && rob_commit.uOP1.valid) begin
                excPC <= rob_commit.uOP1.pc;
            end else if (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid && rob_commit.uOP0.exception == ExcAddressErrIF) begin
                excPC <= rob_commit.uOP0.BadVAddr;
            end else begin
                excPC <= rob_commit.uOP0.pc;
            end
            
            // isDS                                <=  (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) ? 
            //                                         rob_commit.uOP0.isDS : rob_commit.uOP1.isDS;
            isDS                                <=  rob_commit.uOP1.causeExc &&
                                                    inst1Good &&
                                                    rob_commit.uOP1.valid &&
                                                    (rob_commit.uOP1.isDS || (inst0Good && rob_commit.uOP0.branchType != typeNormal && rob_commit.uOP1.uOP == MDBUBBLE_U)) &&
                                                    !(rob_commit.uOP0.causeExc && rob_commit.uOP0.exception != ExcAddressErrIF);

            commit_rename_valid_0               <= inst0Good & ~ctrl_commit.flushReq & ~causeInt;
            commit_rename_valid_1               <= inst1Good & ~ctrl_commit.flushReq & ~causeInt;

            commit_rename_req_0.committed_arf   <= rob_commit.uOP0.dstLAddr;
            commit_rename_req_0.committed_prf   <= rob_commit.uOP0.dstPAddr;
            commit_rename_req_0.stale_prf       <= rob_commit.uOP0.dstPStale;

            commit_rename_req_1.committed_arf   <= rob_commit.uOP1.dstLAddr;
            commit_rename_req_1.committed_prf   <= rob_commit.uOP1.dstPAddr;
            commit_rename_req_1.stale_prf       <= rob_commit.uOP1.dstPStale;

            // ??????0????????????1????????
            // commit_rename_req_0.wr_reg_commit   <=  causeInt || (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid && rob_commit.uOP0.exception != ExcAddressErrIF) ? 0 : rob_commit.uOP0.dstwe;
            if (causeInt || (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid && rob_commit.uOP0.exception != ExcAddressErrIF)) begin
                commit_rename_req_0.wr_reg_commit <= 0;
            end else begin
                commit_rename_req_0.wr_reg_commit <= rob_commit.uOP0.dstwe;
            end
            
            // commit_rename_req_1.wr_reg_commit   <=  causeInt || ( (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) || 
            //                                         (rob_commit.uOP1.causeExc && inst1Good && rob_commit.uOP1.valid) ) ?  
            //                                         0 : rob_commit.uOP1.dstwe;
            if(causeInt || ((rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) || 
                            (rob_commit.uOP1.causeExc && inst1Good && rob_commit.uOP1.valid) )) begin
                commit_rename_req_1.wr_reg_commit <= 0;
            end else begin
                commit_rename_req_1.wr_reg_commit <= rob_commit.uOP1.dstwe;
            end

            backend_nlp.update.valid            <= inst0Good && rob_commit.uOP0.branchType != typeNormal;
            backend_nlp.update.pc               <= rob_commit.uOP0.pc;
            backend_nlp.update.target           <= rob_commit.uOP0.branchAddr;
            backend_nlp.update.shouldTake       <= rob_commit.uOP0.branchTaken;
            backend_nlp.update.bimState         <= rob_commit.uOP0.nlpBimState;
        end
    end

    always_comb begin
        ctrl_commit.flushReq    = `FALSE;
        backend_if0.redirect    = `FALSE;
        backend_if0.valid       = `FALSE;
        backend_if0.redirectPC  = lastTarget;
        if ( causeInt ) begin
            ctrl_commit.flushReq    = `TRUE;
            backend_if0.redirect    = `TRUE;
            backend_if0.valid       = `TRUE;
            backend_if0.redirectPC  = 32'hBFC0_0380;
        end else if ( causeExce ) begin                  // ???????????????????????????????????????????????????????????
        // TODO: ??????????????????
            ctrl_commit.flushReq    = `TRUE;
            backend_if0.redirect    = `TRUE;
            backend_if0.valid       = `TRUE;
            backend_if0.redirectPC  = ( exception == ExcEret && exceInfo.EPc[1:0] == 2'b0 ) ? exceInfo.EPc :  32'hBFC0_0380;
        end else if( (predFailed && !waitDS) || (lastWaitDs && !waitDS) ) begin
            ctrl_commit.flushReq    = `TRUE;
            backend_if0.redirect    = `TRUE;
            backend_if0.valid       = `TRUE;
            backend_if0.redirectPC  = lastTarget;
        end 
    end

    assign exceInfo.causeExce = causeExce || causeInt;
    assign exceInfo.exceType = causeInt ? ExcInterrupt : (( exception == ExcEret && exceInfo.EPc[1:0] != 2'b0 ) ? ExcAddressErrIF : exception);
    assign exceInfo.reserved = ( exception == ExcEret && exceInfo.EPc[1:0] != 2'b0 ) ? exceInfo.EPc : BadVAddr;
    always_comb begin
        exceInfo.excePC = 0;
        if (causeInt) begin
            if(inst0Good) begin
                exceInfo.excePC = rob_commit.uOP0.pc;          
            end else begin
                exceInfo.excePC = rob_commit.uOP1.pc;          
            end
        end else if ( exception == ExcEret && exceInfo.EPc[1:0] != 2'b0 ) begin
            exceInfo.excePC = exceInfo.EPc;
        end else begin
            exceInfo.excePC = excPC;
        end
    end
    // assign exceInfo.isDS = isDS;
    always_comb begin
        exceInfo.isDS = isDS;
        if(causeInt && inst0Good) begin
            exceInfo.isDS = rob_commit.uOP0.isDS;
        end else if(causeInt && inst1Good) begin
            exceInfo.isDS = rob_commit.uOP1.isDS;
        end else begin
            exceInfo.isDS = isDS;
        end
    end
    assign exceInfo.interrupt = ext_interrupt_signal;
    
    wire debug_is_branch = rob_commit.uOP0.branchType != typeNormal && inst0Good;
    wire debug_redirect = backend_if0.redirect;
endmodule
