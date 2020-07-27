`timescale 1ns / 1ps

`ifndef DEFSSV
`define DEFSSV

`define TRUE            1'b1
`define FALSE           1'b0
// `define WORD            31:0

`define IB_SIZE         16
`define IB_ADDR         3:0
`define NLP_SIZE        512
// `define NLP_ADDR        9:0
`define NLP_PC          10:2

typedef struct packed {
    logic   [31:0]  target;
    logic   [1:0]   bimState;
    logic           taken;
    logic           valid;
} NLPPredInfo;

typedef struct packed {
    logic   [31:0]  pc;
    logic   [31:0]  target;
    logic   [1:0]   bimState;
    logic           shouldTake;
    logic           valid;
} NLPUpdateInfo;

typedef struct packed {
    // logic   [31:0]  target;
    logic           taken;
    logic           valid;
} BPDPredInfo;

typedef struct packed {
    // logic   [31:0]  target;
    logic           taken;
    logic           valid;
} BPDUpdateInfo;

typedef struct packed {
    logic   [31:0]  inst;
    logic   [31:0]  pc;
    logic           isBr;
    logic           isDs;
    logic           isJ;
    logic           valid;
    NLPPredInfo     nlpInfo;
    BPDPredInfo     bpdInfo;
    logic           predTaken;
    logic   [31:0]  predAddr;
    logic           jBadAddr;
} InstBundle;

`endif
