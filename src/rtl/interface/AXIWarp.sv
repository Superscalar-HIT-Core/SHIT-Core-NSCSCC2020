`timescale 1ns / 1ps

module AXIWarp(
    AXIReadAddr.slave  axiReadAddr,
    AXIReadData.slave  axiReadData,
    AXIWriteAddr.slave axiWriteAddr,
    AXIWriteData.slave axiWriteData,
    AXIWriteResp.slave axiWriteResp,

    output wire [ 3:0]  awid      ,
    output wire [31:0]  awaddr    ,
    output wire [ 3:0]  awlen     ,
    output wire [ 2:0]  awsize    ,
    output wire [ 1:0]  awburst   ,
    output wire [ 1:0]  awlock    ,
    output wire [ 3:0]  awcache   ,
    output wire [ 2:0]  awprot    ,
    output wire         awvalid   ,
    input  wire         awready   ,

    output wire [ 3:0]  wid       ,
    output wire [31:0]  wdata     ,
    output wire [ 3:0]  wstrb     ,
    output wire         wlast     ,
    output wire         wvalid    ,
    input  wire         wready    ,

    input  wire [ 3:0]  bid       ,
    input  wire [ 1:0]  bresp     ,
    input  wire         bvalid    ,
    output wire         bready    ,

    output wire [ 3:0]  arid      ,
    output wire [31:0]  araddr    ,
    output wire [ 3:0]  arlen     ,
    output wire [ 2:0]  arsize    ,
    output wire [ 1:0]  arburst   ,
    output wire [ 1:0]  arlock    ,
    output wire [ 3:0]  arcache   ,
    output wire [ 2:0]  arprot    ,
    output wire         arvalid   ,
    input  wire         arready   ,

    input  wire [ 3:0]  rid       ,
    input  wire [31:0]  rdata     ,
    input  wire [ 1:0]  rresp     ,
    input  wire         rlast     ,
    input  wire         rvalid    ,
    output wire         rready    
    );

    assign awid       = axiWriteAddr.id;
    assign awaddr     = axiWriteAddr.address;
    assign awlen      = axiWriteAddr.length;
    assign awsize     = axiWriteAddr.size;
    assign awburst    = axiWriteAddr.burst;
    assign awlock     = axiWriteAddr.lock;
    assign awcache    = axiWriteAddr.cache;
    assign awprot     = axiWriteAddr.protect;
    assign awburst    = axiWriteAddr.burst;
    assign awvalid    = axiWriteAddr.valid;
    
    assign axiWriteAddr.ready   = awready;

    assign wdata      = axiWriteData.data;
    assign wstrb      = axiWriteData.strobe;
    assign wlast      = axiWriteData.last;
    assign wvalid     = axiWriteData.valid;

    assign axiWriteData.ready   = wready;

    assign axiWriteResp.id      = bid    ;
    assign axiWriteResp.respond = bresp  ;
    assign bready     = axiWriteResp.ready;
    
    assign axiWriteResp.valid = bvalid;

    assign arid       = axiReadAddr.id;
    assign araddr     = axiReadAddr.address;
    assign arlen[3:0] = axiReadAddr.length;
    assign arsize     = axiReadAddr.size;
    assign arburst    = axiReadAddr.burst;
    assign arlock     = axiReadAddr.lock;
    assign arcache    = axiReadAddr.cache;
    assign arprot     = axiReadAddr.protect;
    assign arvalid    = axiReadAddr.valid;

    assign axiReadAddr.ready    = arready;

    assign axiReadData.id       = rid     ;
    assign axiReadData.data     = rdata   ;
    assign axiReadData.respond  = rresp   ;
    assign axiReadData.last     = rlast   ;
    assign rready  =  axiReadData.ready;
    
    assign axiReadData.valid    = rvalid;

endmodule
