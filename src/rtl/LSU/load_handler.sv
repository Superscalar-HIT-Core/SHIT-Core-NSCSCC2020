`timescale 1ns / 1ps
`include "LSU_defines.svh"
`include "MHandler_defines.svh"
module load_handler(
    GLOBAL.slave                g,
    MH2LH.lhandler              mh2lh,
    DCACHE2MEMORY.dcache        dc2mem
    );

    logic           valid;
    logic   [27:0]  addr;
    always_ff @(posedge g.clk)
        if(!g.resetn)
            valid <= 1'b0;
        else if(mh2lh.valid & ~dc2mem.mready)
            valid <= 1'b1;
        else if(dc2mem.mready)
            valid <= 1'b0;

    always_ff @(posedge g.clk) if(mh2lh.valid & mh2lh.ready) addr <= mh2lh.addr;

    assign mh2lh.ready = ~valid;
    assign mh2lh.busy = dc2mem.dvalid;

    assign dc2mem.dvalid = mh2lh.valid | valid;
    assign dc2mem.addr = valid ? {addr,4'b0} : {mh2lh.addr,4'b0};
    assign dc2mem.wen = 1'b0;
endmodule
