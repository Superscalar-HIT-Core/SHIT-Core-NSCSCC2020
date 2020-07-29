`timescale 1ns / 1ps
`include "LSU_defines.svh"

typedef struct packed {
    logic               valid;
    logic   [6:0]       id;
    logic   [5:0]       regid;
    logic               cache;
    logic   [31:0]      addr;
    Size                size;
    logic   [7:0]       rely;
    logic               hold;
    logic               issued;
    logic               miss;
} RBUF_LINE;
`define RBUFROW 3:0
`define RBUFPOINTER 1:0
module read_buffer(
    GLOBAL.slave                g,
    LSU2RBUFFER.rbuf            lsu2rb,
    WBUFFER2RBUFFER.rbuf        wb2rb,
    RBUFFER2DACCESSOR.rbuf      rb2da,
    WRAPER2BUFFER.buffer        wp2bf,
    RBUFFER2UHANDLER.rbuf       rb2uh,
    LSU2PRF.lsu                 lsu2prf
    );
    RBUF_LINE rbuffer[`RBUFROW];
    logic [`RBUFPOINTER] avail,ready;
    logic [`RBUFPOINTER] launch[1:0];
    logic [`RBUFPOINTER] lu;
    logic [`RBUFROW] valids,readys,load,miss,dmiss;
    logic hit = wp2rb.op == dop_r & wp2rb.hit;
    always_comb
        casez(valids)
        4'b???0: avail = 2'b00;
        4'b??01: avail = 2'b01;
        4'b?011: avail = 2'b10;
        4'b0111: avail = 2'b11;
        default: avail = 2'b00;
        endcase
    always_comb 
        casez(readys)
        4'b???1: ready = 2'b00;
        4'b??10: ready = 2'b01;
        4'b?100: ready = 2'b10;
        4'b1000: ready = 2'b11;
        default: ready = 2'b00;
        endcase

    assign lsu2rb.busy = rbuffer[avail].valid == 1'b1;
    generate
        genvar i;
        for(i = 0; i < 4; i = i + 1)
        begin
            assign load[i] = ~rbuffer[i].valid & i == avail & lsu2rb.valid;
            assign miss[i] = (wp2rb.addr[31:4] == rbuffer[i].addr[31:4]) &
                            (wp2rb.op == dop_w | wp2rb.op == dop_r) & 
                            ~wp2rb.hit & rbuffer[i].cache;
            assign dmiss[i] = da2rb.load & da2rb.addr == rbuffer[i].addr[31:4];
            assign valids[i] = rbuffer[i].valid;
            assign readys[i] = rbuffer[i].valid & ~rbuffer[i].hold & ~rbuffer[i].issued & ~rbuffer[i].miss;
            always_ff @(posedge g.clk)
                if(!g.resetn)
                    rbuffer[i].valid <= 1'b0;
                else if((hit & launch[1] == i) | (rb2uh.valid & lu == i))
                    rbuffer[i].valid <= 1'b0;
                else if(lsu2rb.valid & i == avail)
                    rbuffer[i].valid <= 1'b1;

            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].addr <= lsu2rb.addr;
            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].regid <= lsu2rb.regid;
            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].size <= lsu2rb.size;
            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].id <= lsu2rb.id;
            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].cache <= lsu2rb.cache;
            always_ff @(posedge g.clk)
                if(load[i])
                    rbuffer[i].rely <= wb2rb.rely;
                else 
                    rbuffer[i].rely <= rbuffer[i].rely & wb2rb.cur;
            always_ff @(posedge g.clk) 
                if(load[i])
                    rbuffer[i].hold <= |wb2rb.rely;
                else
                    rbuffer[i].hold <= |(rbuffer[i].rely & wb2rb.cur);
            always_ff @(posedge g.clk)
                if(load[i])
                    rbuffer[i].issued <= 1'b0;
                else if(((rb2da.r & rb2da.ready) |
                        (rb2uh.rvalid & rb2uh.uready)) & ready == i)
                    rbuffer[i].issued <= 1'b1;
                else if(miss[i])
                    rbuffer[i].issued <= 1'b0;
            always_ff @(posedge g.clk)
                if(load[i] | dmiss[i])
                    rbuffer[i].miss <= 1'b0;
                else if(miss[i])
                    rbuffer[i].miss <= 1'b1;
        end     
    endgenerate
    assign rb2da.r = readys[ready] & rbuffer[ready].cache;
    assign rb2da.addr = rbuffer[ready].addr;
    assign rb2da.size = rbuffer[ready].size;
    assign rb2uh.rvalid = readys[ready] & ~rbuffer[ready].cache;
    assign rb2uh.raddr = rbuffer[ready].addr;
    assign rb2uh.rsize = rbuffer[ready].size;
    assign rb2uh.rready = ~hit;
    
    always_ff @(posedge g.clk) launch[0] <= ready;
    always_ff @(posedge g.clk) launch[1] <= launch[0];
    always_ff @(posedge g.clk)
        if(rb2uh.uready & rb2uh.rvalid)
            lu <= ready;
    assign lsu2prf.valid = hit | rb2uh.uvalid;
    assign lsu2prf.regid = hit ? rbuffer[launch[i]].regid : rbuffer[lu].regid;
    assign lsu2prf.id = hit ? rbuffer[launch[1].id] : rbuffer[lu].id;
    assign lsu2prf.data = hit ? wp2rb.data : rb2uh.udata;
endmodule
