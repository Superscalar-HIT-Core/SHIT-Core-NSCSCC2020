`timescale 1ns / 1ps

`include "LSU_defines.svh"

typedef struct packed {
    logic valid;
    logic dirty;
    logic [18:0] tag;
}TB_CONTENT;

typedef struct packed{
    logic           clk;
    logic           en;
    logic   [8:0]   addr;
    TB_CONTENT      tag;
}TB_IO;

typedef struct packed{
    logic           clk;
    logic           en;
    logic   [8:0]   addr;
    logic   [127:0] data;
}DB_RD;

typedef struct packed{
    logic           clk;
    logic   [15:0]  wen;
    logic   [8:0]   addr;
    logic   [127:0] data;
}DB_WR;

module dcache(
    GLOBAL.slave            g,
    WRAPER2DCACHE.dcache    wp2dc
    );
    wire [8:0] index = wp2dc.addr[12:4];
    logic [511:0] lru;

    logic [18:0] tag_reg;
    logic [8:0] index_reg,index_reg2;
    logic r_reg,w_reg,l_reg;
    logic [15:0] wd_reg;
    logic [127:0] din_reg;
    
    TB_IO tag0r,tag0w,tag1r,tag1w;
    DB_RD dbr0,dbr1;
    DB_WR dbw0,dbw1;
    
    assign tag0w.clk = g.clk;
    assign tag0r.clk = g.clk;
    assign tag1w.clk = g.clk;
    assign tag1r.clk = g.clk;
    
    assign dbw0.clk = g.clk;
    assign dbr0.clk = g.clk;
    assign dbw1.clk = g.clk;
    assign dbr1.clk = g.clk;
    
    TB_CONTENT tbc [1:0];
    TB_CONTENT tin_reg [1:0];

    always_ff @(posedge g.clk) tag_reg <= wp2dc.addr[31:13];
    always_ff @(posedge g.clk)
        if(!g.resetn)
            index_reg <= index_reg + 1;
        else
            index_reg <= index;
    always @(posedge g.clk)
        if(!g.resetn)
            index_reg2 <= 9'b0;
        else 
            index_reg2 <= index_reg;

    always_ff @(posedge g.clk) r_reg <= wp2dc.r;
    always_ff @(posedge g.clk) w_reg <= |wp2dc.wd & ~&wp2dc.wd;
    always_ff @(posedge g.clk) l_reg <= &wp2dc.wd;
    always_ff @(posedge g.clk) wd_reg <= wp2dc.wd;
    always_ff @(posedge g.clk) din_reg <= wp2dc.din;

    logic hit0,hit1,hit;
    logic hit0_reg,hit1_reg;
    assign hit0 = (tbc[0].tag == tag_reg) & tbc[0].valid;
    assign hit1 = (tbc[1].tag == tag_reg) & tbc[1].valid;
    always_ff @(posedge g.clk) hit0_reg <= g.resetn & hit0;
    always_ff @(posedge g.clk) hit1_reg <= g.resetn & hit1;
    always_comb
        if(hit0_reg)
            wp2dc.dout = dbr0.data;
        else if(hit1_reg)
            wp2dc.dout = dbr1.data;
        else
            case(lru[index_reg2])
            1'b0: wp2dc.dout = dbr0.data;
            1'b1: wp2dc.dout = dbr1.data;
            endcase

    always_ff @(posedge g.clk)
        if(!g.resetn)
            wp2dc.dirty <= 1'b0;
        else if((w_reg | r_reg) & ~hit)
            case(lru[index_reg])
            1'b0: wp2dc.dirty <= tbc[1].dirty & tbc[1].valid;
            1'b1: wp2dc.dirty <= tbc[0].dirty & tbc[1].valid;
            endcase 
        else
            wp2dc.dirty <= 1'b0;

    always_ff @(posedge g.clk)
        case(lru[index_reg])
        1'b0: wp2dc.tout <= tbc[1].tag;
        1'b1: wp2dc.tout <= tbc[0].tag;
        endcase

    assign hit = (hit0 | hit1) & (r_reg | w_reg);
    always_ff @(posedge g.clk) wp2dc.hit <= g.resetn & hit;

    assign dbw0.wen = w_reg & hit0 ? wd_reg :
                      l_reg & lru[index_reg] == 1'b1 ? wd_reg : 16'h0;
    assign dbw1.wen = w_reg & hit1 ? wd_reg :
                      l_reg & lru[index_reg] == 1'b0 ? wd_reg : 16'h0;
    assign dbw0.addr = index_reg;
    assign dbw1.addr = index_reg;
    assign tag0w.en = ((lru[index_reg] == 1'b1 & l_reg)|~g.resetn) | ((hit0) & w_reg);
    assign tag1w.en = ((lru[index_reg] == 1'b0 & l_reg)|~g.resetn) | ((hit1) & w_reg);
    assign tag0w.tag = {g.resetn,w_reg,tag_reg};
    assign tag1w.tag = {g.resetn,w_reg,tag_reg};

    always_ff @(posedge g.clk) 
        if(!g.resetn)
            lru <= 512'b0;
        else if(l_reg)
            lru[index_reg] <= ~lru[index_reg];
        else if((tbc[0].valid & tbc[0].tag == tag_reg) & (r_reg | w_reg))
            lru[index_reg] <= 1'b0;
        else if((tbc[1].valid & tbc[1].tag == tag_reg) & (r_reg | w_reg))
            lru[index_reg] <= 1'b1;

    wire tag0_bypass = (tag0w.addr == tag0r.addr) & tag0w.en & (wp2dc.r | |wp2dc.wd);
    reg tag0_bypass_reg;
    always_ff @(posedge g.clk) tag0_bypass_reg <= g.resetn & tag0_bypass;
    always_ff @(posedge g.clk) tin_reg[0] <= tag0w.tag;
    assign tbc[0] = tag0_bypass_reg ? tin_reg[0] : tag0r.tag;
    wire tag1_bypass = (tag1w.addr == tag1r.addr) & tag1w.en & (wp2dc.r | |wp2dc.wd);
    reg tag1_bypass_reg;
    always_ff @(posedge g.clk) tag1_bypass_reg <= g.resetn & tag1_bypass; 
    always_ff @(posedge g.clk) tin_reg[1] <= tag1w.tag;
    assign tbc[1] = tag1_bypass_reg ? tin_reg[1] : tag1r.tag;
    
    assign tag0w.addr = index_reg;
    assign tag0r.addr = index;
    assign tag0r.en = ~tag0_bypass & (wp2dc.r | |wp2dc.wd);
    tag_blk tag0(tag0w.clk,tag0w.en,tag0w.addr,tag0w.tag,tag0r.clk,tag0r.en,tag0r.addr,tag0r.tag);
    
    assign tag1w.addr = index_reg;
    assign tag1r.addr = index;
    assign tag1r.en = ~tag1_bypass & (wp2dc.r | |wp2dc.wd);
    tag_blk tag1(tag1w.clk,tag1w.en,tag1w.addr,tag1w.tag,tag1r.clk,tag1r.en,tag1r.addr,tag1r.tag);
    
    assign dbw0.data = din_reg;
    assign dbr0.en = ~|dbw0.wen;
    assign dbr0.addr = index_reg;
    data_blk data0(dbw0.clk,dbw0.wen,dbw0.addr,dbw0.data,dbr0.clk,dbr0.en,dbr0.addr,dbr0.data);
    
    assign dbw1.data = din_reg;
    assign dbr1.en = ~|dbw1.wen;
    assign dbr1.addr = index_reg;
    data_blk data1(dbw1.clk,dbw1.wen,dbw1.addr,dbw1.data,dbr1.clk,dbr1.en,dbr1.addr,dbr1.data);
endmodule
