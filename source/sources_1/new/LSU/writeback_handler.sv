`timescale 1ns / 1ps
`include "LSU_defines.svh"
`include "MHandler_defines.svh"
module writeback_handler(
    GLOBAL.slave                g,
    MH2WBH.wbhandler            mh2wbh,
    DCACHE2MEMORY.dcache        dc2mem
    );
    logic           valid;
    logic   [27:0]  addr;
    logic   [127:0] data;
    always_ff @(posedge g.clk)
        if(!g.resetn)
            valid <= 1'b0;
        else if(mh2wbh.valid & dc2mem.mready)
            valid <= 1'b1;
        else if(dc2mem.mready)
            valid <= 1'b0;
    
    always_ff @(posedge g.clk) if(mh2wbh.valid & mh2wbh.ready) data <= mh2wbh.data;
    always_ff @(posedge g.clk) if(mh2wbh.valid & mh2wbh.ready) addr <= mh2wbh.addr;
    assign mh2wbh.ready = ~valid;
    assign mh2wbh.busy = dc2mem.dvalid;
    assign dc2mem.dvalid = mh2wbh.valid | valid;
    assign dc2mem.wen = 1'b1;
    assign dc2mem.addr = valid ? {addr,4'b0} : {mh2wbh.addr,4'b0};
    assign dc2mem.data = valid ? data : mh2wbh.data;
endmodule
