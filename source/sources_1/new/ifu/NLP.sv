`timescale 1ns / 1ps
`include "../defs.sv"

module NLP(
    input wire clk,
    input wire rst,

    Regs_NLP.nlp    regs_nlp,
    NLP_IF0.nlp     nlp_if0,

    NLPUpdate.nlp   if3_nlp,
    NLPUpdate.nlp   backend_nlp,

    Ctrl.slave      ctrl_nlp
);
// fake nlp for now

    logic [         31 : 0] target      [`NLP_SIZE-1 : 0];
    logic [          1 : 0] bimState    [`NLP_SIZE-1 : 0];
    logic [`NLP_SIZE-1 : 0] valid;

    logic [         31 : 0] pc0;
    logic [         31 : 0] pc1;

    assign pc0 = regs_nlp.PC;
    assign pc1 = regs_nlp.PC + 4;

    always_ff @ (posedge clk) begin
        if(rst || ctrl_nlp.flush) begin
            valid <= `NLP_SIZE'h0;
        end else begin
            if(backend_nlp.update.valid) begin
                target[backend_nlp.update.pc[`NLP_PC]] <= backend_nlp.update.target;
                if(backend_nlp.update.shouldTake) begin
                    bimState[backend_nlp.update.pc[`NLP_PC]] 
                        <= backend_nlp.update.bimState == 2'b11 ? 2'b11 : backend_nlp.update.bimState + 1'b1;
                end else begin
                    bimState[backend_nlp.update.pc[`NLP_PC]] 
                        <= backend_nlp.update.bimState == 2'b00 ? 2'b00 : backend_nlp.update.bimState - 1'b1;
                end
                valid[backend_nlp.update.pc[`NLP_PC]] = 1'b1;
            end
            if(if3_nlp.update.valid && if3_nlp.update.pc[`NLP_PC] != backend_nlp.update.pc[`NLP_PC]) begin
                target[if3_nlp.update.pc[`NLP_PC]] <= if3_nlp.update.target;
                if(if3_nlp.update.shouldTake) begin
                    bimState[if3_nlp.update.pc[`NLP_PC]] 
                        <= if3_nlp.update.bimState == 2'b11 ? 2'b11 : if3_nlp.update.bimState + 1'b1;
                end else begin
                    bimState[if3_nlp.update.pc[`NLP_PC]] 
                        <= if3_nlp.update.bimState == 2'b00 ? 2'b00 : if3_nlp.update.bimState - 1'b1;
                end
                valid[if3_nlp.update.pc[`NLP_PC]] = 1'b1;
            end
        end
    end

    assign nlp_if0.nlpInfo0.valid    = valid    [pc0[`NLP_PC]];
    assign nlp_if0.nlpInfo0.target   = target   [pc0[`NLP_PC]];
    assign nlp_if0.nlpInfo0.taken    = bimState [pc0[`NLP_PC]][1];
    assign nlp_if0.nlpInfo0.bimState = bimState [pc0[`NLP_PC]];

    assign nlp_if0.nlpInfo1.valid    = valid    [pc1[`NLP_PC]];
    assign nlp_if0.nlpInfo1.target   = target   [pc1[`NLP_PC]];
    assign nlp_if0.nlpInfo1.taken    = bimState [pc1[`NLP_PC]][1];
    assign nlp_if0.nlpInfo1.bimState = bimState [pc1[`NLP_PC]];
endmodule
