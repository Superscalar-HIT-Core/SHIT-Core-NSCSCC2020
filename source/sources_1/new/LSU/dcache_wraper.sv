`timescale 1ns / 1ps
`include "LSU_defines.svh"
module dcache_wraper(
    GLOBAL.slave    g,
    DACCESSOR2WRAPER.wraper da2wp,
    WRAPER2MHANDLER.wraper  wp2mh,
    WRAPER2BUFFER.wraper    wp2buf
    );

    WRAPER2DCACHE wp2dc();
    assign wp2dc.r = ~da2wp.l & da2wp.r; 
    assign wp2dc.wt = 1'b0;
    assign wp2dc.addr = da2wp.addr;
    
    always_comb
        if(da2wp.l)
            wp2dc.wd = 16'hffff;
        else if(da2wp.w)
            case(da2wp.size)
            s_byte: wp2dc.wd = 16'h1 << da2wp.addr[3:0];
            s_half: wp2dc.wd = 16'h3 << da2wp.addr[3:0];
            s_word: wp2dc.wd = 16'hf << da2wp.addr[3:0];
            default: wp2dc.wd = 16'h0;
            endcase
        else
            wp2dc.wd = 16'h0;
    
    always_comb
        if(da2wp.l)
            wp2dc.din = da2wp.data;
        else
            wp2dc.din = da2wp.data << {da2wp.addr[3:0],3'b0};

    Size size_reg[1:0];
    logic [31:0] addr_reg[1:0];
    logic [31:0] word = wp2dc.dout >> {addr_reg[1][3:0],3'b0};
    Dcache_op op[1:0];
    
    always_ff @(posedge g.clk)
        if(!g.resetn)
            op[0] <= dop_nil;
        else if(da2wp.l)
            op[0] <= dop_l;
        else if(da2wp.w)
            op[0] <= dop_w;
        else if(da2wp.r)
            op[0] <= dop_r;
        else 
            op[0] <= dop_nil;
    always_ff @(posedge g.clk) if(!g.resetn) op[1] <= dop_nil; else op[1] <= op[0];

    always_ff @(posedge g.clk) size_reg[0] <= (!g.resetn) ? s_nil : da2wp.size;
    always_ff @(posedge g.clk) size_reg[1] <= (!g.resetn) ? s_nil : size_reg[0];
    always_ff @(posedge g.clk) addr_reg[0] <= (!g.resetn) ? 32'b0:da2wp.addr;
    always_ff @(posedge g.clk) addr_reg[1] <= (!g.resetn) ? 32'b0:addr_reg[0];

    dcache dcache(g,wp2dc.dcache);
    assign wp2mh.op = op[1];
    assign wp2mh.addr = addr_reg[1];
    assign wp2mh.tag = wp2dc.tout;
    assign wp2mh.data = wp2dc.dout;
    assign wp2mh.hit = wp2dc.hit;
    assign wp2mh.dirty = wp2dc.dirty;

    assign wp2buf.op = op[1];
    assign wp2buf.hit = wp2dc.hit;
    assign wp2buf.addr = addr_reg[1];
    always_comb
        case(size_reg[1])
        s_byte: wp2buf.data = {{24{word[7]}},word[7:0]};
        s_half: wp2buf.data = {{16{word[15]}},word[15:0]};
        s_word: wp2buf.data = word;
        default: wp2buf.data = 32'hx;
        endcase
endmodule
