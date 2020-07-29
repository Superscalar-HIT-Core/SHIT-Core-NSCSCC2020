`timescale 1ns / 1ps
`include "LSU_defines.svh"

typedef struct packed {
    logic               valid;
    logic   [6:0]       id;
    logic               cache;
    logic   [31:0]      addr;
    Size                size;
    logic   [31:0]      data;
    logic               com;
    logic               issued;
} WBUF_LINE;

`define WBUFROW     7:0
`define WBUFPOINTER 2:0

module write_buffer(
    GLOBAL.slave            g,
    LSU2WBUFFER.wbuf        lsu2wb,
    WRAPER2BUFFER.buffer    wp2buf,
    WBUFFER2DACCESSOR.wbuf  wb2da,
    WBUFFER2UHANDLER.wbuf   wb2uh,
    WBUFFER2RBUFFER.wbuf    wb2rb
    );

    WBUF_LINE wbuffer[`WBUFROW];
    logic [`WBUFPOINTER] wpointer,cpointer,fpointer;
    logic finish = ((wp2wb.op == dop_w) & wp2wb.hit & wbuffer[fpointer].cache) |
                   (wb2uh.w & wb2uh.ready & ~wbuffer[fpointer].cache);

    always_ff @(posedge g.clk)
        if(!g.resetn)
            wpointer <= 3'b0;
        else if(lsu2wb.rb)
            wpointer <= cpointer;
        else if(lsu2wb.req & ~wbuffer[wpointer].valid)
            wpointer <= wpointer + 3'b1;

    always_ff @(posedge g.clk)
        if(!g.resetn)
            cpointer <= 3'b0;
        else if(lsu2wb.com & wbuffer[cpointer].valid)
            cpointer <= cpointer + 3'b1;

    always_ff @(posedge g.clk)
        if(!g.resetn)
            fpointer <= 3'b0;
        else if(finish & wbuffer[fpointer].valid)
            fpointer <= fpointer + 3'b1;

    logic loaded = wb2da.load & wb2da.laddr == wbuffer[fpointer].addr[31:4];
    logic [7:0] do_write;
    generate
        genvar i;
        for(i = 0; i < 8; i = i + 1)
        begin
            assign do_write[i] = lsu2wb.req & wpointer == i & ~wbuffer[i].valid;

            always_ff @(posedge g.clk)
                if(!g.resetn)
                    wbuffer[i].valid <= 1'b0;
                else if(lsu2wb.rb & ~wbuffer[i].com)
                    wbuffer[i].valid <= 1'b0;
                else if(finish & i == fpointer)
                    wbuffer[i].valid <= 1'b0;
                else if(lsu2wb.req & i == wpointer & ~lsu2wb.rb)
                    wbuffer[i].valid <= 1'b1;
            
            always_ff @(posedge g.clk) 
                if(lsu2wb.req & i == wpointer & ~wbuffer[i].valid)
                    wbuffer[i].com <= 1'b0;
                else if(lsu2wb.com & i == cpointer)
                    wbuffer[i].com <= 1'b1;
            
            always_ff @(posedge g.clk)
                if(lsu2wb.req & i == wpointer & ~wbuffer[i].valid)
                    wbuffer[i].issued <= 1'b0;
                else if(loaded)
                    wbuffer[i].issued <= 1'b0;
                else if(wb2da.w & wb2da.ready & i == fpointer)
                    wbuffer[i].issued <= 1'b1;

            always_ff @(posedge g.clk) if(do_write[i]) wbuffer[i].addr <= lsu2wb.addr;
            always_ff @(posedge g.clk) if(do_write[i]) wbuffer[i].data <= lsu2wb.data;
            always_ff @(posedge g.clk) if(do_write[i]) wbuffer[i].size <= lsu2wb.size;
            always_ff @(posedge g.clk) if(do_write[i]) wbuffer[i].id <= lsu2wb.id;
            always_ff @(posedge g.clk) if(do_write[i]) wbuffer[i].cache <= lsu2wb.cache;
            assign wb2rb.rely[i] = lsu2wb.cache ? 
                (wbuffer[i].valid & wbuffer[i].cache & wbuffer[i].addr[31:2] == lsu2wb.addr[31:2]):
                (wbuffer[i].valid & ~wbuffer[i].cache);
            assign wb2rb.cur[i] = wbuffer[i].valid;
        end
    endgenerate
    
    assign lsu2wb.busy = wbuffer[wpointer].valid | lsu2wb.rb;

    assign wb2da.w = wbuffer[fpointer].valid & wbuffer[fpointer].com & ~wbuffer[fpointer].issued & wbuffer[fpointer].cache;
    assign wb2da.addr = wbuffer[fpointer].addr;
    assign wb2da.data = wbuffer[fpointer].data;
    assign wb2da.size = wbuffer[fpointer].size;

    assign wb2uh.w = wbuffer[fpointer].valid & wbuffer[fpointer].com & ~wbuffer[fpointer].issued & ~wbuffer[fpointer].cache;
    assign wb2uh.addr = wbuffer[fpointer].addr;
    assign wb2da.data = wbuffer[fpointer].data;
    assign wb2da.size = wbuffer[fpointer].size;
endmodule
