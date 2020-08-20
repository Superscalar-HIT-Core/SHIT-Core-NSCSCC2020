`timescale 1ns / 1ps
`include "../defines/defines.svh"

module MDU(
    input  wire         clk,
    input  wire         rst,
    
    Ctrl.slave          ctrl_mdu,

    input  UOPBundle    uopHi,
    input  UOPBundle    uopLo,
    input  PRFrData     rdata,
    
    output PRFwInfo     wbData,
    FU_ROB.fu           mdu_rob
);
    wire  [31:0]    quotientU, remainderU;
    wire  [31:0]    quotient, remainder;
    wire  [63:0]    mulResUnsigned;
    wire  [63:0]    mulRes;
    logic [31:0]    divLo;
    logic [31:0]    mulLo;
    logic [31:0]    multA, multB;
    logic [31:0]    dividend, dividor;
    UOPBundle       dummy;
    assign dummy = 0;
    UOPBundle       mulPipeHi [`MDU_MUL_CYCLE:0];
    UOPBundle       mulPipeLo [`MDU_MUL_CYCLE:0];
    UOPBundle       divPipeHi [`MDU_DIV_CYCLE:0];
    UOPBundle       divPipeLo [`MDU_DIV_CYCLE:0];

    logic [32 : 0]  rs0SgnPipe;
    logic [32 : 0]  rs1SgnPipe;

    logic           mulResSgn;
    logic           quotientSgn;
    logic           remainderSgn;

    typedef enum logic[2:0] { idle, divOutputHi, divOutputLo, mulOutputHi, mulOutputLo } MDUFSMState;

    MDUFSMState state, nxtState;
    assign dummy.uOP    = NOP_U;
    assign dummy.valid  = `FALSE;

    assign mulResSgn    = ~(rs0SgnPipe[`MDU_MUL_CYCLE - 1] ^  rs1SgnPipe[`MDU_MUL_CYCLE - 1]);
    assign quotientSgn  = ~(rs0SgnPipe[`MDU_DIV_CYCLE - 1] ^  rs1SgnPipe[`MDU_DIV_CYCLE - 1]);
    assign remainderSgn = ~(rs0SgnPipe[`MDU_DIV_CYCLE - 1]);

    assign mulRes       = mulPipeHi[0].uOP == MULTHI_U && ~mulResSgn    ? ~mulResUnsigned + 1'b1 : mulResUnsigned;
    assign quotient     = divPipeHi[0].uOP == DIVHI_U  && ~quotientSgn  ? ~quotientU      + 1'b1 : quotientU     ;
    assign remainder    = divPipeHi[0].uOP == DIVHI_U  && ~remainderSgn ? ~remainderU     + 1'b1 : remainderU    ;

    assign dividend     = uopHi.uOP == DIVHI_U && rdata.rs0_data[31]  ? ~rdata.rs0_data + 1 : rdata.rs0_data;
    assign dividor      = uopHi.uOP == DIVHI_U && rdata.rs1_data[31]  ? ~rdata.rs1_data + 1 : rdata.rs1_data;
    assign multA        = uopHi.uOP == MULTHI_U && rdata.rs0_data[31]  ? ~rdata.rs0_data + 1 : rdata.rs0_data;
    assign multB        = uopHi.uOP == MULTHI_U && rdata.rs1_data[31]  ? ~rdata.rs1_data + 1 : rdata.rs1_data;

    Divider_IP divider_i(
        .aclk                   (clk                    ),
        .aresetn                (~rst && ~ctrl_mdu.flush),
        .s_axis_divisor_tvalid  (`TRUE                  ),  
        .s_axis_divisor_tdata   (dividor                ),    
        .s_axis_dividend_tvalid (`TRUE                  ),
        .s_axis_dividend_tdata  (dividend               ),  
        // .m_axis_dout_tvalid     (m_axis_dout_tvalid),        
        .m_axis_dout_tdata      ({quotientU, remainderU})           
    );

    Multiplier_IP multiplier_i(
        .CLK                    (clk                    ),
        .A                      (multA                  ),    
        .B                      (multB                  ),    
        .P                      (mulResUnsigned         ),
        .SCLR                   (rst || ctrl_mdu.flush )     
    );

    always_ff @ (posedge clk) begin
        if(rst || ctrl_mdu.flush) begin
            for(integer i = 0; i <= `MDU_MUL_CYCLE; i++) begin
                mulPipeHi[i]      <= 0;
                mulPipeLo[i]      <= 0;
            end
            for(integer i = 0; i <= `MDU_DIV_CYCLE; i++) begin
                divPipeHi[i]      <= 0;
                divPipeLo[i]      <= 0;
            end
            rs0SgnPipe <= 0;
            rs1SgnPipe <= 0;
        end else begin
            for(integer i = 0; i < `MDU_MUL_CYCLE; i++) begin
                mulPipeHi[i] <= mulPipeHi[i + 1];
                mulPipeLo[i] <= mulPipeLo[i + 1];
            end
            // mulPipeHi[`MDU_MUL_CYCLE - 1] <= (uopHi.uOP == MULTHI_U || uopHi.uOP == MULTUHI_U) ? uopHi : dummy;
            // mulPipeLo[`MDU_MUL_CYCLE - 0] <= (uopLo.uOP == MULTLO_U || uopLo.uOP == MULTULO_U) ? uopLo : dummy;
            if (uopHi.uOP == MULTHI_U || uopHi.uOP == MULTUHI_U) begin
                mulPipeHi[`MDU_MUL_CYCLE - 1] <= uopHi;
                mulPipeLo[`MDU_MUL_CYCLE - 0] <= uopLo;
            end else begin
                mulPipeHi[`MDU_MUL_CYCLE - 1] <= dummy;
                mulPipeLo[`MDU_MUL_CYCLE - 0] <= dummy;
            end
            for(integer i = 0; i < `MDU_DIV_CYCLE; i++) begin
                divPipeHi[i] <= divPipeHi[i + 1];
                divPipeLo[i] <= divPipeLo[i + 1];
            end
            // divPipeHi[`MDU_DIV_CYCLE - 1] <= (uopHi.uOP ==  DIVHI_U || uopHi.uOP ==  DIVUHI_U) ? uopHi : dummy;
            // divPipeLo[`MDU_DIV_CYCLE - 0] <= (uopLo.uOP ==  DIVLO_U || uopLo.uOP ==  DIVULO_U) ? uopLo : dummy;
            if (uopHi.uOP == DIVHI_U || uopHi.uOP == DIVUHI_U) begin
                divPipeHi[`MDU_DIV_CYCLE - 1] <= uopHi;
                divPipeLo[`MDU_DIV_CYCLE - 0] <= uopLo;
            end else begin
                divPipeHi[`MDU_DIV_CYCLE - 1] <= dummy;
                divPipeLo[`MDU_DIV_CYCLE - 0] <= dummy;
            end

            rs0SgnPipe <= {rs0SgnPipe[30:0], rdata.rs0_data[31] && uopHi.valid};
            rs1SgnPipe <= {rs1SgnPipe[30:0], rdata.rs1_data[31] && uopHi.valid};
        end
    end

    always_comb begin
        case(state)
            mulOutputHi: begin
                if(rst || ctrl_mdu.flush) begin
                    nxtState = idle;
                end else begin
                    nxtState = mulOutputLo;
                end
            end
            divOutputHi: begin
                if(rst || ctrl_mdu.flush) begin
                    nxtState = idle;
                end else begin
                    nxtState = divOutputLo;
                end
            end
            mulOutputLo ,
            divOutputLo ,
            idle        : begin
                if(rst || ctrl_mdu.flush) begin
                    nxtState = idle;
                end else if(mulPipeHi[1].valid) begin
                    nxtState = mulOutputHi;
                end else if(divPipeHi[1].valid) begin
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
        if(rst || ctrl_mdu.flush) begin
            state       <= idle;
            divLo       <= 0;
            mulLo       <= 0; 
        end else begin
            state       <= nxtState;
            // divLo       <= state == divOutputHi ? quotient      : divLo;
            if (state == divOutputHi)   divLo <= quotient;
            else                        divLo <= divLo;
            // mulLo       <= state == mulOutputHi ? mulRes[31:0]  : mulLo;       
            if (state == mulOutputHi)   mulLo <= mulRes[31:0];
            else                        mulLo <= mulLo;       
        end
    end

    always_comb begin
        mdu_rob.id = 0;
        wbData     = 0;
        case(state)
            idle: begin
                wbData.wen          = `FALSE;
                wbData.rd           = 32'h0;
                wbData.wdata        = 32'h0;
                mdu_rob.setFinish   = `FALSE;
            end
            mulOutputHi: begin
                wbData.wen          = `TRUE;
                wbData.rd           = mulPipeHi[0].dstPAddr;
                wbData.wdata        = mulRes[63:32];
                mdu_rob.setFinish   = `TRUE;
                mdu_rob.id          = mulPipeHi[0].id;
            end
            mulOutputLo: begin
                wbData.wen          = `TRUE;
                wbData.rd           = mulPipeLo[0].dstPAddr;
                wbData.wdata        = mulLo;
                mdu_rob.setFinish   = `TRUE;
                mdu_rob.id          = mulPipeLo[0].id;
            end
            divOutputHi: begin
                wbData.wen          = `TRUE;
                wbData.rd           = divPipeHi[0].dstPAddr;
                wbData.wdata        = remainder;
                mdu_rob.setFinish   = `TRUE;
                mdu_rob.id          = divPipeHi[0].id;
            end
            divOutputLo: begin
                wbData.wen          = `TRUE;
                wbData.rd           = divPipeLo[0].dstPAddr;
                wbData.wdata        = divLo;
                mdu_rob.setFinish   = `TRUE;
                mdu_rob.id          = divPipeLo[0].id;
            end
            default: begin
                wbData.wen          = `FALSE;
                mdu_rob.setFinish   = `FALSE;
            end
        endcase
    end
endmodule
