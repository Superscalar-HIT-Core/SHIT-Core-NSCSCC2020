`timescale 1ns / 1ps
`include "../defs.sv"

//  virtually index, physically tag
//  index : low 10 bit[9:0]
//      128bit/cacheline (16 byte), [3:0] addr in line
//      4-line/group (64 byte), 64 group, [9:4] group address
//  tag : high 22 bit[31:10]

//  age bit :  3 bit for every group
//  age reg :  3 * 64

//  tag     : 21 bit for every line
//  tag ram : 21 * 64 （* 4）

//  data ram: 128 * 64 (* 4)

//  valid   :  1 bit for every line

module ICache(
    input wire clk,
    input wire rst,

    Ctrl.slave          ctrl_iCache,

    Regs_ICache.iCache  regs_iCache,
    ICache_TLB.iCache   iCache_tlb,
    InstReq.iCache      instReq,
    InstResp.iCache     instResp,

    ICache_Regs.iCache  iCache_regs
);
    typedef enum  { sRunning, sBlock, sWaitUnpause, sRecover, sReset } ICacheState;

    typedef struct packed {
        logic           writeEn;
        logic   [ 5:0]  address;
        logic   [20:0]  dataIn;
        logic   [20:0]  dataOut;
    } TagRamIO;

    typedef struct packed {
        logic           writeEn;
        logic  [  5:0]  address;
        logic  [127:0]  dataIn;
        logic  [127:0]  dataOut;
    } DataRamIO;

    TagRamIO    tag0IO,     tag1IO,     tag2IO,     tag3IO;
    DataRamIO   data0IO,    data1IO,    data2IO,    data3IO;
    logic  [31 :0]  PCReg;
    logic  [31 :0]  compInputPC;
    logic           flush;
    logic           delayedFlush;
    InstBundle      inst0;
    InstBundle      inst1;

    logic           collision0;
    logic           collision1;
    logic           collision2;
    logic           collision3;
    logic           requestSent;

    logic  [63 :0]  valid   [3 :0];
    logic  [63 :0]  nxtValid[3 :0];
    logic  [3  :0]  age     [63:0];
    logic  [3  :0]  nxtAge  [63:0];

    logic           hit;
    logic           hit0;
    logic           hit1;
    logic           hit2;
    logic           hit3;
    logic  [20 :0]  tag;
    logic  [5  :0]  lineAddress;
    logic  [127:0]  hitLine;
    logic  [31 :0]  hitInsts[3 :0];

    ICacheState     state, nxtState;

    tag_ram tag0 (
        .clka   (clk            ),
        .wea    (tag0IO.writeEn ),
        .addra  (tag0IO.address ),
        .dina   (tag0IO.dataIn  ),
        .douta  (tag0IO.dataOut ) 
    );

    tag_ram tag1 (
        .clka   (clk            ),
        .wea    (tag1IO.writeEn ),
        .addra  (tag1IO.address ),
        .dina   (tag1IO.dataIn  ),
        .douta  (tag1IO.dataOut ) 
    );

    tag_ram tag2 (
        .clka   (clk            ),
        .wea    (tag2IO.writeEn ),
        .addra  (tag2IO.address ),
        .dina   (tag2IO.dataIn  ),
        .douta  (tag2IO.dataOut ) 
    );

    tag_ram tag3 (
        .clka   (clk            ),
        .wea    (tag3IO.writeEn ),
        .addra  (tag3IO.address ),
        .dina   (tag3IO.dataIn  ),
        .douta  (tag3IO.dataOut ) 
    );

    data_ram_0 data0 (
        .clka   (clk            ),
        .wea    (data0IO.writeEn),
        .addra  (data0IO.address),
        .dina   (data0IO.dataIn ),
        .douta  (data0IO.dataOut)
    );

    data_ram_0 data1 (
        .clka   (clk            ),
        .wea    (data1IO.writeEn),
        .addra  (data1IO.address),
        .dina   (data1IO.dataIn ),
        .douta  (data1IO.dataOut)
    );

    data_ram_0 data2 (
        .clka   (clk            ),
        .wea    (data2IO.writeEn),
        .addra  (data2IO.address),
        .dina   (data2IO.dataIn ),
        .douta  (data2IO.dataOut)
    );

    data_ram_0 data3 (
        .clka   (clk            ),
        .wea    (data3IO.writeEn),
        .addra  (data3IO.address),
        .dina   (data3IO.dataIn ),
        .douta  (data3IO.dataOut)
    );
    
    // misc
    always_ff @ (posedge clk) delayedFlush <= ctrl_iCache.flush;
    assign flush = delayedFlush || ctrl_iCache.flush;
    assign hitInsts[0] = hitLine[31 : 0];
    assign hitInsts[1] = hitLine[63 :32];
    assign hitInsts[2] = hitLine[95 :64];
    assign hitInsts[3] = hitLine[127:96];
    always_ff @ (posedge clk) begin
        collision0          <= tag0IO.address != compInputPC[9:4];
        collision1          <= tag1IO.address != compInputPC[9:4];
        collision2          <= tag2IO.address != compInputPC[9:4];
        collision3          <= tag3IO.address != compInputPC[9:4];
        if(rst) begin
            for (integer i = 0; i < 3; i++) begin
                valid[i]    <= 0;
                age  [i]    <= 0;
            end
            inst0           <= 0;
            inst1           <= 0;
        end else if (ctrl_iCache.pause) begin
            valid           <= valid;
            age             <= age;
            inst0           <= inst0;
            inst1           <= inst1;
        end else begin
            valid           <= nxtValid;
            age             <= nxtAge;
            inst0           <= regs_iCache.inst0;
            inst1           <= regs_iCache.inst1;
        end
    end

    always_ff @ (posedge clk) begin
        if(rst) begin
            requestSent <= `FALSE;
        end else if (state == sRunning && instReq.valid) begin
            requestSent <= `TRUE;
        end else if (state == sBlock || state == sRecover || state == sReset) begin
            requestSent <= `FALSE;
        end else begin
            requestSent <= requestSent;
        end
    end

    // IF-1, reg
    always_ff @ (posedge clk) begin
        if(rst || ctrl_iCache.flush) begin
            PCReg <= 0;
        end else if(ctrl_iCache.pause || ctrl_iCache.pauseReq) begin
            PCReg <= PCReg;
        end else begin
            PCReg <= regs_iCache.PC;
        end
    end

    always_comb begin
        // tag data tlb pause
        if(ctrl_iCache.pause || ctrl_iCache.pauseReq) begin
            compInputPC = PCReg;
        end else begin
            compInputPC = regs_iCache.PC;
        end

        iCache_tlb.virAddr0 = compInputPC & 32'hffff_fffc;
        iCache_tlb.virAddr1 = compInputPC | 32'h0000_0004;
    end

    // IF-2, iCache
    assign hit0         = tag0IO.dataOut == tag && valid[0][lineAddress] && !collision0;
    assign hit1         = tag1IO.dataOut == tag && valid[1][lineAddress] && !collision1;
    assign hit2         = tag2IO.dataOut == tag && valid[2][lineAddress] && !collision2;
    assign hit3         = tag3IO.dataOut == tag && valid[3][lineAddress] && !collision3;
    assign hit          = hit0 || hit1 || hit2 || hit3;
    assign hitLine      =   hit0 ? data0IO.dataOut :
                            hit1 ? data1IO.dataOut :
                            hit2 ? data2IO.dataOut :
                            hit3 ? data3IO.dataOut : instResp.cacheLine;
    assign lineAddress  = PCReg[9 : 4];
    assign tag          = PCReg[31:10];

    always_comb begin
        nxtState = sReset;
        case(state)
            sRunning: begin
                if(rst) begin
                    nxtState = sReset;
                end else if (flush && !instReq.valid && !requestSent) begin
                    nxtState = sRunning;
                end else if(flush && (instReq.valid || requestSent)) begin
                    nxtState = sRecover;
                end else if(ctrl_iCache.pause || hit) begin
                    nxtState = sRunning;
                end else begin
                    nxtState = sBlock;
                end
            end
            sBlock: begin
                if(rst) begin
                    nxtState = sReset;
                end else if (flush && !instResp.valid) begin
                    nxtState = sRecover;
                end else if (flush && instResp.valid) begin
                    nxtState = sRunning;
                end else if (ctrl_iCache.pause && !instResp.valid) begin
                    nxtState = sBlock;
                end else if (ctrl_iCache.pause && instResp.valid) begin
                    nxtState = sWaitUnpause;
                end else if (instResp.valid) begin
                    nxtState = sRunning;
                end else begin
                    nxtState = sBlock;
                end
            end
            sRecover: begin
                if(rst) begin
                    nxtState = sReset;
                end else if(instResp.valid) begin
                    nxtState = sRunning;
                end else begin
                    nxtState = sRecover;
                end
            end
            sWaitUnpause:begin
                if(rst) begin
                    nxtState = sReset;
                end else if(flush) begin
                    nxtState = sRunning;
                end else if(!ctrl_iCache.pause) begin
                    nxtState = sRunning;
                end else begin
                    nxtState = sWaitUnpause;
                end
            end
            sReset: begin
                if(rst) begin
                    nxtState = sReset;
                end else begin
                    nxtState = sRunning;
                end
            end
        endcase
    end

    always_ff @ (posedge clk) begin
        state <= nxtState;
    end

    always_comb begin
        ctrl_iCache.pauseReq    = `FALSE;
        instReq.valid           = `FALSE;
        instResp.ready          = `FALSE;
        instReq.pc              = `FALSE;
        
        nxtValid                    = valid;
        nxtAge                      = age;

        iCache_regs.inst0           = 0;
        iCache_regs.inst1           = 0;
        iCache_regs.inst0.nlpInfo   = inst0.nlpInfo;
        iCache_regs.inst1.nlpInfo   = inst1.nlpInfo;
        iCache_regs.inst0.pc        = PCReg & 32'hffff_fffc;
        iCache_regs.inst1.pc        = PCReg | 32'h0000_0004;
        
        tag0IO.address              = compInputPC[9:4];
        tag1IO.address              = compInputPC[9:4];
        tag2IO.address              = compInputPC[9:4];
        tag3IO.address              = compInputPC[9:4];
        
        tag0IO.dataIn               = 0;
        tag1IO.dataIn               = 0;
        tag2IO.dataIn               = 0;
        tag3IO.dataIn               = 0;

        tag0IO.writeEn              = `FALSE;
        tag1IO.writeEn              = `FALSE;
        tag2IO.writeEn              = `FALSE;
        tag3IO.writeEn              = `FALSE;
        data0IO.dataIn              = 0;
        data1IO.dataIn              = 0;
        data2IO.dataIn              = 0;
        data3IO.dataIn              = 0;

        data0IO.address             = compInputPC[9:4];
        data1IO.address             = compInputPC[9:4];
        data2IO.address             = compInputPC[9:4];
        data3IO.address             = compInputPC[9:4];

        data0IO.writeEn             = `FALSE;
        data1IO.writeEn             = `FALSE;
        data2IO.writeEn             = `FALSE;
        data3IO.writeEn             = `FALSE;
        case(state)
            sRunning: begin
                if(hit) begin
                    iCache_regs.inst0.valid = ~PCReg[2] && !flush;
                    iCache_regs.inst0.inst  = hitInsts[{PCReg[3], 1'b0}];
                    iCache_regs.inst0.pc    = PCReg & 32'hffff_fffc;

                    iCache_regs.inst1.valid = !regs_iCache.onlyGetDS && !flush;
                    iCache_regs.inst1.inst  = hitInsts[{PCReg[3], 1'b1}];
                    iCache_regs.inst1.pc    = PCReg | 32'h0000_0004;
                    ctrl_iCache.pauseReq    = `FALSE;
                    instReq.valid           = `FALSE;
                    instResp.ready          = `FALSE;

                    if(hit0) begin
                        nxtAge[lineAddress][0] = 1'b0;
                        nxtAge[lineAddress][1] = 1'b0;
                    end else if(hit1) begin
                        nxtAge[lineAddress][0] = 1'b0;
                        nxtAge[lineAddress][1] = 1'b1;
                    end else if(hit2) begin
                        nxtAge[lineAddress][0] = 1'b1;
                        nxtAge[lineAddress][2] = 1'b0;
                    end else if(hit3) begin
                        nxtAge[lineAddress][0] = 1'b1;
                        nxtAge[lineAddress][2] = 1'b1;
                    end
                end else begin
                    iCache_regs.inst0.valid = `FALSE;
                    iCache_regs.inst1.valid = `FALSE;
                    ctrl_iCache.pauseReq    = `TRUE;
                    instReq.valid           = ~requestSent;
                    instReq.pc              = iCache_tlb.phyAddr0 & 32'hffff_fffc;
                    instResp.ready          = `TRUE;
                end
            end
            sBlock: begin
                instReq.valid               = `FALSE;
                instResp.ready              = `TRUE;
                if(instResp.valid) begin
                    ctrl_iCache.pauseReq    = `FALSE;
                    
                    iCache_regs.inst0.valid = ~PCReg[2] && !flush;
                    iCache_regs.inst0.inst  = hitInsts[{PCReg[3], 1'b0}];
                    iCache_regs.inst0.pc    = PCReg & 32'hffff_fffc;

                    iCache_regs.inst1.valid = !regs_iCache.onlyGetDS && !flush;
                    iCache_regs.inst1.inst  = hitInsts[{PCReg[3], 1'b1}];
                    iCache_regs.inst1.pc    = PCReg | 32'h0000_0004;

                    casex (age[lineAddress])
                        3'b?11: begin   // replace hit0
                            tag0IO.writeEn          = `TRUE;
                            tag0IO.address          = lineAddress;
                            tag0IO.dataIn           = tag;
                            data0IO.writeEn         = `TRUE;
                            data0IO.address         = lineAddress;
                            data0IO.dataIn          = instResp.cacheLine;
                            nxtAge[lineAddress][0]  = 1'b0;
                            nxtAge[lineAddress][1]  = 1'b0;
                            nxtValid[0][lineAddress]   = `TRUE;
                        end
                        3'b?01: begin   // replace hit1
                            tag1IO.writeEn          = `TRUE;
                            tag1IO.address          = lineAddress;
                            tag1IO.dataIn           = tag;
                            data1IO.writeEn         = `TRUE;
                            data1IO.address         = lineAddress;
                            data1IO.dataIn          = instResp.cacheLine;
                            nxtAge[lineAddress][0]  = 1'b0;
                            nxtAge[lineAddress][1]  = 1'b1;
                            nxtValid[1][lineAddress]   = `TRUE;
                        end
                        3'b1?0: begin   // replace hit2
                            tag2IO.writeEn          = `TRUE;
                            tag2IO.address          = lineAddress;
                            tag2IO.dataIn           = tag;
                            data2IO.writeEn         = `TRUE;
                            data2IO.address         = lineAddress;
                            data2IO.dataIn          = instResp.cacheLine;
                            nxtAge[lineAddress][0]  = 1'b1;
                            nxtAge[lineAddress][2]  = 1'b0;
                            nxtValid[2][lineAddress]   = `TRUE;
                        end
                        3'b0?0: begin   // replace hit3
                            tag3IO.writeEn          = `TRUE;
                            tag3IO.address          = lineAddress;
                            tag3IO.dataIn           = tag;
                            data3IO.writeEn         = `TRUE;
                            data3IO.address         = lineAddress;
                            data3IO.dataIn          = instResp.cacheLine;
                            nxtAge[lineAddress][0]  = 1'b1;
                            nxtAge[lineAddress][2]  = 1'b1;
                            nxtValid[3][lineAddress]   = `TRUE;
                        end
                    endcase
                end else begin
                    ctrl_iCache.pauseReq        = `TRUE;
                    iCache_regs.inst0.valid     = `FALSE;
                    iCache_regs.inst1.valid     = `FALSE;
                end
            end
            sRecover: begin
                instReq.valid                   = `FALSE;
                instResp.ready                  = `TRUE;
                ctrl_iCache.pauseReq            = `TRUE;
                
                if(instResp.valid) begin
                    ctrl_iCache.pauseReq        = `FALSE;
                    iCache_regs.inst0.valid     = `FALSE;
                    iCache_regs.inst1.valid     = `FALSE;
                end else begin
                    ctrl_iCache.pauseReq        = `TRUE;
                    iCache_regs.inst0.valid     = `FALSE;
                    iCache_regs.inst1.valid     = `FALSE;
                end
            end
            sWaitUnpause: begin
                ctrl_iCache.pauseReq            = `FALSE;
                instReq.valid                   = `FALSE;
                instResp.ready                  = `FALSE;
                
                iCache_regs.inst0.valid         = ~PCReg[2] && !flush;
                iCache_regs.inst0.inst          = hitInsts[{PCReg[3], 1'b0}];
                iCache_regs.inst0.pc            = PCReg & 32'hffff_fffc;

                iCache_regs.inst1.valid         = !regs_iCache.onlyGetDS && !flush;
                iCache_regs.inst1.inst          = hitInsts[{PCReg[3], 1'b1}];
                iCache_regs.inst1.pc            = PCReg | 32'h0000_0004;
            end
            sReset: begin
                iCache_regs.inst0.valid         = `FALSE;
                iCache_regs.inst1.valid         = `FALSE;
            end
        endcase
    end

endmodule
