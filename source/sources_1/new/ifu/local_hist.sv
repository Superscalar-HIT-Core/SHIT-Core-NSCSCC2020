
`timescale 1ns / 1ps
`include "../defines/defines.svh"

module LocalHistPredictor(
    input clk,
    input rst,
    input [31:0] br_PC,
    output LocalHistPred pred_info,
    output BHREntry bhr,
    output pred_taken,
    input commit_update,
    input LocalHistPred committed_pred_info,
    input committed_taken,
    output reg [31:0] br_PC_out
);
    // 2 Pipeline stage
    // 1 Cycle Delay
    // Output is not registered
    // 2级流水化访问

    // Stage 1: BHT access and get BHR 
    BHTIndex bht_index, bht_index_r;
    BHREntry [255:0] BHT;
    BHREntry current_bhr;
    PHTEntry [1023:0] PHT;
    PHTEntry current_ph;
    assign current_bhr = BHT[bht_index];
    PHTIndex pht_index,pht_index_r;

    // Hash Function?
    assign bht_index = br_PC[10:3] ^ br_PC[18:11];
    assign pht_index = br_PC[12:3] ^ current_bhr; // TODO

    // Pipeline Register
    always @(posedge clk)   begin
        if(rst) begin
            pht_index_r <= 0;
            bhr <= 0;
            br_PC_out <= 0;
            bht_index_r <= 0;
        end else begin
            pht_index_r <= pht_index;
            bhr <= current_bhr;
            br_PC_out <= br_PC;
            bht_index_r <= bht_index;
        end
    end

    // Stage 2: PHT access and get two bit counter, output the prediction result
    assign current_ph = PHT[pht_index_r];
    assign pred_taken = current_ph[1];
    assign pred_info.bht_index = bht_index_r;
    assign pred_info.pht_index = pht_index_r;


    // Update logic
    PHTEntry pht_inc;
    PHTEntry pht_dec;
    BHREntry bhr_new;

    assign pht_inc = PHT[committed_pred_info.pht_index] == 2'b11 ? 2'b11 : PHT[committed_pred_info.pht_index] + 2'b01;
    assign pht_dec = PHT[committed_pred_info.pht_index] == 2'b00 ? 2'b00 : PHT[committed_pred_info.pht_index] - 2'b01;
    assign bhr_new = { BHT[committed_pred_info.bht_index][`BHRLEN-2:0], committed_taken };
    always @(posedge clk)   begin
        if(rst) begin
            for(integer i=0;i<1024;i++) begin
                PHT[i] <= 0;
            end
            for(integer i=0;i<256;i++) begin
                BHT[i] <= 0;
            end
        end else if(commit_update) begin
            PHT[committed_pred_info.pht_index] <= committed_taken ? pht_inc : pht_dec;
            BHT[committed_pred_info.bht_index] <= bhr_new;
        end
    end


endmodule