`timescale 1ns / 1ps
`include "defs.sv"

interface AXIReadAddr;
    logic        valid;
    logic        ready;

    logic [ 3:0] id;
    logic [31:0] address;
    logic [ 3:0] length;
    logic [ 2:0] size;
    logic [ 1:0] burst;
    logic [ 1:0] lock;
    logic [ 3:0] cache;
    logic [ 2:0] protect;

    modport master(output valid, id, address, length, size, burst, lock, cache, protect, input ready);
    modport slave(input valid, id, address, length, size, burst, lock, cache, protect, output ready);
endinterface : AXIReadAddr //AXIReadAddr

interface AXIReadData;
    logic        valid;
    logic        ready;

    logic [ 3:0] id;
    logic [31:0] data;
    logic [ 1:0] respond;
    logic        last;
    modport master(output ready, input valid, id, data, respond, last);
    modport slave(input ready, output valid, id, data, respond, last);
endinterface //AXIReadData

interface AXIWriteAddr;
    logic        valid;
    logic        ready;

    logic [ 3:0] id;
    logic [31:0] address;
    logic [ 3:0] length;
    logic [ 2:0] size;
    logic [ 1:0] burst;
    logic [ 1:0] lock;
    logic [ 3:0] cache;
    logic [ 2:0] protect;

    modport master(output valid, id, address, length, size, burst, lock, cache, protect, input ready);
    modport slave(input valid, id, address, length, size, burst, lock, cache, protect, output ready);
endinterface //AXIWriteAddr

interface AXIWriteData;
    logic        valid;
    logic        ready;

    logic [ 3:0] id;
    logic [31:0] data;
    logic [ 3:0] strobe;
    logic        last;

    modport master(output valid, id, data, strobe, last, input ready);
    modport slave(input valid, id, data, strobe, last, output ready);
endinterface //AXIWriteData

interface AXIWriteResp;
    logic        valid;
    logic        ready;

    logic [ 3:0] id;
    logic [ 1:0] respond;

    modport master(output ready, input valid, id, respond);
    modport slave(input ready, output valid, id, respond);
endinterface //AXIWriteResp

interface InstReq;
    logic        valid;
    logic        ready;

    logic [31:0] pc;

    modport axi(output ready, input valid, pc);
    modport iCache(input ready, output valid, pc);
    
    task automatic sendReq(logic [31:0] ad, ref logic clk);
        @(posedge clk) #1 begin
            valid     =   `TRUE;
            pc        =   ad;
        end
        do @(posedge clk);
        while (!ready);
        #1
        valid   =   `FALSE;
    endtask //automatic
endinterface //InstReq

interface InstResp;
    logic        valid;
    logic        ready;

    logic[127:0] cacheLine;

    modport axi(output valid, cacheLine, input ready);
    modport iCache(input valid, cacheLine, output ready);

    task automatic getResp(ref logic clk);
        @(posedge clk) #1 begin
            ready       =   `TRUE;
        end
        do @(posedge clk);
        while (!valid);
        #1
        ready   =   `FALSE;
    endtask //automatic

endinterface //InstResp

interface DataReq;
    logic        valid;
    logic        ready;

    logic [31:0] addr;
    logic        write_en;
    logic [31:0] data;
    logic [3 :0] strobe;
    logic [2 :0] size;

    modport axi(output ready, input valid, addr, write_en, data, strobe, size);
    modport lsu(input ready, output valid, addr, write_en, data, strobe, size);

    task automatic sendWReq(logic [31:0] ad, logic [31:0] dat, ref logic clk);
        @(posedge clk) #1 begin
            valid       =   `TRUE;
            addr        =   ad;
            write_en    =   `TRUE;
            strobe      =   4'b1111;
            data        =   dat;
        end
        do @(posedge clk);
        while (!ready);
        #1
        valid   =   `FALSE;
    endtask //automatic

    task automatic sendRReq(logic [31:0] ad, ref logic clk);
        @(posedge clk) #1 begin
            valid       =   `TRUE;
            addr        =   ad;
            write_en    =   `FALSE;
            strobe      =   4'b1111;
        end
        do @(posedge clk);
        while (!ready);
        #1
        valid   =   `FALSE;
    endtask //automatic

endinterface //DataReq

