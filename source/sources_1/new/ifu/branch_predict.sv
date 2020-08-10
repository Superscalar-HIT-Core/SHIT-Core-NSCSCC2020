`timescale 1ns / 1ps
`include "../defines/defines.svh"
module Predictor(
    input clk,
    input rst,
    input pause,
    input hold,
    // Recover must be delayed for 1 cycle in case of flushing the newly committed history
    input recover,
    input [31:0] br_PC,
    input IF3_isBR,
    input IF3_isJ,
    output reg pred_valid,
    output PredInfo pred_info,
    output reg pred_taken,
    output reg [31:0] pred_target,
    input commit_valid,
    input PredInfo committed_pred_info,
    input committed_branch_taken,
    input committed_mispred,
    input commit_update_target_en,
    input [31:0] committed_target
    // For RAS
    // input IF3_isLink,
    // input IF3_isReturn,
    // input [31:0] IF3_LinkPC,
    // output reg [31:0] IF3_ReturnPC,
    // input committed_isLink,
    // input committed_isReturn,
    // input commmit_valid,
    // input [31:0] commit_LinkPC
);  
    reg         commit_valid_r;
    PredInfo    committed_pred_info_r;
    reg         committed_branch_taken_r;
    reg         committed_mispred_r;
    reg         commit_update_target_en_r;
    reg[31:0]   committed_target_r;

    always @(posedge clk)  begin
        if(rst) begin
            commit_valid_r                  <= 0;
            committed_pred_info_r           <= 0;
            committed_branch_taken_r        <= 0;
            committed_mispred_r             <= 0;
            commit_update_target_en_r       <= 0;
            committed_target_r              <= 0;
        end else begin
            commit_valid_r                  <= commit_valid           ;
            committed_pred_info_r           <= committed_pred_info    ;
            committed_branch_taken_r        <= committed_branch_taken ;
            committed_mispred_r             <= committed_mispred      ;
            commit_update_target_en_r       <= commit_update_target_en;
            committed_target_r              <= committed_target       ;
        end
    end

    GlobalHistPred pred_info_global_o;
    LocalHistPred pred_info_local_o;
    BHREntry bhr;
    GlobalHist ghist;
    wire pred_taken_global, pred_taken_local;
    CPHTIndex CPHT_index, CPHT_index_update;
    CPHT_Entry [1023:0] CPHT;
    wire [31:0] br_PC_dly;
    LocalHistPred committed_pred_info_local;
    assign committed_pred_info_local.bht_index = committed_pred_info_r.bht_index;
    assign committed_pred_info_local.pht_index = committed_pred_info_r.pht_index;
    wire pred_direction_valid, pred_address_valid;
    LocalHistPredictor localhist(
        .clk(clk),
        .rst(rst),
        .pause(pause),
        .br_PC(br_PC),
        .pred_info(pred_info_local_o),
        .bhr(bhr),
        .pred_taken(pred_taken_local),
        .commit_update(commit_valid_r),
        .committed_pred_info(committed_pred_info_local),
        .committed_taken(committed_branch_taken_r),
        .br_PC_out(br_PC_dly)
    );
    wire [31:0] pred_target_o;
    wire [9:0] btb_index_o;
    BTB btb(
        .clk(clk),
        .rst(rst),
        .br_PC(br_PC_dly),
        .pred_valid(pred_address_valid),
        .pred_target(pred_target_o),
        .pred_btb_index(btb_index_o),
        .BHR(bhr),
        .commit_update_en(commit_valid_r && commit_update_target_en_r), // Only update for inderect branches
        .commit_update_index(committed_pred_info_r.btb_index),
        .commit_update_target(committed_target_r) 
    );
    // wire [31:0] IF3_ReturnPC_o;
    // RAS ras(
    //     .clk(clk),
    //     .rst(rst),
    //     .pause(pause),
    //     .recover(recover),
    //     .isLink(IF3_isLink),
    //     .isReturn(IF3_isReturn),
    //     .target(IF3_ReturnPC_o),
    //     .commit_valid_r(commit_valid_r),
    //     .committed_isLink(committed_isLink),
    //     .committed_isReturn(committed_isReturn),
    //     .committed_pc(commit_LinkPC)
    // );
    GlobalHistPred committed_pred_info_global;
    assign committed_pred_info_global.pht_index_g = committed_pred_info_r.pht_index_g;
    GlobalHistPredictor globalhist(
        .clk(clk),
        .rst(rst),
        .pause(pause),
        .pred_valid(pred_direction_valid),
        .br_PC(br_PC),
        .recover(recover),
        .pred_info(pred_info_global_o),
        .ghist(ghist),
        .pred_taken(pred_taken_global),
        // For updating global histroy
        .pred_valid_local( IF3_isBR || IF3_isJ ), 
        .pred_taken_local( pred_taken || IF3_isJ ),
        .commit_update(commit_valid_r),
        .committed_pred_info(committed_pred_info_global),
        .committed_taken(committed_branch_taken_r)
    );


    // Stage 2: Take the output and select the working predictor
    // Remove the useless CPHT
    // assign CPHT_index_update = committed_pred_info.cpht_index ;
    // assign CPHT_index= ghist[19:10] ^ ghist[9:0] ^ br_PC_dly[12:3];

    // always @(posedge clk)   begin
    //     if(rst) begin
    //         for(integer i = 0; i < 1024; i++)   begin
    //             CPHT[i] <= 0;
    //         end
    //     end else if(commit_valid_r) begin
    //         // TODO
    //         if(committed_pred_info.use_global && committed_mispred)   begin
    //             CPHT[CPHT_index_update] <= CPHT[CPHT_index_update] == 2'b00 ? 2'b00 : CPHT[CPHT_index_update] - 2'b01;
    //         end else begin
    //             CPHT[CPHT_index_update] <= CPHT[CPHT_index_update] == 2'b11 ? 2'b11 : CPHT[CPHT_index_update] + 2'b01;
    //         end
    //     end
    // end


    // Output is registered
    wire pred_taken_o, use_global_o;
    // assign pred_taken_o = CPHT[CPHT_index] == 1 ? pred_taken_global : pred_taken_local;
    // assign use_global_o = CPHT[CPHT_index] == 1;
    assign pred_taken_o = pred_taken_global;
    assign use_global_o = 1;
    // Output logic
    PredInfo pred_info_o;
    assign pred_info_o.bht_index = pred_info_local_o.bht_index;
    assign pred_info_o.pht_index = pred_info_local_o.pht_index;
    assign pred_info_o.pht_index_g = pred_info_global_o.pht_index_g;
    assign pred_info_o.cpht_index = 0;
    assign pred_info_o.use_global = use_global_o;
    assign pred_info_o.btb_index = btb_index_o;

    always @(posedge clk)   begin
        if(rst) begin
            pred_info <= 0;
            pred_taken <= 0;
            pred_target <= 0;
            pred_valid <= 0;
            // IF3_ReturnPC <= 0;
        end else if(~hold) begin
            pred_info <= pred_info_o;
            pred_taken <= pred_taken_o;
            pred_target <= pred_target_o;
            pred_valid <= pred_address_valid | pred_direction_valid;
            // IF3_ReturnPC <= IF3_ReturnPC_o;
        end
    end



endmodule