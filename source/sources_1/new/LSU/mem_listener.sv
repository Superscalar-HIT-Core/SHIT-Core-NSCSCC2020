`timescale 1ns / 1ps

module mem_listener(
    GLOBAL.slave                g,
    MH2ML.mlistener             mh2ml,
    DCACHE2MEMORY.dcache        dc2mem,
    MHANDER2DACCESSOR.mhanlder  mh2da
    );

    assign dc2mem.ready = mh2da.ready;
    assign mh2da.valid = dc2mem.valid;
    assign mh2da.data = dc2mem.data;
    assign mh2da.addr = mh2ml.addr;
    assign mh2ml.received = mh2da.valid & mh2da.ready;
    
endmodule
