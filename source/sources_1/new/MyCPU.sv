`timescale 1ns / 1ps

module MyCPU(
    input clk,
    input rst,

    output wire rsta_busy               ,
    output wire rstb_busy               ,

    output wire         s_aclk          ,
    output wire         s_aresetn       ,
    output wire [ 3:0]  s_axi_awid      ,
    output wire [31:0]  s_axi_awaddr    ,
    output wire [ 7:0]  s_axi_awlen     ,
    output wire [ 2:0]  s_axi_awsize    ,
    output wire [ 1:0]  s_axi_awburst   ,
    output wire         s_axi_awvalid   ,
    input  wire         s_axi_awready   ,
    output wire [31:0]  s_axi_wdata     ,
    output wire [ 3:0]  s_axi_wstrb     ,
    output wire         s_axi_wlast     ,
    output wire         s_axi_wvalid    ,
    input  wire         s_axi_wready    ,
    input  wire [ 3:0]  s_axi_bid       ,
    input  wire [ 1:0]  s_axi_bresp     ,
    input  wire         s_axi_bvalid    ,
    output wire         s_axi_bready    ,
    output wire [ 3:0]  s_axi_arid      ,
    output wire [31:0]  s_axi_araddr    ,
    output wire [ 7:0]  s_axi_arlen     ,
    output wire [ 2:0]  s_axi_arsize    ,
    output wire [ 1:0]  s_axi_arburst   ,
    output wire         s_axi_arvalid   ,
    input  wire         s_axi_arready   ,
    input  wire [ 3:0]  s_axi_rid       ,
    input  wire [31:0]  s_axi_rdata     ,
    input  wire [ 1:0]  s_axi_rresp     ,
    input  wire         s_axi_rlast     ,
    input  wire         s_axi_rvalid    ,
    output wire         s_axi_rready   
);
    
    AXIReadAddr         axiReadAddr();
    AXIReadData         axiReadData();
    AXIWriteAddr        axiWriteAddr();
    AXIWriteData        axiWriteData();
    AXIWriteResp        axiWriteResp();

    InstReq             instReq();
    InstResp            instResp();
    DataReq             dataReq();
    DataResp            dataResp();
    DCacheReq           dCacheReq();
    DCacheResp          dCacheResp();
    
    Ctrl                ctrl_if0_1_regs();
    Ctrl                ctrl_if2_3_regs();
    Ctrl                ctrl_iCache();
    Ctrl                ctrl_if3();
    Ctrl                ctrl_if3_output_regs();
    Ctrl                ctrl_instBuffer();
    Ctrl                ctrl_nlp();

    BackendRedirect     backend_if0();
    BPDUpdate           backend_bpd();
    NLPUpdate           backend_nlp();

    ICache_TLB          iCache_tlb();
    
    IFU_InstBuffer      ifu_instBuffer();
    InstBuffer_Backend  instBuffer_backend();

    CtrlUnit        cu(.*);
    AXIInterface    axiInterface(.*);
    AXIWarp         axiWarp(.*);
    IFU             ifu(.*);
    InstBuffer      instBuffer(.*);
endmodule
