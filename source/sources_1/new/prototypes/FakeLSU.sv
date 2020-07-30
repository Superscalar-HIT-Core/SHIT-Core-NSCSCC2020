`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/23 21:50:46
// Design Name: 
// Module Name: FakeLSU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../defines/defines.svh"

module FakeLSU(
    input  wire             clk,
    input  wire             rst,

    Ctrl.slave              ctrl_lsu,

    output logic            lsu_busy,
    input  logic            fireStore,

    input  UOPBundle        uOP,
    input  PRFrData         oprands,

    // output UOPBundle        commitUOP,
    output PRFwInfo         wbData,
    FU_ROB.fu               lsu_commit_reg,

    DataReq.lsu             dataReq,
    DataResp.lsu            dataResp,

    logic                   hasPendingUncachedLoad,
    UncachedLoadInfo.lsu    uncachedLoadInfo
);

    typedef enum {
        sIdle,
        sException,
        sSaveUncachedLoad,
        sLoadReqUncached,
        sLoadRespUncached,
        sLoadReq,
        sLoadResp,
        sSaveBlock,
        sSaveFire,
        sRecover,
        sReset
    } LsuState;

    LsuState            state, nxtState;
    UOPBundle           currentUOP;
    PRFrData            currentOprands;
    logic       [31:0]  currentLoadAddress;
    UOPBundle           lastUOP;
    PRFrData            lastOprands;
    logic               uOPIsLoad;
    logic               uOPIsUncachedLoad;
    logic               uOPIsSave;
    logic               uOPCauseExce;
    logic               flushInStore;

    logic       [ 7:0]  bytes [3:0];
    logic       [15:0]  hws   [1:0];
    logic               committed;
    logic               clearCurrent;

    logic [31:0]        reqAddrRaw;
    logic               pendingFlush;

    UOPBundle           uncachedLoads       [7:0];  // prevent overflow
    PRFrData            uncachedLoadOprands [7:0];
    logic [2:0]         uncachedCount;
    logic [7:0]         uncachedReady;
    logic [7:0]         uncachedReadyDly1;
    logic [7:0]         uncachedReadyDly2;
    logic [7:0]         uncachedReadyDly3;
    logic [7:0]         uncachedReadyDly4;
    logic [2:0]         currentUncachedLoad;
    logic               saveBlocking;
    logic               goodToSave;

    assign hasPendingUncachedLoad = uncachedCount > 0;

    assign currentLoadAddress = currentOprands.rs0_data + currentUOP.imm;

    assign uOPIsLoad = currentUOP.valid && (
        currentUOP.uOP == LB_U  || 
        currentUOP.uOP == LH_U  || 
        currentUOP.uOP == LBU_U || 
        currentUOP.uOP == LHU_U || 
        currentUOP.uOP == LW_U
    );

    assign uOPIsUncachedLoad = uOPIsLoad && currentLoadAddress >= 32'hA000_0000 && currentLoadAddress <= 32'hBFFF_FFFF;

    assign uOPIsSave = currentUOP.valid && (
        currentUOP.uOP == SB_U  || 
        currentUOP.uOP == SH_U  || 
        currentUOP.uOP == SW_U  || 
        currentUOP.uOP == SWL_U || 
        currentUOP.uOP == SWR_U
    );

    always_comb begin
        uOPCauseExce = `FALSE;
        if(currentUOP.valid) begin
            case(currentUOP.uOP)
                LW_U, SW_U        : uOPCauseExce = |currentLoadAddress[1:0];
                LH_U, LHU_U, SH_U : uOPCauseExce =  currentLoadAddress[ 0 ];
                default           : uOPCauseExce = `FALSE;
            endcase
        end
    end

    assign bytes[0] = dataResp.data[ 7: 0];
    assign bytes[1] = dataResp.data[15: 8];
    assign bytes[2] = dataResp.data[23:16];
    assign bytes[3] = dataResp.data[31:24];
    assign hws[0]   = dataResp.data[15: 0];
    assign hws[1]   = dataResp.data[31:16];
    assign clearCurrent = state == sIdle;

    always_comb begin
        if(reqAddrRaw >= 32'h8000_0000 && reqAddrRaw <= 32'h9fff_ffff) begin
            dataReq.addr = reqAddrRaw - 32'h8000_0000;
        end else if(reqAddrRaw >= 32'hA000_0000 && reqAddrRaw <= 32'hBFFF_FFFF) begin
            dataReq.addr = reqAddrRaw - 32'hA000_0000;
        end else begin
            dataReq.addr = reqAddrRaw;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            state           <= sReset;
        end else begin
            state           <= nxtState;
        end
    end

    always_ff @(posedge clk) begin
        if(rst || ctrl_lsu.flush) begin
            pendingFlush <= `FALSE;
        end else if (state == sException) begin
            pendingFlush <= `TRUE;
        end else begin
            pendingFlush <= `FALSE;
        end
    end

    always_ff @ (posedge clk) begin
        if(rst) begin
            lastUOP         <= 0;
            lastOprands     <= 0;
        end else if (ctrl_lsu.flush && state == sSaveFire && !flushInStore) begin
            lastUOP         <= uOP;
            lastOprands     <= oprands;
        end else begin
            lastUOP         <= lastUOP;
            lastOprands     <= lastOprands;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            flushInStore    <= `FALSE;
        end else if (dataReq.ready) begin
            flushInStore    <= `FALSE;
        end else if (ctrl_lsu.flush && state == sSaveFire && !dataReq.ready) begin
            flushInStore    <= `TRUE;
        end else begin
            flushInStore    <= flushInStore;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            goodToSave <= `FALSE;
        end else if (saveBlocking && fireStore) begin
            goodToSave <= `TRUE;
        end else if (uOPIsSave) begin
            goodToSave <= `FALSE;
        end
    end
    
    always_comb begin
        for(integer i = 0; i < 8; i++) begin
            uncachedReady[i] =
            (uncachedLoads[i].valid)    &&
            !uncachedLoadInfo.isEmpty   &&
            (
                uncachedLoadInfo.head0.id == uncachedLoads[i].id ||
                (
                    uncachedLoadInfo.head1.id == uncachedLoads[i].id &&
                    (!uncachedLoadInfo.head0.causeExc || uncachedLoadInfo.head0.exception != ExcAddressErrIF))
            );
        end
    end

    always_ff @(posedge clk) begin
        if (rst || ctrl_lsu.flush) begin
            uncachedReadyDly1 <= 0;
            uncachedReadyDly2 <= 0;
            uncachedReadyDly3 <= 0;
            uncachedReadyDly4 <= 0;
        end else begin
            uncachedReadyDly1 <= uncachedReady;
            uncachedReadyDly2 <= uncachedReadyDly1;
            uncachedReadyDly3 <= uncachedReadyDly2;
            uncachedReadyDly4 <= uncachedReadyDly3;
        end
    end

    always_ff @(posedge clk) begin
        if(rst || ctrl_lsu.flush) begin
            uncachedCount       <= 0;
            currentUncachedLoad <= 0;
            for (integer i = 0; i < 8; i++) begin
                uncachedLoads       [i] <= 0;
                uncachedLoadOprands [i] <= 0;
            end
        end else begin
            if (state == sIdle && uOPIsUncachedLoad) begin
                for (integer i = 0; i < 8; i++) begin
                    if(!uncachedLoads[i].valid) begin
                        uncachedLoads       [i] <= currentUOP;
                        uncachedLoadOprands [i] <= currentOprands;
                        uncachedCount           <= uncachedCount + 1;
                        break;
                    end
                end
            end else if (state == sLoadRespUncached && dataResp.valid) begin
                uncachedLoads[currentUncachedLoad].valid <= `FALSE;
                uncachedCount <= uncachedCount - 1;
            end
            if (nxtState == sLoadReqUncached) begin
                for (integer i = 0; i < 8; i++) begin
                    if(uncachedReady[i]) begin
                        currentUncachedLoad <= i;
                        break;
                    end
                end
            end
        end
    end

    always_comb begin
        if (state == sLoadReqUncached || state == sLoadRespUncached) begin
            currentUOP      = uncachedLoads[currentUncachedLoad];
            currentOprands  = uncachedLoadOprands[currentUncachedLoad];
        end else if (flushInStore) begin
            currentUOP      = lastUOP;
            currentOprands  = lastOprands;
        end else begin
            currentUOP      = uOP;
            currentOprands  = oprands;
        end
    end

    always_ff @ (posedge clk) committed <= (state == sIdle && uOPIsSave) ? `FALSE : `TRUE;

    always_ff @(posedge clk) begin
        if (rst || ctrl_lsu.flush) begin
            saveBlocking <= `FALSE;
        end else if (state == sSaveBlock) begin
            saveBlocking <= `TRUE;
        end else if (state == sSaveFire) begin
            saveBlocking <= `FALSE;
        end
    end

    always_comb begin
        case (state)
            sIdle: begin
                if(rst || ctrl_lsu.flush) begin
                    nxtState = sReset;
                end else if(uOPCauseExce) begin
                    nxtState = sException;
                end else if(uOPIsLoad && uOPIsUncachedLoad) begin
                    nxtState = sIdle;
                end else if(uOPIsLoad && !uOPIsUncachedLoad) begin
                    nxtState = sLoadReq;
                end else if (uOPIsSave && !pendingFlush) begin
                    nxtState = sSaveBlock;
                end else if (uncachedReady > 0) begin
                    nxtState = sLoadReqUncached;
                end else begin
                    nxtState = sIdle;
                end
            end
            sException: begin
                if(rst || ctrl_lsu.flush) begin
                    nxtState = sReset;
                end else begin
                    nxtState = sIdle;
                end
            end
            // sWaitFlush: begin
            //     if(rst || ctrl_lsu.flush) begin
            //         nxtState = sReset;
            //     end else begin
            //         nxtState = sWaitFlush;
            //     end
            // end
            sLoadReq: begin
                if(rst || ctrl_lsu.flush) begin
                    nxtState = sReset;
                end else if (dataReq.ready) begin
                    nxtState = sLoadResp;
                end else begin
                    nxtState = sLoadReq;
                end
            end
            sLoadResp: begin
                if(rst) begin
                    nxtState = sReset;
                end else if(ctrl_lsu.flush && !dataResp.valid) begin
                    nxtState = sRecover;
                end else if (dataResp.valid) begin
                    nxtState = sIdle;
                end else begin
                    nxtState = sLoadResp;
                end
            end
            sLoadReqUncached: begin    // dont care flush
                if(rst) begin
                    nxtState = sReset;
                end else if (dataReq.ready) begin
                    nxtState = sLoadRespUncached;
                end else begin
                    nxtState = sLoadReqUncached;
                end
            end
            sLoadRespUncached: begin    // dont care flush
                if(rst) begin
                    nxtState = sReset;
                end else if (dataResp.valid && saveBlocking && (fireStore || goodToSave)) begin
                    nxtState = sSaveFire;
                end else if (dataResp.valid && saveBlocking) begin
                    nxtState = sSaveBlock;
                end else if (dataResp.valid) begin
                    nxtState = sIdle;
                end else begin
                    nxtState = sLoadRespUncached;
                end
            end
            sSaveBlock: begin
                if(rst || ctrl_lsu.flush) begin
                    nxtState = sReset;
                end else if (fireStore || goodToSave) begin
                    nxtState = sSaveFire;
                end else if (uncachedReadyDly4 > 0) begin
                    nxtState = sLoadReqUncached;
                end else begin
                    nxtState = sSaveBlock;
                end
            end
            sSaveFire: begin
                if(rst) begin   // definitive
                    nxtState = sReset;
                end else if (dataReq.ready) begin
                    nxtState = sIdle;
                end else begin
                    nxtState = sSaveFire;
                end
            end
            sRecover: begin
                if(rst) begin
                    nxtState = sReset;
                end else if (dataResp.valid) begin
                    nxtState = sIdle;
                end else begin
                    nxtState = sRecover;
                end
            end
            sReset: begin
                if(rst || ctrl_lsu.flush) begin
                    nxtState = sReset;
                end else begin
                    nxtState = sIdle;
                end
            end
            default: begin
                nxtState = sReset;
            end
        endcase
    end

    always_comb begin
        dataReq.data                    = 0;
        dataReq.strobe                  = 4'b1111;
        dataReq.write_en                = 0;
        dataReq.size                    = 3'b010;
        dataReq.valid                   = `FALSE;
        dataResp.ready                  = `FALSE;
        lsu_commit_reg.setFinish        = `FALSE;
        lsu_commit_reg.id               = 0;
        lsu_commit_reg.setException     = `FALSE;
        lsu_commit_reg.exceptionType    = ExcAddressErrL;
        lsu_commit_reg.BadVAddr         = 0;
        wbData                          = 0;
        reqAddrRaw                      = 0;
        lsu_busy                        = 0;
        case(state)
            sIdle: begin
                dataReq.valid                   = `FALSE;
                dataResp.ready                  = `FALSE;
                lsu_busy                        = (currentUOP.valid && !uOPIsUncachedLoad) || saveBlocking;
                lsu_commit_reg.setFinish        = uOPIsSave && !uOPCauseExce;
                lsu_commit_reg.id               = currentUOP.id;
            end
            sException: begin
                lsu_busy                        = `FALSE;
                lsu_commit_reg.setFinish        = `TRUE;
                lsu_commit_reg.id               = currentUOP.id;
                lsu_commit_reg.setException     = `TRUE;
                lsu_commit_reg.exceptionType    = uOPIsLoad ? ExcAddressErrL : ExcAddressErrS;
                lsu_commit_reg.BadVAddr         = (currentOprands.rs0_data + currentUOP.imm);
            end
            // sWaitFlush: begin
            //     lsu_busy                        = `FALSE;
            //     lsu_commit_reg.setFinish        = `TRUE;
            //     lsu_commit_reg.id               = currentUOP.id;
            //     lsu_commit_reg.setException     = `FALSE;
            //     dataReq.valid                   = `FALSE;
            //     dataResp.ready                  = `FALSE;
            // end
            sLoadReq: begin
                dataReq.valid                   = ~ctrl_lsu.flush;
                reqAddrRaw                      = (currentOprands.rs0_data + currentUOP.imm);
                dataReq.write_en                = `FALSE;
                dataResp.ready                  = `FALSE;
                lsu_busy                        = `TRUE;
                case(currentUOP.uOP)
                    LW_U, SW_U        : dataReq.size = 3'b010;
                    LH_U, LHU_U, SH_U : dataReq.size = 3'b001;
                    default           : dataReq.size = 3'b000;
                endcase
            end
            sLoadResp: begin
                dataResp.ready                  = `TRUE;
                lsu_busy                        = `TRUE;
                if (dataResp.valid) begin
                    lsu_commit_reg.setFinish    = `TRUE;
                    lsu_commit_reg.id           = currentUOP.id;
                    wbData.wen                  = `TRUE;
                    wbData.rd                   = currentUOP.dstPAddr;
                    case (currentUOP.uOP)
                        LB_U :  wbData.wdata    = {{24{bytes[currentLoadAddress[1:0]][7]}}, bytes[currentLoadAddress[1:0]]};
                        LH_U :  wbData.wdata    = {{16{hws[currentLoadAddress[1]][15]}}, hws[currentLoadAddress[1]]};
                        LBU_U:  wbData.wdata    = {24'b0, bytes[currentLoadAddress[1:0]]};
                        LHU_U:  wbData.wdata    = {16'b0, hws[currentLoadAddress[1]]};
                        LW_U :  wbData.wdata    = dataResp.data;
                    endcase
                    lsu_busy                    = `FALSE;
                end
            end
            sLoadReqUncached: begin
                dataReq.valid                   = `TRUE;
                reqAddrRaw                      = (currentOprands.rs0_data + currentUOP.imm);
                dataReq.write_en                = `FALSE;
                dataResp.ready                  = `FALSE;
                lsu_busy                        = `TRUE;
                case(currentUOP.uOP)
                    LW_U, SW_U        : dataReq.size = 3'b010;
                    LH_U, LHU_U, SH_U : dataReq.size = 3'b001;
                    default           : dataReq.size = 3'b000;
                endcase
            end
            sLoadRespUncached: begin
                dataResp.ready                  = `TRUE;
                lsu_busy                        = `TRUE;
                if (dataResp.valid) begin
                    lsu_commit_reg.setFinish    = `TRUE;
                    lsu_commit_reg.id           = currentUOP.id;
                    wbData.wen                  = `TRUE;
                    wbData.rd                   = currentUOP.dstPAddr;
                    case (currentUOP.uOP)
                        LB_U :  wbData.wdata    = {{24{bytes[currentLoadAddress[1:0]][7]}}, bytes[currentLoadAddress[1:0]]};
                        LH_U :  wbData.wdata    = {{16{hws[currentLoadAddress[1]][15]}}, hws[currentLoadAddress[1]]};
                        LBU_U:  wbData.wdata    = {24'b0, bytes[currentLoadAddress[1:0]]};
                        LHU_U:  wbData.wdata    = {16'b0, hws[currentLoadAddress[1]]};
                        LW_U :  wbData.wdata    = dataResp.data;
                    endcase
                    // lsu_busy                    = `FALSE;
                end
            end
            sSaveBlock: begin
                lsu_busy                        = `TRUE;
                wbData.wen                      = `FALSE;
            end
            sSaveFire: begin
                lsu_busy                        = ~dataReq.ready;
                dataReq.valid                   = `TRUE;
                reqAddrRaw                      = currentOprands.rs0_data + currentUOP.imm;
                dataReq.data                    = currentOprands.rs1_data;
                dataReq.write_en                = `TRUE;
                wbData.wen                      = `FALSE;
                case (currentUOP.uOP)
                    SB_U :  begin
                        dataReq.size            = 3'b000;
                        case (dataReq.addr[1:0])
                            2'b00: begin
                                dataReq.strobe  = 4'b0001;
                                dataReq.data    = currentOprands.rs1_data;
                            end
                            2'b01: begin
                                dataReq.strobe  = 4'b0010;
                                dataReq.data    = currentOprands.rs1_data << 8;
                            end
                            2'b10: begin
                                dataReq.strobe  = 4'b0100;
                                dataReq.data    = currentOprands.rs1_data << 16;
                            end
                            2'b11: begin
                                dataReq.strobe  = 4'b1000;
                                dataReq.data    = currentOprands.rs1_data << 24;
                            end
                        endcase
                    end
                    SH_U :  begin
                        dataReq.size   = 3'b001;
                        dataReq.strobe = dataReq.addr[1] ? 4'b1100 : 4'b0011;
                        dataReq.data   = dataReq.addr[1] ? currentOprands.rs1_data << 16 : currentOprands.rs1_data;
                    end
                    SW_U :  begin
                        dataReq.strobe = 4'b1111;
                        dataReq.size   = 3'b010;
                        dataReq.data   = currentOprands.rs1_data;
                    end
                endcase
            end
            sRecover: begin
                dataResp.ready          = `TRUE;
                lsu_busy                = ~dataResp.valid;
            end
            sReset: begin
                lsu_busy                = `FALSE;
            end
        endcase
    end

endmodule
