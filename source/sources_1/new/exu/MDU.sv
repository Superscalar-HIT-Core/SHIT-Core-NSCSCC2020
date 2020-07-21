`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/19 23:05:36
// Design Name: 
// Module Name: MDU
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

module MDU(
    input  wire         clk,
    input  wire         rst,

    input  UOPBundle    uopHi,
    input  UOPBundle    uopLo,
    input  PRFrData     rdata,
    
    output PRFwInfo     wbData,
    FU_ROB.fu           mdu_rob
);
    wire  [31:0]    quotient, remainder;
    wire  [63:0]    mulRes;
    logic [31:0]    divLo;
    PRFNum          divLoAddr;
    logic [31:0]    mulLo;
    PRFNum          mulLoAddr;
    UOPBundle       dummy;
    UOPBundle       mulPipe [`MDU_MUL_CYCLE:0];
    UOPBundle       divPipe [`MDU_DIV_CYCLE:0];

    typedef enum logic[2:0] { idle, divOutputHi, divOutputLo, mulOutputHi, mulOutputLo } MDUFSMState;

    MDUFSMState state, nxtState;
    assign dummy.uOP    = NOP_U;
    assign dummy.valid  = `FALSE;

    Divider_IP divider_i(
        .aclk                   (clk                    ),
        .s_axis_divisor_tvalid  (`TRUE                  ),  
        .s_axis_divisor_tdata   (rdata.rs0_data         ),    
        .s_axis_dividend_tvalid (`TRUE                  ),
        .s_axis_dividend_tdata  (rdata.rs1_data         ),  
        // .m_axis_dout_tvalid     (m_axis_dout_tvalid),        
        .m_axis_dout_tdata      ({quotient, remainder}  )           
    );

    Multiplier_IP multiplier_i(
        .CLK                    (clk                    ),
        .A                      (rdata.rs0_data         ),    
        .B                      (rdata.rs1_data         ),    
        .P                      (mulRes                 )     
    );

    always_ff @ (posedge clk) begin
        if(rst) begin
            for(integer i = 0; i <= `MDU_MUL_CYCLE + 1; i++) begin
                mulPipe[i].valid <= `FALSE;
            end
            for(integer i = 0; i <= `MDU_DIV_CYCLE + 1; i++) begin
                divPipe[i].valid <= `FALSE;
            end
        end else begin
            for(integer i = 0; i < `MDU_MUL_CYCLE; i++) begin
                mulPipe[i] <= mulPipe[i + 1];
            end
            mulPipe[`MDU_MUL_CYCLE - 1] <= (uopHi.uOP == MULTHI_U || uopHi.uOP == MULTUHI_U) ? uopHi : dummy;
            mulPipe[`MDU_MUL_CYCLE - 0] <= (uopLo.uOP == MULTLO_U || uopLo.uOP == MULTULO_U) ? uopLo : dummy;
            for(integer i = 0; i < `MDU_DIV_CYCLE; i++) begin
                divPipe[i] <= divPipe[i + 1];
            end
            divPipe[`MDU_DIV_CYCLE - 1] <= (uopHi.uOP ==  DIVHI_U || uopHi.uOP ==  DIVUHI_U) ? uopHi : dummy;
            divPipe[`MDU_DIV_CYCLE - 0] <= (uopLo.uOP ==  DIVLO_U || uopLo.uOP ==  DIVULO_U) ? uopLo : dummy;
        end
    end

    always_comb begin
        case(state)
            mulOutputHi: begin
                if(rst) begin
                    nxtState = idle;
                end else begin
                    nxtState = mulOutputLo;
                end
            end
            divOutputHi: begin
                if(rst) begin
                    nxtState = idle;
                end else begin
                    nxtState = divOutputLo;
                end
            end
            mulOutputLo ,
            divOutputLo ,
            idle        : begin
                if(rst) begin
                    nxtState = idle;
                end else if(mulPipe[1].valid) begin
                    nxtState = mulOutputHi;
                end else if(divPipe[1].valid) begin
                    nxtState = divOutputHi;
                end else begin
                    nxtState = idle;
                end
            end
            default: begin
                nxtState = idle;
            end
        endcase
    end

    always_ff @ (posedge clk) begin
        state <= nxtState;
        divLo <= state == divOutputHi ? quotient     : divLo;
        mulLo <= state == mulOutputHi ? mulRes[31:0] : mulLo;
    end

    always_comb begin
        case(state)
            idle: begin
                wbData.wen          = `FALSE;
                wbData.rd           = 32'h0;
                wbData.wdata        = 32'h0;
                mdu_rob.setFinish   = `FALSE;
            end
            mulOutputHi: begin
                wbData.wen          = `TRUE;
                wbData.rd           = mulPipe[0].dstPAddr;
                wbData.wdata        = mulRes[63:32];
                mdu_rob.setFinish   = `TRUE;
                mdu_rob.id          = mulPipe[0].id;
            end
            mulOutputLo: begin
                wbData.wen          = `TRUE;
                wbData.rd           = mulPipe[0].dstPAddr;
                wbData.wdata        = mulLo;
                mdu_rob.setFinish   = `TRUE;
                mdu_rob.id          = mulPipe[0].id;
            end
            divOutputHi: begin
                wbData.wen          = `TRUE;
                wbData.rd           = divPipe[0].dstPAddr;
                wbData.wdata        = remainder;
                mdu_rob.setFinish   = `TRUE;
                mdu_rob.id          = divPipe[0].id;
            end
            divOutputLo: begin
                wbData.wen          = `TRUE;
                wbData.rd           = divPipe[0].dstPAddr;
                wbData.wdata        = divLo;
                mdu_rob.setFinish   = `TRUE;
                mdu_rob.id          = divPipe[0].id;
            end
            default: begin
                wbData.wen          = `FALSE;
                mdu_rob.setFinish   = `FALSE;
            end
        endcase
    end
endmodule
