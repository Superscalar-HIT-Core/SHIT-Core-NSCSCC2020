`timescale 1ns / 1ps

module dcache_accessor(
    MHANDLER2DACCESSOR.daccessor    mh2da,
    WBUFFER2DACCESSOR.accessor      wb2da,
    RBUFFER2DACCESSOR.accessor      rb2da,
    DACCESSOR2WRAPER.daccessor      da2wp
    );

    assign mh2da.ready = 1'b1;
    assign rb2da.ready = ~da2wp.l;
    assign wb2da.ready = ~da2wp.l & ~da2wp.r;
    assign da2wp.l = mh2da.valid;
    assign da2wp.r = ~da2wp.l & rb2da.r & rb2da.ready;
    assign da2wp.w = ~da2wp.l & ~rb2da.r & wb2da.w & wb2da.ready;
    assign da2wp.addr = da2wp.l ? {mh2da.addr,4'b0} :
                        da2wp.r ? rb2da.raddr :
                        da2wp.w ? wb2da.waddr : 32'hx;
    assign da2wp.data = da2wp.l ? mh2da.data :
                        da2wp.w ? {96'hx,wb2da.data} : 128'hx;
    assign da2wp.size = da2wp.w ? wb2da.size : rb2da.size;
endmodule
