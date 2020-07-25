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
    
    output logic        lsu_busy,
    input  logic        fireStore,
    
    input  UOPBundle    uOP,
    input  PRFrData     oprands,

    output UOPBundle    commitUOP,
    output PRFwInfo     wbData,
    FU_ROB.fu           lsu_rob,

    DataReq.lsu         dataReq,
    DataResp.lsu        dataResp
);

    typedef enum { sIdle, sLoadReq, sLoadResp, sSaveBlock, sSaveFire, sRecover, sReset } LsuState;
    LsuState    state, nxtState;
    UOPBundle   currentUOP;
    PRFrData    currentOprands;
    logic       uOPIsLoad;
    logic       uOPIsSave;

    logic [ 7:0] bytes [3:0];
    logic [15:0] hws   [1:0];

    assign uOPIsLoad = currentUOP.valid && (
        currentUOP.uOP == LB_U  || 
        currentUOP.uOP == LH_U  || 
        currentUOP.uOP == LBU_U || 
        currentUOP.uOP == LHU_U || 
        currentUOP.uOP == LW_U
    );

    assign uOPIsLoad = currentUOP.valid && (
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

    always_ff @ (posedge clk) begin
        currentUOP      <= lsu_busy ? currentUOP : uOP;
        currentOprands  <= lsu_busy ? currentOprands : oprands;
        state           <= nxtState;
    end

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
                    nxtState = sIdle;
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
                    nxtState = sLoadReq;
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
            default: begin
                nxtState = sReset;
            end
        endcase
    end

    always_comb begin
        dataReq.addr        = 0;
        dataReq.write_en    = 0;
        dataReq.valid       = `FALSE;
        dataResp.ready      = `FALSE;
        commitUOP           = 0;
        lsu_rob             = 0;
        wbData              = 0;
        case(state)
            sIdle: begin
                dataReq.valid           = `FALSE;
                dataResp.ready          = `FALSE;
                commitUOP               = 0;
                lsu_rob.setFinish       = `FALSE;
                lsu_busy                = `FALSE;
            end
            sLoadReq: begin
                dataReq.valid           = `TRUE;
                dataReq.addr            = (currentOprands.rs0_data + currentUOP.imm[15:0]) & 32'hfffffffc;
                dataReq.write_en        = `FALSE;
                dataResp.ready          = `FALSE;
                lsu_busy                = `TRUE;
            end
            sLoadResp: begin
                dataResp.ready          = `TRUE;
                lsu_busy                = `TRUE;
                if (dataResp.valid) begin
                    commitUOP           = currentUOP;
                    lsu_rob.setFinish   = `TRUE;
                    lsu_rob.id          = currentUOP.id;
                    wbData.wen          = `TRUE;
                    wbData.rd           = currentUOP.dstPAddr;
                    lsu_busy            = `FALSE;
                    case (currentUOP.uOP)
                        LB_U :  wbData.wData = {{24{bytes[dataReq.addr[1:0]][7]}}, bytes[dataReq.addr[1:0]]};
                        LH_U :  wbData.wData = {{16{hws[dataReq.addr[1]]}}, hws[dataReq.addr[1]]};
                        LBU_U:  wbData.wData = {24'b0, bytes[dataReq.addr[1:0]]};
                        LHU_U:  wbData.wData = {16'b0, hws[dataReq.addr[1]]};
                        LW_U :  wbData.wData = dataResp.data;
                    endcase
                end
            end
            sSaveBlock: begin
                lsu_busy                = `TRUE;
                lsu_rob.setFinish       = `TRUE;
                lsu_rob.id              = currentUOP.id;
                wbData.wen              = `FALSE;
            end
            sSaveFire: begin
                lsu_busy                = `TRUE;
                dataReq.valid           = `TRUE;
                dataReq.addr            = currentOprands.rs0_data + currentUOP.imm[15:0];
                dataReq.data            = currentOprands.rs1_data;
                dataReq.write_en        = `TRUE;
                wbData.wen              = `FALSE;
                case (currentUOP.uOP)
                    SB_U :  begin
                        case (dataReq.addr[1:0])
                            2'b00: dataReq.strobe = 4'b0001;
                            2'b01: dataReq.strobe = 4'b0010;
                            2'b10: dataReq.strobe = 4'b0100;
                            2'b11: dataReq.strobe = 4'b1000;
                        endcase
                    end
                    SH_U :  dataReq.strobe = dataReq[1] ? 4'b1100 : 4'b0011;
                    SW_U :  dataReq.strobe = 4'b1111;
                endcase
            end
        endcase
    end

endmodule