interface DataResp;
    logic        valid;
    logic        ready;

    logic[31:0]  data;

    modport axi(output valid, data, input ready);
    modport lsu(input valid, data, output ready);
    
    task automatic getResp(ref logic clk);
        @(posedge clk) #1 begin
            ready       =   `TRUE;
        end
        do @(posedge clk);
        while (!valid);
        #1
        ready   =   `FALSE;
    endtask //automatic
endinterface //DataResp

interface DCacheReq;
    logic           valid;
    logic           ready;

    logic [ 31:0]   addr;
    logic           write_en;
    logic [127:0]   data;

    modport axi(output ready, input valid, addr, write_en, data);
    modport dCache(input ready, output valid, addr, write_en, data);

    task automatic sendWReq(logic [31:0] ad, logic [127:0] dat, ref logic clk);
        @(posedge clk) #1 begin
            valid       =   `TRUE;
            addr        =   ad;
            write_en    =   `TRUE;
            data        =   dat;
        end
        do @(posedge clk);
        while (!ready);
        #1
        valid   =   `FALSE;
    endtask //automatic

    task automatic sendRReq(logic [31:0] ad, ref logic clk);
        @(posedge clk) #1 begin
            valid       =   `TRUE;
            addr        =   ad;
            write_en    =   `FALSE;
        end
        do @(posedge clk);
        while (!ready);
        #1
        valid   =   `FALSE;
    endtask //automatic
endinterface //DCacheReq

interface DCacheResp;
    logic           valid;
    logic           ready;

    logic [127:0]   data;

    modport axi(output valid, data, input ready);
    modport dCache(input valid, data, output ready);
    
    task automatic getResp(ref logic clk);
        @(posedge clk) #1 begin
            ready       =   `TRUE;
        end
        do @(posedge clk);
        while (!valid);
        #1
        ready   =   `FALSE;
    endtask //automatic
endinterface //DCacheResp

interface IF0_Regs;
    logic   [31:0]  nPC;
    logic   [31:0]  PC;

    InstBundle      inst0;
    InstBundle      inst1;

    modport if0(input PC, output nPC, inst0, inst1);
    modport regs(output PC, input nPC, inst0, inst1);

    task automatic setPC(logic [31:0] addr, ref logic clk);
        @(posedge clk) #1 nPC = addr;
    endtask //automatic

endinterface //IF0_1
/*
interface Regs_IF1;
    logic   [31:0]  PC;

    modport regs(output PC);
    modport if1(input PC);
endinterface //Reg_IF1*/

interface Regs_NLP;
    logic   [31:0]  PC;

    modport regs(output PC);
    modport nlp(input PC);
endinterface //Regs_NLP

interface Regs_BPD;
    logic   [31:0]  PC;

    modport regs(output PC);
    modport bpd(input PC);
endinterface //Regs_BPD

interface Regs_ICache;
    logic   [31:0]  PC;
    logic           onlyGetDS;

    InstBundle      inst0;
    InstBundle      inst1;

    modport regs(output PC, inst0, inst1, onlyGetDS);
    modport iCache(input PC, inst0, inst1, onlyGetDS);

    task automatic sendPC(logic [31:0] addr, ref logic clk);
        @(posedge clk) #1 PC = addr;
    endtask //automatic
endinterface //Regs_ICache

