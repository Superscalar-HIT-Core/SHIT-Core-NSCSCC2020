`timescale 1ns / 1ps

module mem_listener(
    GLOBAL.slave                g,
    MH2ML.mlistener             mh2ml,
    DCACHE2MEMORY.dcache        dc2mem,
    MHANDLER2DACCESSOR.mhandler  mh2da
    );

    assign dc2mem.dready = mh2da.ready;
    assign mh2da.valid = dc2mem.mvalid;
    assign mh2da.data = dc2mem.mdata;
    assign mh2da.addr = mh2ml.addr;
    assign mh2ml.received = mh2da.valid & mh2da.ready;
    
endmodule
