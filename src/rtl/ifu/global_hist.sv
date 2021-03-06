`timescale 1ns / 1ps
`include "../defines/defines.svh"

module GlobalHistPredictor(
    input clk,
    input rst,
    input recover,
    input pause,
    input [31:0] br_PC,
    output GlobalHistPred pred_info,
    output pred_valid,
    output GlobalHist ghist,
    output pred_taken,
    input pred_valid_local,
    input pred_taken_local,
    input commit_update,
    input GlobalHistPred committed_pred_info,
    input committed_taken
);
    // 2 Pipeline stage
    // 1 Cycle Delay
    // Output is not registered
    GlobalHist ghist_committed;
    PHTEntry [4095:0] PHT;
    PHTEntry current_ph;
    PHTIndex_G pht_index, pht_index_r;
    assign pht_index = ghist[1:0] ^ br_PC[11:0]; // TODO

    // Pipeline Register
    always @(posedge clk)   begin
        if(rst) begin
            pht_index_r <= 0;
        end else if(~pause) begin
            pht_index_r <= pht_index;
        end
    end
    
    assign current_ph = PHT[pht_index_r];
    assign pred_taken = current_ph[1];
    assign pred_valid = valid[pht_index_r];
    assign pred_info.pht_index_g = pht_index_r;


    PHTEntry pht_inc;
    PHTEntry pht_dec;

    assign pht_inc = PHT[committed_pred_info.pht_index_g] == 2'b11 ? 2'b11 : PHT[committed_pred_info.pht_index_g] + 2'b01;
    assign pht_dec = PHT[committed_pred_info.pht_index_g] == 2'b00 ? 2'b00 : PHT[committed_pred_info.pht_index_g] - 2'b01;
    
    
    reg [4095:0] valid;
    // Update of global history(speculatively)
    always @(posedge clk)   begin
        if(rst) begin
            ghist <= 0;
        end else if(recover) begin
            ghist <= ghist_committed;
        end else if(pred_valid_local && ~pause) begin
            ghist <= { ghist[`GHLEN-2:0], pred_taken_local };
        end
    end
    // Update the committed global history
    always @(posedge clk)   begin
        if(rst) begin
            ghist_committed <= 0;
        end else if(commit_update) begin
            ghist_committed <= { ghist_committed[`GHLEN-2:0], committed_taken };
        end
    end
    // Update logic
    always @(posedge clk)   begin
        if(rst) begin
            for(integer i=0;i<4096;i++) begin
                PHT[i] <= 0;
            end
            valid <= 0;
        end else if(commit_update) begin
            PHT[committed_pred_info.pht_index_g] <= committed_taken ? pht_inc : pht_dec;
            valid[committed_pred_info.pht_index_g] <= 1'b1;
        end
    end

endmodule