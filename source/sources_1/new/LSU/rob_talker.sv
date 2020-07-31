`timescale 1ns / 1ps
`define EXP_ADDR_S  1'b1
`define EXP_ADDR_L  1'b0
module rob_talker(
    GLOBAL.slave            g,
    LSU2RTALKER.talker      lsu2rt,
    LSU2ROB.lsu             lsu2rob
    );

    logic wreq_reg;
    logic rreq_reg;
    logic [6:0] id_reg;
    logic addr_err_reg;
    logic [31:0] bad_addr_reg;
    always_ff @(posedge g.clk) 
        if(lsu2rt.rfin & ~lsu2rt.halt) 
            wreq_reg <= lsu2rt.wreq & g.resetn; 
        else if(~lsu2rt.rfin)
            wreq_reg <= 1'b0;
    always_ff @(posedge g.clk) 
        if(lsu2rt.rfin & ~lsu2rt.halt) 
            rreq_reg <= lsu2rt.rreq & g.resetn & lsu2rt.addr_err; 
        else if(~lsu2rt.rfin)
            rreq_reg <= 1'b0;
    always_ff @(posedge g.clk) if(!lsu2rt.halt) addr_err_reg <= lsu2rt.addr_err & g.resetn;
    always_ff @(posedge g.clk) if(!lsu2rt.halt) id_reg <= lsu2rt.id;
    always_ff @(posedge g.clk) if(!lsu2rt.halt) bad_addr_reg <= lsu2rt.bad_addr;
    assign lsu2rt.halt = wreq_reg | rreq_reg;
    assign lsu2rob.valid = lsu2rt.rfin | lsu2rt.wreq | wreq_reg | (lsu2rt.rreq & lsu2rt.addr_err) | rreq_reg;
    assign lsu2rob.id = lsu2rt.rfin ? lsu2rt.rid :
                 (wreq_reg | rreq_reg) ? id_reg : lsu2rt.id;
    always_comb 
        if(lsu2rt.wreq)
            lsu2rob.ls = lsu2rt.addr_err ? `EXP_ADDR_S : 1'bx;
        else if(wreq_reg)
            lsu2rob.ls = addr_err_reg ? `EXP_ADDR_S : 1'bx;
        else if(lsu2rt.rreq & lsu2rt.addr_err)
            lsu2rob.ls = `EXP_ADDR_L;
        else if(rreq_reg)
            lsu2rob.ls = `EXP_ADDR_L;
        else
            lsu2rob.ls = `EXP_ADDR_L;
    
    assign lsu2rob.set_ex = (lsu2rt.addr_err | addr_err_reg) & ~ lsu2rt.rfin;
    assign lsu2rob.bad_addr = addr_err_reg ? bad_addr_reg : lsu2rt.bad_addr;
endmodule
