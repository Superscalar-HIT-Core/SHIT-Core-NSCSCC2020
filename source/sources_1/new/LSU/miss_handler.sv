`timescale 1ns / 1ps
`include "LSU_defines.svh"
module miss_handler(
    GLOBAL.slave                g,
    WRAPER2MHANDLER.mhandler    wp2mh,
    DCACHE2MEMORY.dcache        dc2mem,
    MHANDLER2DACCESSOR.mhandler mh2da
    );

    MSHR_LINE   MSHR[`MSHRROW];
    logic miss = (wp2mh.op == dop_w | wp2mh.op == dop_r) & ~wp2mh.hit;
    logic [27:0] laddr_reg;
    logic load_reg;
    logic [`MSHRROW] adchecks;
    logic adcheck = (load_reg & laddr_reg == wp2mh.addr[31:4]) | |adchecks;

    MH2WBH  mh2wbh();
    MH2LH   mh2lh();
    MH2ML   mh2ml();

    DCACHE2MEMORY           wbh_dc2mem();
    DCACHE2MEMORY           lh_dc2mem();
    DCACHE2MEMORY           ml_dc2mem();

    logic [`MSHRPOINTER] lpointer,ipointer,dpointer;
    always_ff @(posedge g.clk)
        if(!g.resetn)
            lpointer <= 3'b0;
        else if(miss & ~adcheck & MSHR[lpointer].valid)
            lpointer <= lpointer + 3'b1;
    
    always_ff @(posedge g.clk)
        if(!g.resetn)
            ipointer <= 3'b0;
        else if(lh_dc2mem.dvalid & lh_dc2mem.mready)
            ipointer <= ipointer + 3'b1;

    always_ff @(posedge g.clk)
        if(!g.resetn)
            dpointer <= 3'b0;
        else if(mh2ml.received)
            dpointer <= dpointer + 3'b1;

    generate
        genvar i;
        for(i = 0; i < 8; i = i + 1)
        begin
            assign adchecks[i] = MSHR[i].valid & MSHR[i].addr == wp2mh.addr[31:4];
            always_ff @(posedge g.clk)
                if(!g.resetn)
                    MSHR[i].valid <= 1'b0;
                else if(mh2ml.received & i == dpointer)
                    MSHR[i].valid <= 1'b0;
                else if(miss & ~adcheck & lpointer == i)
                    MSHR[i].valid <= 1'b1;
            always_ff @(posedge g.clk) if(i == lpointer & ~MSHR[i].valid) MSHR[i].addr <= wp2mh.addr[31:4];
            always_ff @(posedge g.clk) if(i == lpointer & ~MSHR[i].valid) MSHR[i].tag <= wp2mh.tag;
            always_ff @(posedge g.clk) if(i == lpointer & ~MSHR[i].valid) MSHR[i].data <= wp2mh.data;
            always_ff @(posedge g.clk)
                if(miss & ~adcheck & i == lpointer & ~MSHR[i].valid)
                    MSHR[i].wb <= wp2mh.dirty;
                else if(mh2wbh.valid & mh2wbh.ready)
                    MSHR[i].wb <= 1'b0;
            always_ff @(posedge g.clk)
                if(miss & ~adcheck & i == lpointer & ~MSHR[i].valid)
                    MSHR[i].issued <= 1'b0;
                else if(mh2lh.valid & mh2lh.ready & i == ipointer)
                    MSHR[i].issued <= 1'b1;
        end
    endgenerate

    always_ff @(posedge g.clk)
        load_reg <= g.resetn & mh2da.valid;

    always_ff @(posedge g.clk)
        laddr_reg <= mh2da.addr;        

    assign mh2wbh.valid = MSHR[ipointer].valid & MSHR[ipointer].wb;
    assign mh2wbh.addr = {MSHR[ipointer].tag,MSHR[ipointer].addr[8:0]};
    assign mh2wbh.data = MSHR[ipointer].data;
    assign wbh_dc2mem.mready = dc2mem.mready;
    writeback_handler wb_handler(g,mh2wbh.wbhandler,wbh_dc2mem.dcache);

    assign mh2lh.valid = MSHR[ipointer].valid & ~MSHR[ipointer].issued;
    assign mh2lh.addr = MSHR[ipointer].addr;
    assign lh_dc2mem.mready = ~mh2wbh.busy & dc2mem.mready;
    load_handler l_handler(g,mh2lh.lhandler,lh_dc2mem.dcache);

    assign mh2ml.addr = MSHR[dpointer].addr;
    assign ml_dc2mem.mvalid = dc2mem.mvalid;
    assign ml_dc2mem.mdata = dc2mem.mdata;
    mem_listener m_listener(g,mh2ml.mlistener,ml_dc2mem.dcache,mh2da);

    assign dc2mem.dvalid = wbh_dc2mem.dvalid | lh_dc2mem.dvalid;
    assign dc2mem.wen   = wbh_dc2mem.dvalid ? wbh_dc2mem.wen : lh_dc2mem.wen;
    assign dc2mem.addr  = wbh_dc2mem.dvalid ? wbh_dc2mem.addr : lh_dc2mem.addr;
    assign dc2mem.ddata  = wbh_dc2mem.ddata;
    assign dc2mem.dready = ml_dc2mem.dready;
endmodule
