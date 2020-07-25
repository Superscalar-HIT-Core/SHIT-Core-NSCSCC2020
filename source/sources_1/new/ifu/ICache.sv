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
    typedef enum { sStartUp, sRunning, sBlock, sWaitUnpause, sReset, sRecovery } ICacheState;

    typedef struct packed {
        logic           clk;
        logic           writeEn;
        logic   [ 5:0]  address;
        logic   [20:0]  dataIn;
        logic   [20:0]  dataOut;
    } TagRamIO;

    typedef struct packed {
        logic           clk;
        logic           writeEn;
        logic  [  5:0]  address;
        logic  [127:0]  dataIn;
        logic  [127:0]  dataOut;
    } DataRamIO;


    ICacheState     state, nextState, lastState;
    logic [31:0]    delayPC;
    logic           hit;
    logic [ 5:0]    lineAddress, delayLineAddr;
    logic [21:0]    tag, preservedTag, writeBackTag;
    logic [21:0]    tagOut0;
    logic [21:0]    tagOut1;
    logic [21:0]    tagOut2;
    logic [21:0]    tagOut3;

    logic [ 63:0]   valid   [ 3:0];
    logic [ 63:0]   nxtvalid[ 3:0];
    logic [127:0]   hitLine;
    logic [127:0]   waitUnpauseRes;
    logic [ 31:0]   insts   [ 3:0];
    logic [  3:0]   age     [63:0];
    logic [  1:0]   writeSel;
    logic           lastPause;
    logic           pauseDiscard;
    logic           delayOnlyGetDS;
    logic           lastTag0Collision;
    logic           lastTag1Collision;
    logic           lastTag2Collision;
    logic           lastTag3Collision;

    logic [  1:0]   pendingCounter;
    logic [  1:0]   nxtPendingCounter;
    logic           pendingResp;

    TagRamIO    tag0IO,     tag1IO,     tag2IO,     tag3IO;
    DataRamIO   data0IO,    data1IO,    data2IO,    data3IO;

    tag_ram tag0 (
        .clka   (tag0IO.clk     ),
        .wea    (tag0IO.writeEn ),
        .addra  (tag0IO.address ),
        .dina   (tag0IO.dataIn  ),
        .douta  (tag0IO.dataOut ) 
    );

    tag_ram tag1 (
        .clka   (tag1IO.clk     ),
        .wea    (tag1IO.writeEn ),
        .addra  (tag1IO.address ),
        .dina   (tag1IO.dataIn  ),
        .douta  (tag1IO.dataOut ) 
    );

    tag_ram tag2 (
        .clka   (tag2IO.clk     ),
        .wea    (tag2IO.writeEn ),
        .addra  (tag2IO.address ),
        .dina   (tag2IO.dataIn  ),
        .douta  (tag2IO.dataOut ) 
    );

    tag_ram tag3 (
        .clka   (tag3IO.clk     ),
        .wea    (tag3IO.writeEn ),
        .addra  (tag3IO.address ),
        .dina   (tag3IO.dataIn  ),
        .douta  (tag3IO.dataOut ) 
    );

    data_ram_0 data0 (
        .clka   (data0IO.clk    ),
        .wea    (data0IO.writeEn),
        .addra  (data0IO.address),
        .dina   (data0IO.dataIn ),
        .douta  (data0IO.dataOut)
    );

    data_ram_0 data1 (
        .clka   (data1IO.clk    ),
        .wea    (data1IO.writeEn),
        .addra  (data1IO.address),
        .dina   (data1IO.dataIn ),
        .douta  (data1IO.dataOut)
    );

    data_ram_0 data2 (
        .clka   (data2IO.clk    ),
        .wea    (data2IO.writeEn),
        .addra  (data2IO.address),
        .dina   (data2IO.dataIn ),
        .douta  (data2IO.dataOut)
    );

    data_ram_0 data3 (
        .clka   (data3IO.clk    ),
        .wea    (data3IO.writeEn),
        .addra  (data3IO.address),
        .dina   (data3IO.dataIn ),
        .douta  (data3IO.dataOut)
    );

    assign iCache_tlb.virAddr0  =   regs_iCache.PC & 32'hffff_fffc;
    assign iCache_tlb.virAddr1  =   regs_iCache.PC | 32'h0000_0004;
    assign lineAddress          =   regs_iCache.PC[9:4];
    assign tag                  =   iCache_tlb.phyAddr0[31:10];
    assign hit                  =   (preservedTag == tag0IO.dataOut && valid[0][delayLineAddr] && !lastTag0Collision) ||
                                    (preservedTag == tag1IO.dataOut && valid[1][delayLineAddr] && !lastTag1Collision) ||
                                    (preservedTag == tag2IO.dataOut && valid[2][delayLineAddr] && !lastTag2Collision) ||
                                    (preservedTag == tag3IO.dataOut && valid[3][delayLineAddr] && !lastTag3Collision);

    assign insts[0]             =   hitLine[ 31: 0];
    assign insts[1]             =   hitLine[ 63:32];
    assign insts[2]             =   hitLine[ 95:64];
    assign insts[3]             =   hitLine[127:96];

    assign tag0IO.clk   = clk;
    assign tag1IO.clk   = clk;
    assign tag2IO.clk   = clk;
    assign tag3IO.clk   = clk;

    assign data0IO.clk  = clk;
    assign data1IO.clk  = clk;
    assign data2IO.clk  = clk;
    assign data3IO.clk  = clk;

    assign iCache_regs.overrun = ctrl_iCache.pause;

    always_ff @ (posedge clk) lastPause = ctrl_iCache.pause;

    assign pauseDiscard = lastPause && !ctrl_iCache.pause;
    
    always_ff @ (posedge clk) begin
        lastTag0Collision <= tag0IO.address != lineAddress;
        lastTag1Collision <= tag1IO.address != lineAddress;
        lastTag2Collision <= tag2IO.address != lineAddress;
        lastTag3Collision <= tag3IO.address != lineAddress;
    end

    always_comb begin
        if(state == sBlock && instResp.valid)                           hitLine = instResp.cacheLine;
        else if(state == sWaitUnpause)                                  hitLine = waitUnpauseRes;
        else if(preservedTag == tag0IO.dataOut && valid[0][delayLineAddr] && !lastTag0Collision)  hitLine = data0IO.dataOut;
        else if(preservedTag == tag1IO.dataOut && valid[1][delayLineAddr] && !lastTag1Collision)  hitLine = data1IO.dataOut;
        else if(preservedTag == tag2IO.dataOut && valid[2][delayLineAddr] && !lastTag2Collision)  hitLine = data2IO.dataOut;
        else if(preservedTag == tag3IO.dataOut && valid[3][delayLineAddr] && !lastTag3Collision)  hitLine = data3IO.dataOut;
        else hitLine = 128'hffffffff_ffffffff_ffffffff_ffffffff;
    end

    always_ff @ (posedge clk) begin
        if (rst || ctrl_iCache.flush) begin
            writeBackTag <= 0;
        end else if(state == sBlock) begin
            writeBackTag <= writeBackTag;
        end else if(lastState == sStartUp && state == sRunning || lastState == sRunning) begin
            writeBackTag <= tag;
        end
    end

    assign preservedTag = (lastState == sStartUp && state == sRunning || lastState == sBlock && state == sStartUp) ? tag : writeBackTag;

    always_ff @ (posedge clk) begin
        if(rst) begin
            pendingCounter <= 0;
        end else begin
            pendingCounter <= nxtPendingCounter;
        end
    end

    always_ff @ (posedge clk) begin
        if (state == sBlock && instResp.valid && ctrl_iCache.pause) begin
            waitUnpauseRes <= instResp.cacheLine;
        end
    end

    assign pendingResp = nxtPendingCounter != 2'b00;
    assign nxtPendingCounter = instReq.valid ? pendingCounter + 1 : (instResp.valid ? pendingCounter - 1 : pendingCounter);

    always_ff @ (posedge clk) delayOnlyGetDS <= regs_iCache.onlyGetDS;

    always_comb begin
        nextState = sReset;
        case(state)
            sStartUp: begin
                if(rst) begin
                    nextState = sReset;
                end else if(ctrl_iCache.flush) begin
                    nextState = sRecovery;
                end else if(ctrl_iCache.pause) begin
                    nextState = sStartUp;
                end else begin
                    nextState = sRunning;
                end
            end
            sRunning: begin
                if(rst) begin
                    nextState = sReset;
                end else if(ctrl_iCache.flush) begin
                    nextState = sRecovery;
                end else if(ctrl_iCache.pause) begin
                    nextState = sRunning;
                end else if(hit) begin
                    nextState = sRunning;
                end else if(instReq.ready) begin
                    nextState = sBlock;
                end else begin
                    nextState = sRunning;
                end
            end
            sBlock: begin
                if(rst) begin
                    nextState = sReset;
                end else if(ctrl_iCache.flush) begin
                    nextState = sRecovery;
                end else if (instResp.valid && ctrl_iCache.pause) begin
                    nextState = sWaitUnpause;
                end else if(ctrl_iCache.pause) begin
                    nextState = sBlock;
                end else if(instResp.valid) begin
                    nextState = sStartUp;
                end else begin
                    nextState = sBlock;
                end
            end
            sWaitUnpause: begin
                if(rst || ctrl_iCache.flush) begin
                    nextState = sReset;
                end else if(ctrl_iCache.pause) begin
                    nextState = sWaitUnpause;
                end else begin
                    nextState = sStartUp;
                end
            end
            sRecovery: begin
                if(rst) begin
                    nextState = sReset;
                end else if(ctrl_iCache.pause) begin
                    nextState = sRecovery;
                end else if(instResp.valid || !pendingResp || hit) begin
                    nextState = sStartUp;
                end else begin
                    nextState = sRecovery;
                end
            end
            sReset: begin
                if(rst || ctrl_iCache.flush) begin
                    nextState = sReset;
                end else begin
                    nextState = sStartUp;
                end
            end
        endcase
    end

    always_ff @ (posedge clk) begin
        state           <= nextState;
        lastState       <= state;
        if (rst) begin
            valid[0] = 0;
            valid[1] = 0;
            valid[2] = 0;
            valid[3] = 0;
        end else if (state != sBlock) begin
            valid[0] = valid[0];
            valid[1] = valid[1];
            valid[2] = valid[2];
            valid[3] = valid[3];
        end else if(!valid[0][delayLineAddr] && instResp.valid) begin
            valid[0][delayLineAddr] = `TRUE;
        end else if(!valid[1][delayLineAddr] && instResp.valid) begin
            valid[1][delayLineAddr] = `TRUE;
        end else if(!valid[2][delayLineAddr] && instResp.valid) begin
            valid[2][delayLineAddr] = `TRUE;
        end else if(!valid[3][delayLineAddr] && instResp.valid) begin
            valid[3][delayLineAddr] = `TRUE;
        end
        
        if(nextState == sReset) begin
            delayPC         <= 32'h0000_0000;
            delayLineAddr   <= 6'h00_0000;
        end else if(ctrl_iCache.pause) begin
            delayPC         <= delayPC;
            delayLineAddr   <= delayLineAddr;
        end else if(nextState == sStartUp || (nextState == sRunning && hit)) begin
            delayPC         <= regs_iCache.PC;
            delayLineAddr   <= lineAddress;
        end else begin
            delayPC         <= delayPC;
            delayLineAddr   <= delayLineAddr;
        end
    end

    always_ff @ (posedge clk) begin
        if(rst) begin
            for(integer i = 0; i < 64; i++) begin
                age[i]      = 3'b000;
            end
        end else if(tag == tag0IO.dataOut && valid[0][delayLineAddr]) begin
            age[delayLineAddr][2]   = 1'b1; 
            age[delayLineAddr][0]   = 1'b1; 
        end else if(tag == tag1IO.dataOut && valid[1][delayLineAddr]) begin
            age[delayLineAddr][2]   = 1'b1; 
            age[delayLineAddr][0]   = 1'b0; 
        end else if(tag == tag2IO.dataOut && valid[2][delayLineAddr]) begin
            age[delayLineAddr][2]   = 1'b0; 
            age[delayLineAddr][1]   = 1'b1; 
        end else if(tag == tag3IO.dataOut && valid[3][delayLineAddr]) begin
            age[delayLineAddr][2]   = 1'b0; 
            age[delayLineAddr][1]   = 1'b0; 
        end
    end

    InstBundle delayInst0;
    InstBundle delayInst1;

    always_ff @ (posedge clk) begin
        delayInst0 <= regs_iCache.inst0;
        delayInst1 <= regs_iCache.inst1;
    end

    always_comb begin
        iCache_regs.inst0.nlpInfo   = delayInst0.nlpInfo;
        iCache_regs.inst1.nlpInfo   = delayInst1.nlpInfo;
        ctrl_iCache.pauseReq        = `FALSE;
        instReq.valid               = `FALSE;
        instResp.ready              = `FALSE;

        tag0IO.writeEn              = `FALSE;
        tag1IO.writeEn              = `FALSE;
        tag2IO.writeEn              = `FALSE;
        tag3IO.writeEn              = `FALSE;

        tag3IO.address              = lineAddress;
        tag0IO.address              = lineAddress;
        tag1IO.address              = lineAddress;
        tag2IO.address              = lineAddress;

        tag3IO.dataIn               = 0;
        tag0IO.dataIn               = 0;
        tag1IO.dataIn               = 0;
        tag2IO.dataIn               = 0;
    
        data0IO.writeEn             = `FALSE;
        data1IO.writeEn             = `FALSE;
        data2IO.writeEn             = `FALSE;
        data3IO.writeEn             = `FALSE;
        
        data3IO.address             = lineAddress;
        data0IO.address             = lineAddress;
        data1IO.address             = lineAddress;
        data2IO.address             = lineAddress;
        
        data3IO.dataIn              = 0;
        data0IO.dataIn              = 0;
        data1IO.dataIn              = 0;
        data2IO.dataIn              = 0;
        case(state)
            sStartUp: begin
                instReq.valid                   = `FALSE;
                instResp.ready                  = `FALSE;
                ctrl_iCache.pauseReq            = !hit && lastState != sRecovery;
                
                iCache_regs.inst0.pc            = delayPC & 32'hffff_fffc;
                iCache_regs.inst0.valid         = ~delayPC[2] && (delayPC != regs_iCache.PC) && !pauseDiscard && hit && lastState != sRecovery;
                iCache_regs.inst0.inst          = insts[{delayPC[3], 1'b0}];

                iCache_regs.inst1.pc            = delayPC | 32'h0000_0004;
                iCache_regs.inst1.valid         = !pauseDiscard && (delayPC != regs_iCache.PC) && !delayOnlyGetDS && hit && lastState != sRecovery;
                iCache_regs.inst1.inst          = insts[{delayPC[3], 1'b1}];
            end
            sRunning: begin
                if(hit) begin
                    instReq.valid               = `FALSE;
                    instResp.ready              = `FALSE;
                    ctrl_iCache.pauseReq        = `FALSE;
                    
                    iCache_regs.inst0.pc        = delayPC & 32'hffff_fffc;
                    iCache_regs.inst0.valid     = ~delayPC[2] && !pauseDiscard;
                    iCache_regs.inst0.inst      = insts[{delayPC[3], 1'b0}];

                    iCache_regs.inst1.pc        = delayPC | 32'h0000_0004;
                    iCache_regs.inst1.valid     = !pauseDiscard && !delayOnlyGetDS;
                    iCache_regs.inst1.inst      = insts[{delayPC[3], 1'b1}];
                end else begin
                    instReq.valid               = `TRUE;
                    instResp.ready              = `FALSE;
                    instReq.pc                  = delayPC & 32'hffff_fff0;
                    ctrl_iCache.pauseReq        = `TRUE;
                    iCache_regs.inst0.valid     = `FALSE;
                    iCache_regs.inst1.valid     = `FALSE;
                end
            end
            sBlock: begin
                instReq.valid               = `FALSE;
                instResp.ready              = `TRUE;
                
                ctrl_iCache.pauseReq        = ~instResp.valid;

                if(instResp.valid) begin
                    priority if(!valid[0][delayLineAddr]) begin
                        writeSel = 2'b00;
                    end else if(!valid[1][delayLineAddr]) begin
                        writeSel = 2'b01;
                    end else if(!valid[2][delayLineAddr]) begin
                        writeSel = 2'b10;
                    end else if(!valid[3][delayLineAddr]) begin
                        writeSel = 2'b11;
                    end else begin
                        priority casex (age[delayLineAddr])
                            3'b0?0: begin
                                writeSel = 2'b00;
                            end
                            3'b0?1: begin
                                writeSel = 2'b01;
                            end
                            3'b10?: begin
                                writeSel = 2'b10;
                            end
                            3'b11?: begin
                                writeSel = 2'b11;
                            end
                            default: begin
                                writeSel = 2'b00;
                            end
                        endcase
                    end

                    case(writeSel)
                        2'b00: begin
                            tag0IO.writeEn      = `TRUE;
                            tag0IO.address      = delayLineAddr;
                            tag0IO.dataIn       = writeBackTag;
                    
                            data0IO.writeEn     = `TRUE;
                            data0IO.address     = delayLineAddr;
                            data0IO.dataIn      = instResp.cacheLine;
                        end
                        2'b01: begin
                            tag1IO.writeEn      = `TRUE;
                            tag1IO.address      = delayLineAddr;
                            tag1IO.dataIn       = writeBackTag;
                    
                            data1IO.writeEn     = `TRUE;
                            data1IO.address     = delayLineAddr;
                            data1IO.dataIn      = instResp.cacheLine;
                        end
                        2'b10: begin
                            tag2IO.writeEn      = `TRUE;
                            tag2IO.address      = delayLineAddr;
                            tag2IO.dataIn       = writeBackTag;
                    
                            data2IO.writeEn     = `TRUE;
                            data2IO.address     = delayLineAddr;
                            data2IO.dataIn      = instResp.cacheLine;
                        end
                        2'b11: begin
                            tag3IO.writeEn      = `TRUE;
                            tag3IO.address      = delayLineAddr;
                            tag3IO.dataIn       = writeBackTag;
                    
                            data3IO.writeEn     = `TRUE;
                            data3IO.address     = delayLineAddr;
                            data3IO.dataIn      = instResp.cacheLine;
                        end
                    endcase
                    if(delayPC != regs_iCache.PC) begin
                        iCache_regs.inst0.pc    = delayPC & 32'hffff_fffc;
                        iCache_regs.inst0.valid = ~delayPC[2];
                        iCache_regs.inst0.inst  = insts[{delayPC[3], 1'b0}];

                        iCache_regs.inst1.pc    = delayPC | 32'h0000_0004;
                        iCache_regs.inst1.valid = !delayOnlyGetDS;
                        iCache_regs.inst1.inst  = insts[{delayPC[3], 1'b1}];
                    end
                end else begin
                    iCache_regs.inst0.pc    = 32'h0000_0000;
                    iCache_regs.inst0.valid = `FALSE;
                    iCache_regs.inst0.inst  = 32'h0000_0000;

                    iCache_regs.inst0.pc    = 32'h0000_0000;
                    iCache_regs.inst1.valid = `FALSE;
                    iCache_regs.inst0.inst  = 32'h0000_0000;
                end
            end
            sWaitUnpause: begin
                iCache_regs.inst0.pc    = delayPC & 32'hffff_fffc;
                iCache_regs.inst0.valid = ~delayPC[2];
                iCache_regs.inst0.inst  = insts[{delayPC[3], 1'b0}];

                iCache_regs.inst1.pc    = delayPC | 32'h0000_0004;
                iCache_regs.inst1.valid = !delayOnlyGetDS;
                iCache_regs.inst1.inst  = insts[{delayPC[3], 1'b1}];
            end
            sRecovery: begin
                instReq.valid               = `FALSE;
                instResp.ready              = `TRUE;
                ctrl_iCache.pauseReq        = `TRUE;
                iCache_regs.inst0           = 0;
                iCache_regs.inst1           = 0;
            end
            sReset: begin
                instReq.valid               = `FALSE;
                instResp.ready              = `FALSE;

                tag0IO.writeEn              = `FALSE;
                tag1IO.writeEn              = `FALSE;
                tag2IO.writeEn              = `FALSE;
                tag3IO.writeEn              = `FALSE;
                
                data0IO.writeEn             = `FALSE;
                data1IO.writeEn             = `FALSE;
                data2IO.writeEn             = `FALSE;
                data3IO.writeEn             = `FALSE;

                ctrl_iCache.pauseReq        = `FALSE;

                iCache_regs.inst0.pc        = 32'h0000_0000;
                iCache_regs.inst0.valid     = `FALSE;
                iCache_regs.inst0.inst      = 32'h0000_0000;

                iCache_regs.inst0.pc        = 32'h0000_0000;
                iCache_regs.inst1.valid     = `FALSE;
                iCache_regs.inst0.inst      = 32'h0000_0000;

                for(integer i = 0; i < 4; i++) begin
                    nxtvalid[i]    = 0;
                end
            end
        endcase
    end
endmodule
