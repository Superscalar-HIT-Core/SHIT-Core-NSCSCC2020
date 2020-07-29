`timescale 1ns / 1ps

`include "LSU_defines.svh"

typedef struct packed {
    logic valid;
    logic dirty;
    logic [18:0] tag;
}TB_CONTENT;

module dcache(
    GLOBAL.slave            g,
    WRAPER2DCACHE.dcache    wp2dc
    );
    logic [8:0] index = wp2dc.addr[12:4];
    logic [511:0] lru;
    logic bypass;
    logic bypass_reg;

    logic [18:0] tag_reg;
    logic [8:0] index_reg,index_reg2;
    logic r_reg,w_reg,l_reg;
    logic [15:0] wd_reg;
    logic [127:0] din_reg;
    
    TB_CONTENT tbc [1:0];
    logic [127:0] dbc [1:0];

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

    always_ff @(posedge g.clk) r_reg <= 4;
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
        if(bypass_reg)
            case(lru[index_reg2])
            1'b0: wp2dc.dout = dbc[0];
            1'b1: wp2dc.dout = dbc[1];
            endcase
        else if(hit0_reg)
            wp2dc.dout = dbc[0];
        else if(hit1_reg)
            wp2dc.dout = dbc[1];
        else
            case(lru[index_reg2])
            1'b0: wp2dc.dout = dbc[1];
            1'b1: wp2dc.dout = dbc[0];
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

    assign hit = ((hit0 | hit1) & (r_reg | w_reg)) | (bypass & (r_reg | w_reg));
    always_ff @(posedge g.clk) wp2dc.hit <= g.resetn & hit;

    logic [15:0] dwe[1:0];
    logic [1:0] twe;
    TB_CONTENT tin[1:0];
    logic dwaddr[1:0];
    assign dwe[0] = w_reg & hit0 ? wd_reg :
                    l_reg & lru[index_reg] == 1'b1 ? wd_reg : 
                    w_reg & bypass & lru[index_reg] == 1'b0 ? wd_reg : 16'h0;
    assign dwe[1] = w_reg & hit1 ? wd_reg :
                    l_reg & lru[index_reg] == 1'b0 ? wd_reg : 
                    w_reg & bypass & lru[index_reg] == 1'b1 ? wd_reg : 16'h0;
    assign dwaddr[0] = index_reg;
    assign dwaddr[1] = index_reg;
    assign twe[0] = ((lru[index_reg] == 1'b1 & l_reg)|~g.resetn) | ((hit0 | (bypass & lru[index_reg] == 1'b0)) & w_reg);
    assign twe[1] = ((lru[index_reg] == 1'b0 & l_reg)|~g.resetn) | ((hit1 | (bypass & lru[index_reg] == 1'b1)) & w_reg);
    assign tin[0] = {w_reg,g.resetn,tag_reg};
    assign tin[1] = {w_reg,g.resetn,tag_reg};

    always_ff @(posedge g.clk) bypass <= g.resetn & l_reg & (index_reg == index) & (tag_reg == wp2dc.addr[31:13]);
    always_ff @(posedge g.clk) bypass_reg <= g.resetn & bypass;
    always_ff @(posedge g.clk) 
        if(!g.resetn)
            lru <= 512'b0;
        else if(l_reg)
            lru[index_reg] <= ~lru[index_reg];
        else if((tbc[0].valid & tbc[0].tag == tag_reg) & (r_reg | w_reg))
            lru[index_reg] <= 1'b0;
        else if((tbc[1].valid & tbc[1].tag == tag_reg) & (r_reg | w_reg))
            lru[index_reg] <= 1'b1;

    tag_blk tag0(g.clk,twe[0],index_reg,tin[0],clk,index,tbc[0]);
    tag_blk tag1(g.clk,twe[1],index_reg,tin[1],clk,index,tbc[1]);
    data_blk data0(g.clk,dwe[0],dwaddr[0],din_reg[0],clk,index_reg,dbc[0]);
    data_blk data1(g.clk,dwe[1],dwaddr[1],din_reg[0],clk,index_reg,dbc[1]);
endmodule
