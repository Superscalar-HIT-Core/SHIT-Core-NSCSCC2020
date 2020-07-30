`timescale 1ns / 1ps
`include "LSU_defines.svh"
module uncache_handler(
    GLOBAL.slave                g,
    WBUFFER2UHANDLER.uhandler   wb2uh,
    RBUFFER2UHANDLER.uhandler   rb2uh,
    UNCACHE2MEMORY.lsu          uc2mem
    );

    logic rbusy;
    logic rready = 1'b1;
    logic [31:0] raddr = rb2uh.raddr;
    assign rb2uh.uready = uc2mem.mready & ~rbusy;
    
    always_ff @(posedge g.clk)
        if(!g.resetn)
            rbusy <= 1'b0;
        else if(rb2uh.rvalid & rb2uh.uready)
            rbusy <= 1'b1;
        else if(rb2uh.uvalid & rb2uh.rready)
            rbusy <= 1'b0;

    reg [1:0] raddr_reg;
    Size size_reg;
    always @(posedge g.clk) if(rb2uh.rvalid & rb2uh.uready) raddr_reg <= raddr[1:0];
    always @(posedge g.clk) if(rb2uh.rvalid & rb2uh.uready) size_reg <= rb2uh.rsize;

    assign wb2uh.ready = rb2uh.uready & ~rb2uh.rvalid;

    assign uc2mem.uvalid = (rb2uh.rvalid | wb2uh.w) & rb2uh.uready;
    assign uc2mem.uwen = wb2uh.w;
    assign uc2mem.uaddr = wb2uh.w ? {wb2uh.waddr[31:2],2'b0} : {rb2uh.raddr[31:2],2'b0};
    assign uc2mem.udata = wb2uh.data;
    assign uc2mem.uready = rb2uh.rready;

    always_comb 
        case(wb2uh.size)
        s_word: uc2mem.ustrobe = 4'hf;
        s_half: 
            case(wb2uh.waddr[1])
            1'b0: uc2mem.ustrobe = 4'h3;
            1'b1: uc2mem.ustrobe = 4'hc;
            endcase
        s_byte:
            case(wb2uh.waddr[1:0])
            2'b00: uc2mem.ustrobe = 4'h1;
            2'b01: uc2mem.ustrobe = 4'h2;
            2'b10: uc2mem.ustrobe = 4'h4;
            2'b11: uc2mem.ustrobe = 4'h8;
            endcase
        default: uc2mem.ustrobe = 4'hx;
        endcase

    always_ff @(posedge g.clk)
        if(!g.resetn)
            rb2uh.uvalid <= 1'b0;
        else if(uc2mem.uvalid)
            rb2uh.uvalid <= 1'b1;
        else if(rb2uh.rready)
            rb2uh.uvalid <= 1'b0;

    logic [31:0] data = uc2mem.mdata >> {raddr_reg,3'b0};
    always_ff @(posedge g.clk)
        if(uc2mem.mvalid)
            case(size_reg)
            s_word: rb2uh.udata <= data;
            s_half: rb2uh.udata <= {{16{data[15]}},data[15:0]};
            s_byte: rb2uh.udata <= {{24{data[7]}},data[7:0]};
            default: rb2uh.udata <= 32'hx;
            endcase 
endmodule
