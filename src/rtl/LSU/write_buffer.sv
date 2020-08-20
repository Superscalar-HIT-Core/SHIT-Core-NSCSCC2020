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

`define WBUFROW     15:0
`define WBUFPOINTER 3:0

module write_buffer(
    GLOBAL.slave            g,
    LSU2WBUFFER.wbuf        lsu2wb,
    WRAPER2BUFFER.buffer    wp2wb,
    WBUFFER2DACCESSOR.wbuf  wb2da,
    WBUFFER2UHANDLER.wbuf   wb2uh,
    WBUFFER2RBUFFER.wbuf    wb2rb
    );

    WBUF_LINE wbuffer[`WBUFROW];
    logic [`WBUFPOINTER] wpointer,cpointer,cpointer1,fpointer;
    wire finish = ((wp2wb.op == dop_w) & wp2wb.hit & wbuffer[fpointer].cache) |
                   (wb2uh.w & wb2uh.ready & ~wbuffer[fpointer].cache);
    wire do_com = (lsu2wb.com | lsu2wb.com1) & ~lsu2wb.rb;
    wire do_dcom = lsu2wb.com & lsu2wb.com1 & ~lsu2wb.rb;
    
    integer j,cnt;
    always_ff @(posedge g.clk)begin
        cnt = 0;
        for(j = 0; j < 16; j = j + 1)
            if(wbuffer[j].valid)
                cnt = cnt + 1;
        lsu2wb.half = cnt >= 6;
    end

    always_ff @(posedge g.clk)
        if(!g.resetn)
            wpointer <= 4'b0;
        else if(lsu2wb.rb)
            wpointer <= cpointer;
        else if(lsu2wb.req & ~wbuffer[wpointer].valid)
            wpointer <= wpointer + 4'b1;

    always_ff @(posedge g.clk)
        if(!g.resetn)
            cpointer <= 4'b0;
        else if(do_dcom & wbuffer[cpointer1].valid)
            cpointer <= cpointer + 4'h2;
        else if(do_com & wbuffer[cpointer].valid)
            cpointer <= cpointer + 4'h1;
            
    always_ff @(posedge g.clk)
        if(!g.resetn)
            cpointer1 <= cpointer + 4'h1;
        else if(do_dcom & wbuffer[cpointer1].valid)
            cpointer1 <= cpointer + 4'h3;
        else if(do_com & wbuffer[cpointer].valid)
            cpointer1 <= cpointer + 4'h2;
        else
            cpointer1 <= cpointer + 4'h1;

    always_ff @(posedge g.clk)
        if(!g.resetn)
            fpointer <= 4'b0;
        else if(finish & wbuffer[fpointer].valid)
            fpointer <= fpointer + 4'b1;

    wire loaded = wb2da.load & wb2da.laddr == wbuffer[fpointer].addr[31:4];
    logic [`WBUFROW] do_write;
    generate
        genvar i;
        for(i = 0; i < 16; i = i + 1)
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
                else if(do_dcom & i == cpointer1)
                    wbuffer[i].com <= 1'b1;
                else if(do_com & i == cpointer)
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
    assign wb2da.waddr = wbuffer[fpointer].addr;
    assign wb2da.data = wbuffer[fpointer].data;
    assign wb2da.size = wbuffer[fpointer].size;

    assign wb2uh.w = wbuffer[fpointer].valid & wbuffer[fpointer].com & ~wbuffer[fpointer].issued & ~wbuffer[fpointer].cache;
    assign wb2uh.waddr = wbuffer[fpointer].addr;
    assign wb2uh.data = wbuffer[fpointer].data;
    assign wb2uh.size = wbuffer[fpointer].size;
endmodule
