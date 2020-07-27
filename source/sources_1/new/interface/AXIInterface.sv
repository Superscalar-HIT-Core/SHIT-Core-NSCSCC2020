`timescale 1ns / 1ps
`include "../defs.sv"

module AXIInterface(
    input clk,
    input rst,

    AXIReadAddr.master  axiReadAddr,
    AXIReadData.master  axiReadData,
    AXIWriteAddr.master axiWriteAddr,
    AXIWriteData.master axiWriteData,
    AXIWriteResp.master axiWriteResp,

    InstReq.axi         instReq,
    InstResp.axi        instResp,
    DataReq.axi         dataReq,
    DataResp.axi        dataResp,
    DCacheReq.axi       dCacheReq,
    DCacheResp.axi      dCacheResp
);

    typedef enum  { sRAddr, sRInst, sRData, sRDCache, sRRst } AXIRState;
    typedef enum  { sWAddr, sWData, sWDCache, sWDResp, sWDCResp, sWRst } AXIWState;

    AXIRState   rState, nextRState, lastRState;
    AXIWState   wState, nextWState, lastWState;
    
    logic           instReqBusy;
    logic [31:0]    instReqPC;
    logic [31:0]    lastInstReqPC;

    logic           dataReqBusy;
    logic [31:0]    dataReqAddr;
    logic [31:0]    dataReqData;
    logic           dataReqWEn;
    logic [3:0]     dataReqStrobe;
    logic [31:0]    lastDataReqAddr;
    logic [31:0]    lastDataReqData;
    logic           lastDataReqWEn;
    logic [3:0]     lastDataReqStrobe;

    logic           dCacheReqBusy;
    logic [31:0]    dCacheReqAddr;
    logic [127:0]   dCacheReqData;
    logic           dCacheReqWEn;
    logic [31:0]    lastDCacheReqAddr;
    logic [127:0]   lastDCacheReqData;
    logic           lastDCacheReqWEn;

    logic           dReadReady;
    logic [31:0]    dReadRes;

    logic           iReadReady;
    logic [127:0]   iReadRes;

    logic           dcReadReady;
    logic [127:0]   dcReadRes;

    logic [1:0]     instRespCounter;
    logic [1:0]     dCacheRespCounter;
    logic [1:0]     dCacheDataCounter;

    logic           lastInstBusy;
    logic           lastDataBusy;
    logic           lastDCacheBusy;

    assign axiReadAddr.valid  = rState == sRAddr && ((instReqBusy || (dataReqBusy && !dataReqWEn)) || (dCacheReqBusy && !dCacheReqWEn));
    assign axiWriteAddr.valid = wState == sWAddr && ((dataReqBusy && dataReqWEn) || (dCacheReqBusy && dCacheReqWEn));

    assign instReq.ready    = ~lastInstBusy;
    assign dataReq.ready    = ~lastDataBusy;
    assign dCacheReq.ready  = ~lastDCacheBusy;

    assign instResp.valid   = iReadReady;
    assign dataResp.valid   = dReadReady;
    assign dCacheResp.valid = dcReadReady;

    always_comb begin
        instReqBusy     = lastInstBusy ;
        instReqPC       = lastInstReqPC;
        if(rst) begin
            instReqBusy = `FALSE;
        end else if(instReq.valid && !lastInstBusy) begin
            instReqBusy = `TRUE;
            instReqPC   = instReq.pc;
        end else if(rState == sRInst && lastRState == sRAddr) begin
            instReqBusy = `FALSE;
        end else begin
            instReqBusy = lastInstBusy;
        end
    end

    always_comb begin
        dataReqBusy         = lastDataBusy;
        dataReqBusy         = lastDataBusy;
        dataReqAddr         = lastDataReqAddr;
        dataReqData         = lastDataReqData;
        dataReqStrobe       = lastDataReqStrobe;
        dataReqWEn          = lastDataReqWEn;
        if(rst) begin
            dataReqBusy     = `FALSE;
            dataReqWEn      = `FALSE;
        end else if(dataReq.valid && !lastDataBusy) begin
            dataReqBusy     = `TRUE;
            dataReqAddr     = dataReq.addr;
            dataReqWEn      = dataReq.write_en;
            dataReqStrobe   = dataReq.strobe;
            dataReqData     = dataReq.data;
        end else if (rState == sRAddr && lastRState == sRData || (wState == sWAddr && lastWState == sWDResp)) begin
            dataReqBusy     = `FALSE;
            dataReqWEn      = `FALSE;
        end
    end

    always_comb begin
        dCacheReqBusy       = lastDCacheBusy   ;
        dCacheReqAddr       = lastDCacheReqAddr;
        dCacheReqData       = lastDCacheReqData;
        dCacheReqWEn        = lastDCacheReqWEn ;
        if(rst) begin
            dCacheReqBusy   = `FALSE;
            dCacheReqWEn    = `FALSE;
        end else if(dCacheReq.valid && !lastDCacheBusy) begin
            dCacheReqBusy   = `TRUE;
            dCacheReqAddr   = dCacheReq.addr;
            dCacheReqWEn    = dCacheReq.write_en;
            dCacheReqData   = dCacheReq.data;
        end else if (rState == sRDCache && lastRState == sRAddr || (wState == sWDCResp && lastWState == sWDCache)) begin
            dCacheReqBusy   = `FALSE;
            dCacheReqWEn    = `FALSE;
        end else begin
            dCacheReqBusy   = lastDCacheBusy;
        end
    end

    always_ff @ (posedge clk) begin
        lastInstBusy        <= instReqBusy;
        lastInstReqPC       <= instReqPC;

        lastDataBusy        <= dataReqBusy;
        lastDataReqAddr     <= dataReqAddr;
        lastDataReqData     <= dataReqData;
        lastDataReqStrobe   <= dataReqStrobe;
        lastDataReqWEn      <= dataReqWEn;

        lastDCacheBusy      <= dCacheReqBusy;
        lastDCacheReqAddr   <= dCacheReqAddr;
        lastDCacheReqData   <= dCacheReqAddr;
        lastDCacheReqWEn    <= dCacheReqWEn;
    end

    always_comb begin
        unique case(rState)
            sRAddr: begin
                if(rst) begin
                    nextRState = sRRst;
                end else if(axiReadAddr.valid && axiReadAddr.ready) begin
                    if(dataReqBusy && !dataReqWEn) begin
                        nextRState = sRData;
                    end else if(dCacheReqBusy && !dCacheReqWEn) begin
                        nextRState = sRDCache;
                    end else begin
                        nextRState = sRInst;
                    end
                end else begin
                    nextRState = sRAddr;
                end
            end
            sRData: begin
                if(rst) begin
                    nextRState = sRRst;
                end else if(dReadReady && dataResp.ready) begin
                    nextRState = sRAddr;
                end else begin
                    nextRState = sRData;
                end
            end
            sRDCache: begin
                if(rst) begin
                    nextRState = sRRst;
                end else if(dcReadReady && dCacheResp.ready) begin
                    nextRState = sRAddr;
                end else begin
                    nextRState = sRDCache;
                end
            end
            sRInst: begin
                if(rst) begin
                    nextRState = sRRst;
                end else if(iReadReady && instResp.ready) begin
                    nextRState = sRAddr;
                end else begin
                    nextRState = sRInst;
                end
            end
            sRRst: begin
                if(rst) begin
                    nextRState = sRRst;
                end else begin
                    nextRState = sRAddr;
                end
            end
            default: begin
                nextRState = sRRst;
            end
        endcase
    end

    always_comb begin
        unique case(wState)
            sWAddr: begin
                if(rst) begin
                    nextWState = sWRst;
                end else if(axiWriteAddr.valid && axiWriteAddr.ready && dCacheReqBusy && dCacheReqWEn) begin
                    nextWState = sWDCache;
                end else if(axiWriteAddr.valid && axiWriteAddr.ready && dataReqBusy && dataReqWEn) begin
                    nextWState = sWData;
                end else begin
                    nextWState = sWAddr;
                end
            end
            sWDCache: begin
                if(rst) begin
                    nextWState = sWRst;
                end else if(axiWriteData.valid && axiWriteData.ready && axiWriteData.last) begin
                    nextWState = sWDCResp;
                end else begin
                    nextWState = sWDCache;
                end
            end
            sWData: begin
                if(rst) begin
                    nextWState = sWRst;
                end else if(axiWriteData.valid && axiWriteData.ready) begin
                    nextWState = sWDResp;
                end else begin
                    nextWState = sWData;
                end
            end
            sWDResp: begin
                if(rst) begin
                    nextWState = sWRst;
                end else if(axiWriteResp.valid && axiWriteResp.ready) begin
                    nextWState = sWAddr;
                end else begin
                    nextWState = sWDResp;
                end
            end
            sWRst: begin
                if(rst) begin
                    nextWState = sWRst;
                end else begin
                    nextWState = sWAddr;
                end
            end
            default: begin
                nextWState = sWRst;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        rState <= nextRState;
        wState <= nextWState;
        lastRState <= rState;
        lastWState <= wState;
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            instRespCounter <= 0;
        end else if(rState == sRInst) begin
            if(axiReadData.ready && axiReadData.valid) begin
                instRespCounter <= instRespCounter + 1;
                unique case(instRespCounter)
                    2'b00: iReadRes[ 31: 0] <= axiReadData.data;
                    2'b01: iReadRes[ 63:32] <= axiReadData.data;
                    2'b10: iReadRes[ 95:64] <= axiReadData.data;
                    2'b11: iReadRes[127:96] <= axiReadData.data;
                endcase
            end
        end else begin
            instRespCounter <= 0;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            dCacheRespCounter <= 0;
        end else if(rState == sRDCache) begin
            if(axiReadData.ready && axiReadData.valid) begin
                dCacheRespCounter <= dCacheRespCounter + 1;
                unique case(dCacheRespCounter)
                    2'b00: dcReadRes[ 31: 0] = axiReadData.data;
                    2'b01: dcReadRes[ 63:32] = axiReadData.data;
                    2'b10: dcReadRes[ 95:64] = axiReadData.data;
                    2'b11: dcReadRes[127:96] = axiReadData.data;
                endcase
            end
        end else begin
            dCacheRespCounter <= 0;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            dCacheDataCounter <= 0;
        end else if(wState == sWDCache) begin
            if(axiWriteData.ready && axiWriteData.valid) begin
                dCacheDataCounter <= dCacheDataCounter + 1;
            end
        end else begin
            dCacheDataCounter <= 0;
        end
    end

    always_comb begin
        axiReadAddr.id      = 4'h1;
        axiReadAddr.address = 0;
        axiReadAddr.length  = 4'b0011;  // burst 4
        axiReadAddr.size    = 3'b010;
        axiReadAddr.burst   = 2'b10;
                
        dReadReady          = `FALSE;
        iReadReady          = `FALSE;
        dcReadReady         = `FALSE;

        instResp.cacheLine  = iReadRes;
        dataResp.data       = axiReadData.data;
        dCacheResp.data     = dcReadRes;
        unique case(rState)
            sRAddr: begin
                if(dCacheReqBusy && !dCacheReqWEn) begin
                    axiReadAddr.id      = 4'h1;
                    axiReadAddr.address = dCacheReqAddr & 32'hFFFF_FFF0;
                    axiReadAddr.length  = 4'b0011;  // burst 4
                    axiReadAddr.size    = 3'b010;
                    axiReadAddr.burst   = 2'b10;
                end else if(dataReqBusy && !dataReqWEn) begin
                    axiReadAddr.id      = 4'h1;
                    axiReadAddr.address = dataReqAddr;
                    axiReadAddr.length  = 4'b0000;  // no burst
                    axiReadAddr.size    = 3'b010;
                    axiReadAddr.burst   = 2'b10;
                end else if(instReqBusy) begin
                    axiReadAddr.id      = 4'h0;
                    axiReadAddr.address = instReqPC & 32'hFFFF_FFF0;
                    axiReadAddr.length  = 4'b0011;  // burst 4
                    axiReadAddr.size    = 3'b010;
                    axiReadAddr.burst   = 2'b10;
                end
                
                dReadReady  = `FALSE;
                iReadReady  = `FALSE;
                dcReadReady = `FALSE;

                axiReadData.ready = `FALSE;
            end
            sRData: begin
                axiReadData.ready = `TRUE;
                if(axiReadData.valid) begin
                    dReadReady = `TRUE;
                    dataResp.data = axiReadData.data;
                end
                iReadReady  = `FALSE;
                dcReadReady = `FALSE;
            end
            sRInst: begin
                axiReadData.ready = `TRUE;
                if(axiReadData.last) begin
                    iReadReady = `TRUE;
                    instResp.cacheLine = {axiReadData.data, iReadRes[95:0]};
                end
                dReadReady  = `FALSE;
                dcReadReady = `FALSE;
            end
            sRDCache: begin
                axiReadData.ready = `TRUE;
                if(axiReadData.last) begin
                    dcReadReady     = `TRUE;
                    dCacheResp.data = {axiReadData.data, dcReadRes[95:0]};
                end
                iReadReady  = `FALSE;
                dReadReady  = `FALSE;
            end
            sRRst: begin
                axiReadData.ready = `FALSE;
                iReadReady  = `FALSE;
                dReadReady  = `FALSE;
                dcReadReady = `FALSE;

                axiReadAddr.id      = 4'h0;
                axiReadAddr.address = 32'h00000000;
                axiReadAddr.length  = 4'b0000;
                axiReadAddr.size    = 3'b000;
                axiReadAddr.burst   = 2'b10;
            end
        endcase
    end

    always_comb begin
        axiWriteAddr.id         = 4'h0;
        axiWriteAddr.address    = dCacheReqAddr;
        axiWriteAddr.length     = 4'b0011;
        axiWriteAddr.size       = 3'b010;
        axiWriteAddr.burst      = 2'b10;
        axiWriteData.id         = 4'h0;
        axiWriteData.strobe     = 4'b1111;
        axiWriteData.data       = 0;
        axiWriteData.last       = `FALSE; 
        axiWriteResp.ready      = `FALSE;
        unique case(wState)
            sWAddr: begin
                if(dCacheReqBusy && dCacheReqWEn) begin
                    axiWriteAddr.id         = 4'h1;
                    axiWriteAddr.address    = dCacheReqAddr;
                    axiWriteAddr.length     = 4'b0011;
                    axiWriteAddr.size       = 3'b010;
                    axiWriteAddr.burst      = 2'b10;
                end else begin
                    axiWriteAddr.id         = 4'h1;
                    axiWriteAddr.address    = dataReqAddr;
                    axiWriteAddr.length     = 4'b0000;
                    axiWriteAddr.size       = 3'b010;
                    axiWriteAddr.burst      = 2'b01;
                end

                axiWriteData.valid      = `FALSE;
            end
            sWDCache: begin
                axiWriteData.id         = 4'h0;
                axiWriteData.strobe     = 4'b1111;
                case(dCacheDataCounter)
                    2'b00: begin
                        axiWriteData.data   = dCacheReqData[ 31: 0];
                        axiWriteData.last   = `FALSE; 
                    end
                    2'b01: begin
                        axiWriteData.data   = dCacheReqData[ 63:32];
                        axiWriteData.last   = `FALSE; 
                    end
                    2'b10: begin
                        axiWriteData.data   = dCacheReqData[ 95:64];
                        axiWriteData.last   = `FALSE; 
                    end
                    2'b11: begin
                        axiWriteData.data   = dCacheReqData[127:96];
                        axiWriteData.last   = `TRUE; 
                    end
                endcase
                axiWriteData.strobe     = 4'b1111;
                axiWriteData.valid      = `TRUE;
            end
            sWData: begin
                axiWriteData.id         = 4'h0;
                axiWriteData.data       = dataReqData;
                axiWriteData.strobe     = dataReqStrobe;
                axiWriteData.last       = `TRUE; 
                axiWriteData.valid      = `TRUE;
            end
            sWDResp: begin
                axiWriteData.valid      = `FALSE;
                axiWriteResp.ready      = `TRUE;
            end
            sWDCResp: begin
                axiWriteData.valid      = `FALSE;
                axiWriteResp.ready      = `TRUE;
            end
            sWRst: begin
                axiWriteAddr.id         = 4'h0;
                axiWriteAddr.address    = dataReqAddr;
                axiWriteAddr.length     = 4'b0000;
                axiWriteAddr.size       = 3'b010;
                axiWriteAddr.burst      = 2'b01;

                axiWriteData.valid      = `FALSE;
                axiWriteResp.ready      = `FALSE;
            end
        endcase
    end

endmodule
