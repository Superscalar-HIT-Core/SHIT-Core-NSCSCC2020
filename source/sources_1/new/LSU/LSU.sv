`timescale 1ns / 1ps
`include "LSU_defines.svh"
`include "../defines/defines.svh"
module LSU(
    input   logic           clk,
    input   logic           rst,
    Ctrl.slave              ctrl_lsu,
    output  logic           r_busy,
    output  logic           w_busy,
    input   logic           fireStore,
    input   UOPBundle       uOP,
    input   PRFrData        oprands,
    output  PRFwInfo        wbData,
    FU_ROB.fu               lsu_commit_reg,
    DataReq.lsu             dataReq,
    DataResp.lsu            dataResp,
    DcacheReq.lsu           dcacheReq,
    DcacheResp.lsu          dcacheResp,
    input  [`ROB_ID_W]      rid0,
    input                   valid0,
    input                   com0,
    input  [`ROB_ID_W]      rid1
    );
    assign pauseReq = 1'b0;
    assign flushReq = 1'b0;

    logic [31:0] vaddr = oprands.rs0_data + uOP.imm;
    logic [31:0] paddr = (vaddr[31:30] == 2'b10) ? {3'b0,vaddr[28:0]} : vaddr;
    logic cache = ~(vaddr[31:28] == 4'ha | vaddr[31:28] == 4'hb);
    Size size;
    always_comb 
        case(uOP.uOP)
        LB_U,LBU_U,SB_U: size = s_byte;
        LH_U,LHU_U,SH_U: size = s_half;
        LW_U,SW_U:  size = s_word;
        endcase

    logic addr_err;
    always_comb 
        case(uOP.uOP)
        LH_U,LHU_U,SH_U: addr_err = vaddr[0];
        LW_U,SW_U:  addr_err = |vaddr[1:0];
        default: addr_err = 1'b0;
        endcase

    logic store = uOP.uOP == SB_U | uOP.uOP == SH_U | uOP.uOP == SW_U;
    logic load = uOP.uOP == LB_U | uOP.uOP == LBU_U |
                 uOP.uOP == LH_U | uOP.uOP == LHU_U | uOP.uOP == LW_U;

    GLOBAL  g(  .clk(clk),  .resetn(~rst));
    LSU2WBUFFER         lsu2wb();
    WRAPER2BUFFER       wp2buf();
    WBUFFER2DACCESSOR   wb2da();
    WBUFFER2UHANDLER    wb2uh();
    WBUFFER2RBUFFER     wb2rb();
    LSU2RTALKER         lsu2rt();
    
    assign lsu2wb.req = store & ~addr_err & ~lsu2rt.halt;
    assign lsu2wb.id = uOP.id;
    assign lsu2wb.cache = cache;
    assign lsu2wb.addr = paddr;
    assign lsu2wb.size = size;
    assign lsu2wb.data = oprands.rs1_data;
    assign lsu2wb.com = fireStore;
    assign lsu2wb.rb = ctrl_lsu.flush;
    write_buffer wbuf(g.slave,lsu2wb.wbuf,wp2buf.buffer,wb2da.wbuf,wb2uh.wbuf,wb2rb.wbuf);
    assign w_busy = lsu2wb.busy | lsu2rt.halt;

    LSU2RBUFFER         lsu2rb();
    RBUFFER2DACCESSOR   rb2da();
    RBUFFER2UHANDLER    rb2uh();
    LSU2PRF             lsu2prf();

    assign lsu2rb.valid = load & ~addr_err & ~lsu2rt.halt;
    assign lsu2rb.id = uOP.id;
    assign lsu2rb.cache = cache;
    assign lsu2rb.addr = paddr;
    assign lsu2rb.size = size;
    assign lsu2rb.regid = uOP.op1PAddr;
    read_buffer rbuf(g.slave,lsu2rb.rbuf,wb2rb.rbuf,rb2da.rbuf,wp2bf.buffer,rb2uh.rbuf,lsu2prf.lsu);
    assign r_busy = lsu2rb.busy | lsu2rt.halt;
    assign wbData.rd = lsu2prf.regid;
    assign wbData.wen = lsu2prf.valid;
    assign wbData.wdata = lsu2prf.data;

    MHANDLER2DACCESSOR  mh2da();
    DACCESSOR2WRAPER    da2wp();

    dcache_accessor accessor(mh2da.daccessor,wb2da.accessor,rb2da.accessor,da2wp.daccessor);

    WRAPER2MHANDLER     wp2mh();

    dcache_wraper wraper(g.slave,da2wp.wraper,wp2mh.wraper,wp2buf.wraper);

    DCACHE2MOMERY       dc2mem();
    miss_handler mhandler(g.slave,wp2mh.mhandler,dc2mem.dcache,mh2da.mhandler);
    assign dcacheReq.valid = mh2da.dvalid;
    assign dcacheReq.addr = mh2da.addr;
    assign dcacheReq.write_en = mh2da.wen;
    assign dcacheReq.data = mh2da.ddata;
    assign mh2da.mready = dcacheReq.ready;

    assign mh2da.mvalid = dcacheResp.valid;
    assign mh2da.mdata = dcacheResp.data;
    assign dcacheResp.ready = mh2da.dready;

    UNCACHE2MEMORY      uc2mem();

    uncache_handler uhandler(g.slave,wb2uh.uhandler,rb2uh.uhandler,uc2mem.lsu);
    assign dataReq.valid = uc2mem.uvalid;
    assign dataReq.addr = uc2mem.uaddr;
    assign dataReq.write_en = uc2mem.uwen;
    assign dataReq.data = uc2mem.udata;
    assign dataReq.strobe = uc2mem.ustrobe;
    assign uc2mem.mready = dataReq.ready;

    assign dataResp.ready = uc2mem.uready;
    assign uc2mem.mvalid = dataResp.valid;
    assign uc2mem.mdata = dataResp.data;

    LSU2ROB             lsu2rob();
    rob_talker(g.slave,lsu2rt.talker,lsu2rob.lsu);
    assign lsu2rt.wreq = store & ~w_busy;
    assign lsu2rt.rreq = load & ~r_busy;
    assign lsu2rt.addr_err = addr_err;
    assign lsu2rt.bad_addr = vaddr;
    assign lsu2rt.id = uOP.id;
    assign lsu2rt.rfin = lsu2prf.valid;
    assign lsu2rt.rid = lsu2prf.id;

    assign lsu_commit_reg.setFinish = lsu2rob.valid;
    assign lsu_commit_reg.id = lsu2rob.id;
    assign lsu_commit_reg.setException = lsu2rob.set_ex;
    assign lsu_commit_reg.exceptionType = (lsu2rob.sl == 1'b1) ? ExcAddressErrS : ExcAddressErrL;
    assign lsu_commit_reg.BadVAddr = lsu2rob.bad_addr;
endmodule
