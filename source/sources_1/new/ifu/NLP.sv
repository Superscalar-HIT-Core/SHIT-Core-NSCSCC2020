`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/10 20:28:02
// Design Name: 
// Module Name: NLP
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
`include "../defs.sv"

module NLP(
    Regs_NLP.nlp    regs_nlp,
    NLP_IF0.nlp     nlp_if0,

    NLPUpdate.nlp   if3_nlp,
    NLPUpdate.nlp   backend_nlp
);
// fake nlp for now

    assign nlp_if0.nlpInfo0.valid = `FALSE;
    assign nlp_if0.nlpInfo1.valid = `FALSE;

endmodule
