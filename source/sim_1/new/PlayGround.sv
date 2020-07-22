`timescale 1ns / 1ps

module PlayGround(

    );
    assign cpu.lsuWBOut = 0;
    // AXIReadAddr     axiReadAddr();
    // AXIReadData     axiReadData();
    // AXIWriteAddr    axiWriteAddr();
    // AXIWriteData    axiWriteData();
    // AXIWriteResp    axiWriteResp();

    // InstReq         instReq();
    // InstResp        instResp();
    // DataReq         dataReq();
    // DataResp        dataResp();

    // DCacheReq       dCacheReq();
    // DCacheResp      dCacheResp();

    // Ctrl                ctrl_if0_1_regs();
    // Ctrl                ctrl_nlp();
    // Ctrl                ctrl_if2_3_regs();
    // Ctrl                ctrl_iCache();
    // Ctrl                ctrl_if3();
    // Ctrl                ctrl_if3_output_regs();
    // Ctrl                ctrl_instBuffer();

    // ICache_TLB          iCache_tlb();

    // BackendRedirect     backend_if0();
    // BPDUpdate           backend_bpd();
    // NLPUpdate           backend_nlp();

    // IFU_InstBuffer      ifu_instBuffer();
    // InstBuffer_Backend  instBuffer_backend();


    logic clk;
    logic rst;

    wire          rsta_busy      ;
    wire          rstb_busy      ;
    wire          s_aclk         ;
    wire          s_aresetn      ;
    wire  [ 3:0]  s_axi_awid     ;
    wire  [31:0]  s_axi_awaddr   ;
    wire  [ 7:0]  s_axi_awlen    ;
    wire  [ 2:0]  s_axi_awsize   ;
    wire  [ 1:0]  s_axi_awburst  ;
    wire          s_axi_awvalid  ;
    wire          s_axi_awready  ;
    wire  [31:0]  s_axi_wdata    ;
    wire  [ 3:0]  s_axi_wstrb    ;
    wire          s_axi_wlast    ;
    wire          s_axi_wvalid   ;
    wire          s_axi_wready   ;
    wire  [ 3:0]  s_axi_bid      ;
    wire  [ 1:0]  s_axi_bresp    ;
    wire          s_axi_bvalid   ;
    wire          s_axi_bready   ;
    wire  [ 3:0]  s_axi_arid     ;
    wire  [31:0]  s_axi_araddr   ;
    wire  [ 7:0]  s_axi_arlen    ;
    wire  [ 2:0]  s_axi_arsize   ;
    wire  [ 1:0]  s_axi_arburst  ;
    wire          s_axi_arvalid  ;
    wire          s_axi_arready  ;
    wire  [ 3:0]  s_axi_rid      ;
    wire  [31:0]  s_axi_rdata    ;
    wire  [ 1:0]  s_axi_rresp    ;
    wire          s_axi_rlast    ;
    wire          s_axi_rvalid   ;
    wire          s_axi_rready   ;

    // AXIInterface        axiInterface(.*);
    // AXIWarp             AXIWarp(.*);
    // // axi_test_blk_mem    axi_mem(.*);
    // CtrlUnit            ctrlUnit(.*);
    // IFU                 ifu(.*);
    // InstBuffer          instBuffer(.*);

    MyCPU cpu(.*);

    always #10 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        #25
        rst = 1'b0;

        // dataReq.sendWReq(32'h00000110, 32'h0, clk);
        // dataReq.sendWReq(32'h00000114, 32'h1, clk);
        // dataReq.sendWReq(32'h00000118, 32'h2, clk);
        // dataReq.sendWReq(32'h0000011C, 32'h3, clk);
        // dataReq.sendWReq(32'h00000120, 32'h4, clk);
        // dataReq.sendWReq(32'h00000124, 32'h5, clk);
        // dataReq.sendWReq(32'h00000128, 32'h6, clk);
        // dataReq.sendWReq(32'h0000012C, 32'h7, clk);
        // dataReq.sendWReq(32'h00000130, 32'h8, clk);
        // dataReq.sendWReq(32'h00000134, 32'h9, clk);
        // dataReq.sendWReq(32'h00000138, 32'ha, clk);
        // dataReq.sendWReq(32'h0000013C, 32'hb, clk);
        // dataReq.sendWReq(32'h00000140, 32'hc, clk);
        // dataReq.sendWReq(32'h00000144, 32'hd, clk);
        // dataReq.sendWReq(32'h00000148, 32'he, clk);
        // dataReq.sendWReq(32'h0000014C, 32'hf, clk);
        #5000
        // backend_if0.redirectReq(32'h00000114, clk);
        // #1000
        $stop(1);
    end

    initial begin
        forever cpu.iCache_tlb.autoReply(clk);
    end

    initial begin
        #9;
        forever begin
            integer b = $random % 4;
            while (b --> 0) #20;
            //cpu.instBuffer_backend.getResp(clk);
        end
    end

    initial begin
        //if0_regs.fakeIF0(32'h00000000, clk);
        //if0_regs.fakeIF0(32'h00000010, clk);
        //if0_regs.fakeIF0(32'h00000018, clk);
        //if0_regs.fakeIF0(32'h00000020, clk);
        //if0_regs.fakeIF0(32'h00000028, clk);
    end

    axi_test_blk_mem axi_mem (
        .rsta_busy(rsta_busy),          // output wire rsta_busy
        .rstb_busy(rstb_busy),          // output wire rstb_busy
        .s_aclk(s_aclk),                // input wire s_aclk
        .s_aresetn(s_aresetn),          // input wire s_aresetn
        .s_axi_awid(s_axi_awid),        // input wire [3 : 0] s_axi_awid
        .s_axi_awaddr(s_axi_awaddr),    // input wire [31 : 0] s_axi_awaddr
        .s_axi_awlen(s_axi_awlen),      // input wire [7 : 0] s_axi_awlen
        .s_axi_awsize(s_axi_awsize),    // input wire [2 : 0] s_axi_awsize
        .s_axi_awburst(s_axi_awburst),  // input wire [1 : 0] s_axi_awburst
        .s_axi_awvalid(s_axi_awvalid),  // input wire s_axi_awvalid
        .s_axi_awready(s_axi_awready),  // output wire s_axi_awready
        .s_axi_wdata(s_axi_wdata),      // input wire [31 : 0] s_axi_wdata
        .s_axi_wstrb(s_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
        .s_axi_wlast(s_axi_wlast),      // input wire s_axi_wlast
        .s_axi_wvalid(s_axi_wvalid),    // input wire s_axi_wvalid
        .s_axi_wready(s_axi_wready),    // output wire s_axi_wready
        .s_axi_bid(s_axi_bid),          // output wire [3 : 0] s_axi_bid
        .s_axi_bresp(s_axi_bresp),      // output wire [1 : 0] s_axi_bresp
        .s_axi_bvalid(s_axi_bvalid),    // output wire s_axi_bvalid
        .s_axi_bready(s_axi_bready),    // input wire s_axi_bready
        .s_axi_arid(s_axi_arid),        // input wire [3 : 0] s_axi_arid
        .s_axi_araddr(s_axi_araddr),    // input wire [31 : 0] s_axi_araddr
        .s_axi_arlen(s_axi_arlen),      // input wire [7 : 0] s_axi_arlen
        .s_axi_arsize(s_axi_arsize),    // input wire [2 : 0] s_axi_arsize
        .s_axi_arburst(s_axi_arburst),  // input wire [1 : 0] s_axi_arburst
        .s_axi_arvalid(s_axi_arvalid),  // input wire s_axi_arvalid
        .s_axi_arready(s_axi_arready),  // output wire s_axi_arready
        .s_axi_rid(s_axi_rid),          // output wire [3 : 0] s_axi_rid
        .s_axi_rdata(s_axi_rdata),      // output wire [31 : 0] s_axi_rdata
        .s_axi_rresp(s_axi_rresp),      // output wire [1 : 0] s_axi_rresp
        .s_axi_rlast(s_axi_rlast),      // output wire s_axi_rlast
        .s_axi_rvalid(s_axi_rvalid),    // output wire s_axi_rvalid
        .s_axi_rready(s_axi_rready)    // input wire s_axi_rready
    );
endmodule