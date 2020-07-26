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
    input  wire         clk,
    input  wire         rst,

    Ctrl.slave          ctrl_lsu,
    
    output logic        lsu_busy,
    input  logic        fireStore,
    
    input  UOPBundle    uOP,
    input  PRFrData     oprands,

    // output UOPBundle    commitUOP,
    output PRFwInfo     wbData,
    FU_ROB.fu           lsu_commit_reg,

    DataReq.lsu         dataReq,
    DataResp.lsu        dataResp
);

    typedef enum { sIdle, sLoadReq, sLoadResp, sSaveBlock, sSaveFire, sRecover, sReset } LsuState;
    LsuState            state, nxtState;
    UOPBundle           currentUOP;
    PRFrData            currentOprands;
    logic       [31:0]  currentLoadAddress;
    UOPBundle           lastUOP;
    PRFrData            lastOprands;
    logic               uOPIsLoad;
    logic               uOPIsSave;

    logic       [ 7:0]  bytes [3:0];
    logic       [15:0]  hws   [1:0];
    logic               committed;
    logic               clearCurrent;

    logic [31:0] reqAddrRaw;

    assign currentLoadAddress = currentOprands.rs0_data + currentUOP.imm[15:0];

    assign uOPIsLoad = currentUOP.valid && (
        currentUOP.uOP == LB_U  || 
        currentUOP.uOP == LH_U  || 
        currentUOP.uOP == LBU_U || 
        currentUOP.uOP == LHU_U || 
        currentUOP.uOP == LW_U
    );

    assign uOPIsSave = currentUOP.valid && (
        currentUOP.uOP == SB_U  || 
        currentUOP.uOP == SH_U  || 
        currentUOP.uOP == SW_U  || 
        currentUOP.uOP == SWL_U || 
        currentUOP.uOP == SWR_U
    );

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

    always_ff @ (posedge clk) begin
        if(rst) begin
            lastUOP         <= 0;
            lastOprands     <= 0;
            state           <= sReset;
        end else begin
            lastUOP         <= state != sIdle ? lastUOP : uOP;
            lastOprands     <= state != sIdle ? lastOprands : oprands;
            state           <= nxtState;
        end
    end
    
    assign currentUOP      =  uOP;
    assign currentOprands  =  oprands;

    always_ff @ (posedge clk) committed <= (state == sIdle && uOPIsSave) ? `FALSE : `TRUE;

    always_comb begin
        case (state)
            sIdle: begin
                if(rst || ctrl_lsu.flush) begin
                    nxtState = sReset;
                end else if(uOPIsLoad) begin
                    nxtState = sLoadReq;
                end else if (uOPIsSave) begin
                    nxtState = sSaveBlock;
                end else begin
                    nxtState = sIdle;
                end
            end
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
                end else if(ctrl_lsu.flush) begin
                    nxtState = sRecover;
                end else if (dataResp.valid) begin
                    nxtState = sIdle;
                end else begin
                    nxtState = sLoadResp;
                end
            end
            sSaveBlock: begin
                if(rst || ctrl_lsu.flush) begin
                    nxtState = sReset;
                end else if (fireStore) begin
                    nxtState = sSaveFire;
                end else begin
                    nxtState = sSaveBlock;
                end
            end
            sSaveFire: begin
                if(rst || ctrl_lsu.flush) begin
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
        dataReq.data                = 0;
        dataReq.strobe              = 0;
        dataReq.write_en            = 0;
        dataReq.valid               = `FALSE;
        dataResp.ready              = `FALSE;
        lsu_commit_reg.setFinish    = `FALSE;
        lsu_commit_reg.id           = 0;
        wbData                      = 0;
        reqAddrRaw                  = 0;
        lsu_busy                    = 0;
        case(state)
            sIdle: begin
                dataReq.valid                   = `FALSE;
                dataResp.ready                  = `FALSE;
                lsu_commit_reg.setFinish        = `FALSE;
                lsu_busy                        = currentUOP.valid;
                lsu_commit_reg.setFinish        = uOPIsSave;
                lsu_commit_reg.id               = currentUOP.id;
            end
            sLoadReq: begin
                dataReq.valid                   = `TRUE;
                reqAddrRaw                      = (currentOprands.rs0_data + currentUOP.imm[15:0]) & 32'hfffffffc;
                dataReq.write_en                = `FALSE;
                dataResp.ready                  = `FALSE;
                lsu_busy                        = `TRUE;
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
            sSaveBlock: begin
                lsu_busy                        = `TRUE;
                wbData.wen                      = `FALSE;
            end
            sSaveFire: begin
                lsu_busy                        = ~dataReq.ready;
                dataReq.valid                   = `TRUE;
                reqAddrRaw                      = currentOprands.rs0_data + currentUOP.imm[15:0];
                dataReq.data                    = currentOprands.rs1_data;
                dataReq.write_en                = `TRUE;
                wbData.wen                      = `FALSE;
                case (currentUOP.uOP)
                    SB_U :  begin
                        case (dataReq.addr[1:0])
                            2'b00: dataReq.strobe = 4'b0001;
                            2'b01: dataReq.strobe = 4'b0010;
                            2'b10: dataReq.strobe = 4'b0100;
                            2'b11: dataReq.strobe = 4'b1000;
                        endcase
                    end
                    SH_U :  dataReq.strobe = dataReq.addr[1] ? 4'b1100 : 4'b0011;
                    SW_U :  dataReq.strobe = 4'b1111;
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
