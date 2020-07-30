`timescale 1ns / 1ps
`include "../defines/defines.svh"
// `define DISABLE_NLP

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

    // fixed 16 entry
    NLPEntry            data        [15:0];
    logic       [3:0]   currentHead;
    logic               backendUpdateMatch;
    logic               if3UpdateMatch;
    logic               req0Found;
    logic               req1Found;

    always_comb begin
`ifndef DISABLE_NLP
        req0Found = `FALSE;
        req1Found = `FALSE;
        for(integer i = 0; i < 16; i++) begin
            if(data[i].valid && data[i].pc == (regs_nlp.PC & 32'hffff_fffc)) begin
                nlp_if0.nlpInfo0.target     = data[i].targetAddr;
                nlp_if0.nlpInfo0.bimState   = data[i].bimState;
                nlp_if0.nlpInfo0.valid      = `TRUE;
                nlp_if0.nlpInfo0.taken      = data[i].bimState[1];
                req0Found                   = `TRUE;
                break;
            end
        end
        for(integer i = 0; i < 16; i++) begin
            if(data[i].valid && data[i].pc == (regs_nlp.PC | 32'h0000_0004)) begin
                nlp_if0.nlpInfo1.target     = data[i].targetAddr;
                nlp_if0.nlpInfo1.bimState   = data[i].bimState;
                nlp_if0.nlpInfo1.valid      = `TRUE;
                nlp_if0.nlpInfo1.taken      = data[i].bimState[1];
                req1Found                   = `TRUE;
                break;
            end
        end

        if(!req0Found) begin
            nlp_if0.nlpInfo0 = 0;
        end

        if(!req1Found) begin
            nlp_if0.nlpInfo1 = 0;
        end

        backendUpdateMatch  = `FALSE;
        if3UpdateMatch      = `FALSE;
        for(integer i = 0; i < 16; i++) begin
            if(data[i].valid && data[i].pc == backend_nlp.update.pc) begin
                backendUpdateMatch  = `TRUE;
            end
            if(data[i].valid && data[i].pc == if3_nlp.update.pc) begin
                if3UpdateMatch      = `TRUE;
            end
        end
`else
        nlp_if0.nlpInfo0.target     = 0;
        nlp_if0.nlpInfo0.bimState   = 0;
        nlp_if0.nlpInfo0.valid      = `FALSE;
        nlp_if0.nlpInfo0.taken      = 0;
        nlp_if0.nlpInfo1.target     = 0;
        nlp_if0.nlpInfo1.bimState   = 0;
        nlp_if0.nlpInfo1.valid      = `FALSE;
        nlp_if0.nlpInfo1.taken      = 0;
`endif
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            currentHead <= 0;
            for(integer i = 0; i < 16; i++) data[i] <= 0;
        end 
        else begin
            if (if3_nlp.update.valid && if3UpdateMatch) begin
                for(integer i = 0; i < 16; i++) begin
                    if(data[i].valid && data[i].pc == if3_nlp.update.pc) begin
                        data[i].targetAddr     = if3_nlp.update.target;
                        if(if3_nlp.update.shouldTake) begin
                            data[i].bimState   = if3_nlp.update.bimState == 2'b11 ? 2'b11 : if3_nlp.update.bimState + 1;
                        end else begin
                            data[i].bimState   = if3_nlp.update.bimState == 2'b00 ? 2'b00 : if3_nlp.update.bimState - 1;
                        end
                        break;
                    end
                end
            end else if(if3_nlp.update.valid && !if3UpdateMatch) begin
                data[currentHead].valid         <= `TRUE;
                data[currentHead].pc            <= if3_nlp.update.pc;
                data[currentHead].bimState      <= if3_nlp.update.bimState;
                data[currentHead].targetAddr    <= if3_nlp.update.target;
            end

            if (backend_nlp.update.valid && backendUpdateMatch) begin
                for(integer i = 0; i < 16; i++) begin
                    if(data[i].valid && data[i].pc == backend_nlp.update.pc) begin
                        data[i].targetAddr     = backend_nlp.update.target;
                        if(backend_nlp.update.shouldTake) begin
                            data[i].bimState   = backend_nlp.update.bimState == 2'b11 ? 2'b11 : backend_nlp.update.bimState + 1;
                        end else begin
                            data[i].bimState   = backend_nlp.update.bimState == 2'b00 ? 2'b00 : backend_nlp.update.bimState - 1;
                        end
                        break;
                    end
                end
            end else if(backend_nlp.update.valid && !backendUpdateMatch) begin
                data[currentHead].valid         <= `TRUE;
                data[currentHead].pc            <= backend_nlp.update.pc;
                data[currentHead].bimState      <= backend_nlp.update.bimState;
                data[currentHead].targetAddr    <= backend_nlp.update.target;
            end

            if(if3_nlp.update.valid && !if3UpdateMatch && backend_nlp.update.valid && !backendUpdateMatch) begin
                currentHead <= currentHead + 2;
            end else if ((backend_nlp.update.valid && !backendUpdateMatch) || (if3_nlp.update.valid && !if3UpdateMatch)) begin
                currentHead <= currentHead + 1;
            end else begin
                currentHead <= currentHead;
            end
        end
    end


endmodule
