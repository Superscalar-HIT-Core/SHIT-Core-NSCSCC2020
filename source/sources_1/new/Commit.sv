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

    output logic                fireStore
);
    reg [5:0] ext_interrupt_signal;
    logic causeInt;
    always @(posedge clk)   begin
        if(rst) begin
            ext_interrupt_signal <= 0;
        end else begin
            ext_interrupt_signal <= { exceInfo.Counter_Int, ext_int[4:0] };
        end
    end
    // Ext Interrupt
    always_comb begin
        if( | ({ext_interrupt_signal, exceInfo.Cause_IP_SW} & {exceInfo.Status_IM, exceInfo.Status_IM_SW}) &&   
            ( exceInfo.Status_IE == 1 ) && ( exceInfo.Status_EXL = 0 ) )   begin
            causeInt = 1'b1;
        end else begin
            causeInt = 1'b0;
        end
    end

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
    logic [19:0]    BadVAddr;
    Word            excPC;
    logic           isDS;
    logic           inst0Store;
    logic           inst1Store;

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
    assign fireStore        = inst0Store || inst1Store;

    always_ff @(posedge clk) begin
        if(rst) begin
            commit_rename_valid_0 <= 0;
            commit_rename_valid_1 <= 0;
            commit_rename_req_0 <= 0;
            commit_rename_req_1 <= 0;
            waitDS              <= 0;
            lastWaitDs          <= 0;
        end else begin
            if( !predFailed && !(lastWaitDs && !waitDS) && !causeExce &&
                (takePredFailed ||   // 只有预测跳转的时候，才需要检查地址
                (~takePredFailed && (rob_commit.uOP0.branchTaken == `TRUE) && addrPredFailed ))
            ) begin
                predFailed                      <= `TRUE;
                waitDS                          <= rob_commit.uOP1.uOP == MDBUBBLE_U;
            end else begin
                predFailed                      <= `FALSE;
                waitDS                          <= inst1Good ? `FALSE : waitDS;
            end

            lastWaitDs                          <= waitDS;
            lastTarget                          <= waitDS ? lastTarget : target;

            // 在有外部中断的情况下，所有的都被清了
            causeExce                           <=  causeInt ? ExcInterrupt : 
                                                    (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) || 
                                                    (rob_commit.uOP1.causeExc && inst1Good && rob_commit.uOP1.valid) ;
            exception                           <=  causeInt || (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) ? 
                                                    rob_commit.uOP0.exception : rob_commit.uOP0.exception;
            BadVAddr                             <=  causeInt || (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) ? 
                                                    rob_commit.uOP0.BadVAddr : rob_commit.uOP1.BadVAddr;
            excPC                               <=  causeInt || (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) ? 
                                                    rob_commit.uOP0.pc : rob_commit.uOP1.pc;
            isDS                                <=  causeInt || (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) ? 
                                                    rob_commit.uOP0.isDS : rob_commit.uOP1.isDS;

            commit_rename_valid_0               <= inst0Good & ~ctrl_commit.flushReq;
            commit_rename_valid_1               <= inst1Good & ~ctrl_commit.flushReq;

            commit_rename_req_0.committed_arf   <= rob_commit.uOP0.dstLAddr;
            commit_rename_req_0.committed_prf   <= rob_commit.uOP0.dstPAddr;
            commit_rename_req_0.stale_prf       <= rob_commit.uOP0.dstPStale;

            commit_rename_req_1.committed_arf   <= rob_commit.uOP1.dstLAddr;
            commit_rename_req_1.committed_prf   <= rob_commit.uOP1.dstPAddr;
            commit_rename_req_1.stale_prf       <= rob_commit.uOP1.dstPStale;

            // 如果指令0造成异常，则指令1也不能提交
            commit_rename_req_0.wr_reg_commit   <=  causeInt || (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) ? 0 : rob_commit.uOP0.dstwe;
            commit_rename_req_1.wr_reg_commit   <=  causeInt || ( (rob_commit.uOP0.causeExc && inst0Good && rob_commit.uOP0.valid) || 
                                                    (rob_commit.uOP1.causeExc && inst1Good && rob_commit.uOP1.valid) ) ?  
                                                    0 : rob_commit.uOP1.dstwe;

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
        if ( causeExce ) begin                  // 如果分支指令引发了异常，那么先处理异常，再重新做分支指令，其延迟槽也不能被提交
        // TODO: 如果延迟槽引发了异常呢？
            ctrl_commit.flushReq    = `TRUE;
            backend_if0.redirect    = `TRUE;
            backend_if0.valid       = `TRUE;
            backend_if0.redirectPC  = ( exception == ExcEret ) ? exceInfo.EPc : 32'hBFC0_0380;;
        end else if( (predFailed && !waitDS) || (lastWaitDs && !waitDS) ) begin
            ctrl_commit.flushReq    = `TRUE;
            backend_if0.redirect    = `TRUE;
            backend_if0.valid       = `TRUE;
            backend_if0.redirectPC  = lastTarget;
        end 
    end

    assign exceInfo.causeExce = causeExce;
    assign exceInfo.exceType = exception;
    assign exceInfo.reserved = BadVAddr;
    assign exceInfo.excePC = excPC;
    assign exceInfo.isDS = isDS;
    assign exceInfo.interrupt = ext_interrupt_signal;

endmodule
