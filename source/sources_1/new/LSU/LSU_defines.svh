`ifndef LSU_DEFINES
`define LSU_DEFINES 1
typedef enum bit[1:0] {
    s_nil,s_byte,s_half,s_word
} Size;

typedef enum bit[1:0] {
    dop_nil,dop_r,dop_w,dop_l
} Dcache_op;

interface GLOBAL;
    logic   clk;
    logic   resetn;
    modport slave(input clk,resetn);
endinterface

interface WRAPER2DCACHE;
    logic           r;
    logic   [15:0]  wd;
    logic           wt;
    logic   [31:0]  addr;
    logic   [127:0] din;
    logic   [18:0]  tout;
    logic   [127:0] dout;
    logic           hit;
    logic           dirty;
    modport wraper(output r,wd,wt,addr,din, input tout,dout,hit,dirty);
    modport dcache(input r,wd,wt,addr,din, output tout,dout,hit,dirty);
endinterface

interface DACCESSOR2WRAPER;
    logic           r;
    logic           w;
    logic           l;
    Size            size;
    logic   [31:0]  addr;
    logic   [127:0] data;
    modport daccessor(output r,w,l,size,addr,data);
    modport wraper(input r,w,l,size,addr,data);
endinterface

interface WRAPER2MHANDLER;
    Dcache_op       op;
    logic   [31:0]  addr;
    logic   [127:0] data;
    logic           hit;
    logic           dirty;
    logic   [18:0]  tag;
    modport wraper(output op,addr,data,hit,dirty,tag);
    modport mhandler(input op,addr,data,hit,dirty,tag);
endinterface

interface WRAPER2BUFFER;
    Dcache_op       op;
    logic           hit;
    logic   [31:0]  addr;
    logic   [31:0]  data;
    modport wraper(output op,hit,addr,data);
    modport buffer(input op,hit,addr,data);
endinterface

interface WBUFFER2DACCESSOR;
    logic           w;
    logic   [31:0]  waddr;
    Size            size;
    logic   [31:0]  data;
    logic           ready;
    logic           load;
    logic   [27:0]  laddr;
    modport wbuf    (output w,waddr,size,data, input ready,load,laddr);
    modport accessor(input w,waddr,size,data, output ready,load,laddr);
endinterface //WBUFFER2DACCESSOR

interface RBUFFER2DACCESSOR;
    logic           r;
    logic   [31:0]  raddr;
    Size            size;
    logic           ready;
    logic           load;
    logic   [27:0]  laddr;
    modport rbuf    (output r,raddr,size, input ready,load,laddr);
    modport accessor(input r,raddr,size, output ready,load,laddr);
endinterface //RBUFFER2DACCESSOR

interface WBUFFER2UHANDLER;
    logic           w;
    logic   [31:0]  waddr;
    Size            size;
    logic   [31:0]  data;
    logic           ready;
    modport wbuf    (output w,waddr,size,data, input ready);
    modport uhandler(input w,waddr,size,data, output ready);
endinterface //WBUFFER2UHANDLER

interface WBUFFER2RBUFFER;
    logic   [7:0]   rely;
    logic   [7:0]   cur;
    modport wbuf    (output rely,cur);
    modport rbuf    (input rely,cur);
endinterface //WBUFFER2RBUFFER

interface DCACHE2MEMORY;
    logic           dvalid;
    logic   [31:0]  addr;
    logic           wen;
    logic   [127:0] ddata;
    logic           dready;
    logic           mready;
    logic           mvalid;
    logic   [127:0] mdata;
    modport dcache(output dvalid,addr,wen,ddata,dready, input mready,mvalid,mdata);
    modport memory(input dvalid,addr,wen,ddata,dready, output mready,mvalid,mdata);
endinterface //LSU2MEM

interface MHANDLER2DACCESSOR;
    logic           valid;
    logic   [27:0]  addr;
    logic   [127:0] data;
    logic           ready;
    modport mhandler(output valid,addr,data, input ready);
    modport daccessor(input valid,addr,data, output ready);
endinterface //MH2DA

interface LSU2WBUFFER;
    logic           req;
    logic   [6:0]   id;
    logic           cache;
    logic   [31:0]  addr;
    Size            size;
    logic   [31:0]  data;
    logic           com;
    logic           com1;
    logic           rb;
    logic           busy;
    modport lsu(output req,id,cache,addr,size,data,com,com1,rb, input busy);
    modport wbuf(input req,id,cache,addr,size,data,com,com1,rb, output busy);
endinterface

interface LSU2RTALKER;
    logic           wreq;
    logic           rreq;
    logic           addr_err;
    logic   [6:0]   id;
    logic           rfin;
    logic   [6:0]   rid;
    logic   [31:0]  bad_addr;
    logic           halt;
    modport lsu (output wreq,rreq,addr_err,id,rfin,rid,bad_addr, input halt);
    modport talker(input wreq,rreq,addr_err,id,rfin,rid,bad_addr, output halt);
endinterface //LSU2RTALKER

interface LSU2ROB;
    logic           valid;
    logic   [6:0]   id;
    logic           set_ex;
    logic           ls;
    logic   [31:0]  bad_addr;
    modport lsu (output valid,id,set_ex,ls,bad_addr);
    modport rob (input valid,id,set_ex,ls,bad_addr);
endinterface

interface LSU2RBUFFER;
    logic           valid;
    logic   [6:0]   id;
    logic           cache;
    logic   [31:0]  addr;
    Size            size;
    logic           isSigned;
    logic   [5:0]   regid;
    logic           flush;
    logic   [6:0]   rid0;
    logic   [6:0]   rid1;
    logic           valid0;
    logic           commit0;
    logic           busy;
    modport lsu (output valid,regid,cache,addr,size,isSigned,id,flush,rid0,rid1,valid0,commit0, input busy);
    modport rbuf(input valid,regid,cache,addr,size,isSigned,id,flush,rid0,rid1,valid0,commit0, output busy);
endinterface //LSU2RBUFFER

interface LSU2PRF;
    logic           valid;
    logic   [6:0]   id;
    logic   [5:0]   regid;
    logic   [31:0]  data;
    modport lsu (output valid,id,regid,data);
    modport prf (input valid,id,regid,data);
endinterface //LSU2PRF

interface RBUFFER2UHANDLER;
    logic           rvalid;
    logic   [31:0]  raddr;
    Size            rsize;
    logic           rready;
    logic           uready;
    logic           uvalid;
    logic   [31:0]  udata;
    modport rbuf (output rvalid,raddr,rsize,rready, input uready,uvalid,udata);
    modport uhandler (input rvalid,raddr,rsize,rready, output uready,uvalid,udata);
endinterface

interface UNCACHE2MEMORY;
    logic           uvalid;
    logic           uwen;
    logic   [31:0]  uaddr;
    logic   [31:0]  udata;
    logic   [3:0]   ustrobe;
    logic           uready;
    logic           mready;
    logic           mvalid;
    logic   [31:0]  mdata;
    modport lsu (output uvalid,uwen,uaddr,ustrobe,uready,udata, input mready,mvalid,mdata);
    modport memory(input uvalid,uwen,uaddr,ustrobe,uready,udata, output mready,mvalid,mdata);
endinterface
`include "MHandler_defines.svh"
`endif