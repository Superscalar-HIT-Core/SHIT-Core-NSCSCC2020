`timescale 1ns / 1ps
`include "LSU_defines.svh"

typedef struct packed {
    logic               valid;
    logic   [6:0]       id;
    logic   [5:0]       regid;
    logic               cache;
    logic   [31:0]      addr;
    Size                size;
    logic               isSigned;
    logic   [15:0]      rely;
    logic               hold;
    logic               issued;
    logic               miss;
} RBUF_LINE;
`define RBUFROW     15:0
`define RBUFPOINTER 3:0
module read_buffer(
    GLOBAL.slave                g,
    LSU2RBUFFER.rbuf            lsu2rb,
    WBUFFER2RBUFFER.rbuf        wb2rb,
    RBUFFER2DACCESSOR.rbuf      rb2da,
    WRAPER2BUFFER.buffer        wp2rb,
    RBUFFER2UHANDLER.rbuf       rb2uh,
    LSU2PRF.lsu                 lsu2prf
    );
    logic flush_reg;
    always_ff @(posedge g.clk) flush_reg <= lsu2rb.flush & g.resetn;
    wire flush_all = lsu2rb.flush | flush_reg;
    RBUF_LINE rbuffer[`RBUFROW];
    logic [`RBUFPOINTER] avail,ready;
    logic [`RBUFPOINTER] launch[1:0];
    logic [`RBUFPOINTER] lu;
    logic [`RBUFROW] valids,readys,load,miss,dmiss,elders,youngers;
    logic [`RBUFROW] dmiss_reg,dmiss_reg2;
    wire hasElder = |elders;
    wire hit = (wp2rb.op == dop_r) & wp2rb.hit;
    integer j,k,l,cnt;
    always_comb begin
        avail = 4'b0;
        for(j = 0; j < 16; j = j + 1)
            if(valids[j])
                avail = avail + 4'b1;
            else break;
    end

    always_comb begin
        ready = 4'b0;
        for(k = 0; k < 16; k = k + 1)
            if(!readys[k])
                ready = ready + 4'b1;
            else break;
    end
    
    always_ff @(posedge g.clk) begin
        cnt = 0;
        for(l = 0; l < 16; l = l + 1)
            if(valids[j])
                cnt = cnt + 1;
        lsu2rb.half = cnt >= 6;
    end

    assign lsu2rb.busy = (rbuffer[avail].valid == 1'b1) | lsu2rb.flush;
    always_ff @(posedge g.clk) if(!g.resetn) dmiss_reg <= 4'b0; else dmiss_reg <= dmiss;
    always_ff @(posedge g.clk) if(!g.resetn) dmiss_reg2 <= 4'b0; else dmiss_reg2 <= dmiss_reg;
    generate
        genvar i;
        for(i = 0; i < 16; i = i + 1)
        begin
            assign load[i] = ~rbuffer[i].valid & i == avail & lsu2rb.valid;
            assign miss[i] = (wp2rb.addr[31:4] == rbuffer[i].addr[31:4]) &
                            (wp2rb.op == dop_w | wp2rb.op == dop_r) & 
                            ~wp2rb.hit & rbuffer[i].cache;
                            
            assign dmiss[i] =   (rb2da.load & rb2da.laddr == rbuffer[i].addr[31:4] & rbuffer[i].cache) | elders[i] | (youngers[i] & ~hasElder);
            assign elders[i] =   (~rbuffer[i].cache & lsu2rb.rid0 == rbuffer[i].id & rbuffer[i].valid);
            assign youngers[i] = (~rbuffer[i].cache & lsu2rb.rid1 == rbuffer[i].id & & rbuffer[i].valid & (~lsu2rb.valid0 | lsu2rb.commit0));
            assign valids[i] = rbuffer[i].valid;
            assign readys[i] = rbuffer[i].valid & ~rbuffer[i].hold & ~rbuffer[i].issued & ~rbuffer[i].miss;
            always_ff @(posedge g.clk)
                if(!g.resetn | lsu2rb.flush)
                    rbuffer[i].valid <= 1'b0;
                else if((hit & launch[1] == i) | (rb2uh.uvalid & lu == i))
                    rbuffer[i].valid <= 1'b0;
                else if(lsu2rb.valid & i == avail)
                    rbuffer[i].valid <= 1'b1;

            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].addr <= lsu2rb.addr;
            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].regid <= lsu2rb.regid;
            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].size <= lsu2rb.size;
            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].id <= lsu2rb.id;
            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].cache <= lsu2rb.cache;
            always_ff @(posedge g.clk) if(load[i]) rbuffer[i].isSigned <= lsu2rb.isSigned;
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
                if(load[i])
                    rbuffer[i].miss <= ~lsu2rb.cache;
                else if(dmiss[i] | dmiss_reg[i] | dmiss_reg2[i])
                    rbuffer[i].miss <= 1'b0;
                else if(miss[i])
                    rbuffer[i].miss <= 1'b1;
        end     
    endgenerate
    assign rb2da.r = readys[ready] & rbuffer[ready].cache;
    assign rb2da.raddr = rbuffer[ready].addr;
    assign rb2da.size = rbuffer[ready].size;
    assign rb2uh.rvalid = readys[ready] & ~rbuffer[ready].cache & ~flush_all;
    assign rb2uh.raddr = rbuffer[ready].addr;
    assign rb2uh.rsize = rbuffer[ready].size;
    assign rb2uh.rready = ~hit;
    
    always_ff @(posedge g.clk) launch[0] <= ready;
    always_ff @(posedge g.clk) launch[1] <= launch[0];
    always_ff @(posedge g.clk)
        if(rb2uh.uready & rb2uh.rvalid)
            lu <= ready;
    assign lsu2prf.valid = (hit | rb2uh.uvalid) & ~flush_all;
    assign lsu2prf.regid = hit ? rbuffer[launch[1]].regid : rbuffer[lu].regid;
    assign lsu2prf.id = hit ? rbuffer[launch[1]].id : rbuffer[lu].id;
    
    logic [31:0] real_data;
    always_comb
        if(hit)
            case(rbuffer[launch[1]].size)
            s_byte: lsu2prf.data = {{24{rbuffer[launch[1]].isSigned & wp2rb.data[7]}},wp2rb.data[7:0]};
            s_half: lsu2prf.data = {{16{rbuffer[launch[1]].isSigned & wp2rb.data[15]}},wp2rb.data[15:0]};
            s_word: lsu2prf.data = wp2rb.data;
            default: lsu2prf.data = 32'hx;
            endcase
        else
            case(rbuffer[lu].size)
            s_byte: lsu2prf.data = {24'h0,rb2uh.udata[7:0]};
            s_half: lsu2prf.data = {16'h0,rb2uh.udata[15:0]};
            s_word: lsu2prf.data = rb2uh.udata;
            default: lsu2prf.data = 32'hx;
            endcase 
    
    
endmodule
