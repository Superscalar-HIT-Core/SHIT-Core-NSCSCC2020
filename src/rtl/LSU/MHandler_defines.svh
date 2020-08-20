`ifndef MISS_HANDLER_DEFINES
`define MISS_HANDLER_DEFINES 1

interface MH2WBH;
    logic           valid;
    logic   [27:0]  addr;
    logic   [127:0] data;
    logic           ready;
    logic           busy;
    modport mhandler(output valid,addr,data, input ready,busy);
    modport wbhandler(input valid,addr,data, output ready,busy);
endinterface //WBHI

interface MH2LH;
    logic           valid;
    logic   [27:0]  addr;
    logic           ready;
    logic           busy;
    modport mhandler (output valid,addr, input ready,busy);
    modport lhandler (input valid,addr, output ready,busy);
endinterface

interface MH2ML;
    logic   [27:0]  addr;
    logic           received;
    modport mhandler (output addr, input received);
    modport mlistener(input addr, output received);
endinterface //MH2ML

typedef struct packed{
    logic           valid;
    logic           wb;
    logic           issued;
    logic   [27:0]  addr;
    logic   [127:0] data;
    logic   [18:0]  tag;
}MSHR_LINE;

`define MSHRROW 7:0
`define MSHRPOINTER 2:0

`endif