interface ICache_TLB;
    logic   [31:0]  virAddr0;
    logic   [31:0]  virAddr1;
    logic   [31:0]  phyAddr0;
    logic   [31:0]  phyAddr1;

    modport iCache(output virAddr0, virAddr1, input phyAddr0, phyAddr1);
    modport tlb(input virAddr0, virAddr1, output phyAddr0, phyAddr1);
    
    task automatic autoReply(ref logic clk);
        @ (posedge clk) begin
            // phyAddr0 = virAddr0;
            // phyAddr1 = virAddr1;
            if(virAddr0 > 32'hC0000000 || virAddr0 < 32'h3FFFFFFF) begin
                phyAddr0 = #1 virAddr0;
            end else if (virAddr0 > 32'h9fff_ffff) begin
                phyAddr0 = #1 virAddr0 - 32'h9FFF_FFFF;
            end else begin
                phyAddr0 = #1 virAddr0 - 32'h7FFF_FFFF;
            end
            if(virAddr1 > 32'hC0000000 || virAddr1 < 32'h3FFFFFFF) begin
                phyAddr1 = #1 virAddr1;
            end else if (virAddr1 > 32'h9fff_ffff) begin
                phyAddr1 = #1 virAddr1 - 32'h9FFF_FFFF;
            end else begin
                phyAddr1 = #1 virAddr1 - 32'h7FFF_FFFF;
            end
        end
    endtask //automatic

endinterface //Regs_BPD

interface ICache_Regs;
    InstBundle  inst0;
    InstBundle  inst1;
    logic       overrun;

    modport iCache(output inst0, inst1, overrun);
    modport regs(input inst0, inst1, overrun);
endinterface //ICache_Regs

interface NLPUpdate;
    NLPUpdateInfo   update;

    modport if3(output update);
    modport nlp(input update);
    modport backend(output update);
endinterface

interface Regs_IF3;
    InstBundle  inst0;
    InstBundle  inst1;
    logic       rescueDS;
    modport regs(output inst0, inst1, input rescueDS);
    modport if3(input inst0, inst1, output rescueDS);
endinterface //Regs_IF3

interface IF3_Regs;
    InstBundle inst0;
    InstBundle inst1;
    modport regs(input inst0, inst1);
    modport if3(output inst0, inst1);
endinterface //Regs_IF3

interface BPDUpdate;
    BPDUpdateInfo   update;
    logic           updValid;

    modport backend(output update, updValid);
    modport bpd(input update, updValid);
endinterface

interface NLP_IF0;
    NLPPredInfo nlpInfo0;
    NLPPredInfo nlpInfo1;

    modport if0(input nlpInfo0, nlpInfo1);
    modport nlp(output nlpInfo0, nlpInfo1);
endinterface //IF0_NLP

interface BPD_IF3;
    BPDPredInfo     bpdInfo0;
    BPDPredInfo     bpdInfo1;
    BPDUpdateInfo   update0;
    BPDUpdateInfo   update1;

    modport bpd(output bpdInfo0, bpdInfo1, input update0, update1);
    modport if3(input bpdInfo0, bpdInfo1, output update0, update1);
endinterface

interface IF3Redirect;
    logic           redirect;
    logic   [31:0]  redirectPC;

    modport if0(input redirect, redirectPC);
    modport if3(output redirect, redirectPC);
endinterface //IF3_0

interface BackendRedirect;
    logic           redirect;
    logic   [31:0]  redirectPC;

    logic           ready;
    logic           valid;

    modport if0(input redirect, redirectPC, valid, output ready);
    modport backend(output redirect, redirectPC, valid, output ready);

    task automatic redirectReq(logic [31:0] addr, ref logic clk);
        @(posedge clk) #1 begin
            valid       =   `TRUE;
            redirectPC  =   addr;
            redirect    =   `TRUE;
        end
        do @(posedge clk);
        while (!ready);
        #1
        valid   =   `FALSE;
    endtask //automatic
endinterface //BackendRedirect

// interface Ctrl;
//     logic           pauseReq;
//     logic           flushReq;
//     logic           pause;
//     logic           flush;

//     modport master(input pauseReq, flushReq, output pause, flush);
//     modport slave(output pauseReq, flushReq, input pause, flush);
// endinterface //Ctrl

interface IFU_InstBuffer;
    InstBundle      inst0;
    InstBundle      inst1;

    modport ifu(output inst0, inst1);
    modport instBuffer(input inst0, inst1);
endinterface //IFU_InstBuffer

// interface InstBuffer_Backend;
//     InstBundle      inst0;
//     InstBundle      inst1;
//     logic           valid;
//     logic           ready;
//     logic           flushReq;

//     modport instBuffer(output inst0, inst1, valid, input ready, flushReq);
//     modport backend(input inst0, inst1, output ready, flushReq);
    
//     task automatic getResp(ref logic clk);
//         ready       =   `TRUE;
//         flushReq    =   `FALSE;
//         do @(posedge clk);
//         while (!valid);
//         $display("get pc: %h, %h", inst0.valid ? inst0.pc : 32'bX, inst1.valid ? inst1.pc : 32'bX);
//         #1
//         ready   =   `FALSE;
//     endtask //automatic
// endinterface //IFU_InstBuffer

// package defs;
//     typedef enum logic {False, True} bool;
// endpackage
