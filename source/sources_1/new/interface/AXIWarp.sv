`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/08 03:42:39
// Design Name: 
// Module Name: AXIWarp
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


module AXIWarp(
    input clk,
    input rst,

    AXIReadAddr.slave  axiReadAddr,
    AXIReadData.slave  axiReadData,
    AXIWriteAddr.slave axiWriteAddr,
    AXIWriteData.slave axiWriteData,
    AXIWriteResp.slave axiWriteResp,

    output wire rsta_busy    ,      // dont care
    output wire rstb_busy    ,      // dont care
    
    output wire         s_aclk         ,
    output wire         s_aresetn      ,

    output wire [ 3:0]  s_axi_awid     ,
    output wire [31:0]  s_axi_awaddr   ,
    output wire [ 7:0]  s_axi_awlen    ,
    output wire [ 2:0]  s_axi_awsize   ,
    output wire [ 1:0]  s_axi_awburst  ,
    output wire         s_axi_awvalid  ,
    input  wire         s_axi_awready  ,

    output wire [31:0]  s_axi_wdata    ,
    output wire [ 3:0]  s_axi_wstrb    ,
    output wire         s_axi_wlast    ,
    output wire         s_axi_wvalid   ,
    input  wire         s_axi_wready   ,

    input  wire [ 3:0]  s_axi_bid      ,
    input  wire [ 1:0]  s_axi_bresp    ,
    input  wire         s_axi_bvalid   ,
    output wire         s_axi_bready   ,

    output wire [ 3:0]  s_axi_arid     ,
    output wire [31:0]  s_axi_araddr   ,
    output wire [ 7:0]  s_axi_arlen    ,
    output wire [ 2:0]  s_axi_arsize   ,
    output wire [ 1:0]  s_axi_arburst  ,
    output wire         s_axi_arvalid  ,
    input  wire         s_axi_arready  ,

    input  wire [ 3:0]  s_axi_rid      ,
    input  wire [31:0]  s_axi_rdata    ,
    input  wire [ 1:0]  s_axi_rresp    ,
    input  wire         s_axi_rlast    ,
    input  wire         s_axi_rvalid   ,
    output wire         s_axi_rready   
    );

    assign s_aclk           = clk;
    assign s_aresetn        = ~rst;

    assign s_axi_awid       = axiWriteAddr.id;
    assign s_axi_awaddr     = axiWriteAddr.address;
    assign s_axi_awlen[3:0] = axiWriteAddr.length;
    assign s_axi_awlen[7:4] = 4'h0;
    assign s_axi_awsize     = axiWriteAddr.size;
    assign s_axi_awburst    = axiWriteAddr.burst;
    assign s_axi_awvalid    = axiWriteAddr.valid;
    
    assign axiWriteAddr.ready   = s_axi_awready;

    assign s_axi_wdata      = axiWriteData.data;
    assign s_axi_wstrb      = axiWriteData.strobe;
    assign s_axi_wlast      = axiWriteData.last;
    assign s_axi_wvalid     = axiWriteData.valid;

    assign axiWriteData.ready   = s_axi_wready;

    assign axiWriteResp.id      = s_axi_bid    ;
    assign axiWriteResp.respond = s_axi_bresp  ;
    assign s_axi_bready     = axiWriteResp.ready;
    
    assign axiWriteResp.valid = s_axi_bvalid;

    assign s_axi_arid       = axiReadAddr.id;
    assign s_axi_araddr     = axiReadAddr.address;
    assign s_axi_arlen[3:0] = axiReadAddr.length;
    assign s_axi_arlen[7:4] = 4'h0;
    assign s_axi_arsize     = axiReadAddr.size;
    assign s_axi_arburst    = axiReadAddr.burst;
    assign s_axi_arvalid    = axiReadAddr.valid;

    assign axiReadAddr.ready    = s_axi_arready;

    assign axiReadData.id       = s_axi_rid     ;
    assign axiReadData.data     = s_axi_rdata   ;
    assign axiReadData.respond  = s_axi_rresp   ;
    assign axiReadData.last     = s_axi_rlast   ;
    assign s_axi_rready  =  axiReadData.ready;
    
    assign axiReadData.valid    = s_axi_rvalid;

endmodule
