`timescale 1ns / 1ps
`include "../defines/defines.svh"
module Predictor(
    input clk,
    input rst,
    // 注意：此处的recover接的是regfile的recover，需要等分支指令提交进来了再进行恢复
    input recover,
    input [31:0] br_PC,
    input IF3_isBR,
    input IF3_isJ,
    output PredInfo pred_info,
    output reg pred_taken,
    input commit_valid,
    input PredInfo committed_pred_info,
    input [31:0] committed_target,
    input committed_branch_taken,
    input committed_mispred
);  
    // 虽然是竞争的分支预测，也�?要对两个进行更新
    // 两个具有�?周期延时的预测器
    GlobalHistPred pred_info_global_o;
    LocalHistPred pred_info_local_o;
    BHREntry bhr;
    GlobalHist ghist;
    wire pred_taken_global, pred_taken_local;
    CPHTIndex CPHT_index, CPHT_index_update;
    CPHT_Entry [1023:0] CPHT;
    wire [31:0] br_PC_dly;
    // 内部拥有1级的pipeline
    LocalHistPred committed_pred_info_local;
    assign committed_pred_info_local.bht_index = committed_pred_info.bht_index;
    assign committed_pred_info_local.pht_index = committed_pred_info.pht_index;
    LocalHistPredictor localhist(
        .clk(clk),
        .rst(rst),
        .br_PC(br_PC),
        .pred_info(pred_info_local_o),
        .bhr(bhr),
        .pred_taken(pred_taken_local),
        .commit_update(commit_valid),
        .committed_pred_info(committed_pred_info_local),
        .committed_taken(committed_branch_taken),
        .br_PC_out(br_PC_dly)
    );

    wire [31:0] pred_target_o;
    wire [9:0] btb_index_o;
    BTB btb(
        .clk(clk),
        .rst(rst),
        .br_PC(br_PC_dly),
        .pred_target(pred_target_o),
        .pred_btb_index(btb_index_o),
        .BHR(bhr),
        .commit_update(commit_valid),
        .commit_update_index(committed_pred_info.btb_index),
        .commit_update_target() 
    )
    GlobalHistPred committed_pred_info_global;
    assign committed_pred_info_global.pht_index_g = committed_pred_info.pht_index_g;
    GlobalHistPredictor globalhist(
        .clk(clk),
        .rst(rst),
        .br_PC(br_PC),
        .recover(recover),
        .pred_info(pred_info_global_o),
        .ghist(ghist),
        .pred_taken(pred_taken_global),
        // For updating global histroy
        .pred_valid_local(IF3_isBR || IF3_isJ),    // ToDo
        .pred_taken_local(pred_taken || IF3_isJ),
        .commit_update(commit_valid),
        .committed_pred_info(committed_pred_info_global),
        .committed_taken(committed_branch_taken)
    );


    // Stage 2: Take the output and select the working predictor

    assign CPHT_index_update = committed_pred_info.cpht_index ;
    assign CPHT_index= ghist[19:10] ^ ghist[9:0] ^ br_PC_dly[12:3];

    always @(posedge clk)   begin
        if(rst) begin
            for(integer i = 0; i < 1024; i++)   begin
                CPHT[i] <= 0;
            end
        end else if(commit_valid) begin
            // TODO
            if(committed_pred_info.use_global && committed_mispred)   begin
                CPHT[CPHT_index_update] <= CPHT[CPHT_index_update] == 2'b00 ? 2'b00 : CPHT[CPHT_index_update] - 2'b01;
            end else begin
                CPHT[CPHT_index_update] <= CPHT[CPHT_index_update] == 2'b11 ? 2'b11 : CPHT[CPHT_index_update] + 2'b01;
            end
        end
    end

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
    assign pred_info_o.cpht_index = CPHT_index;
    assign pred_info_o.use_global = use_global_o;
    assign pred_info_o.btb_index = btb_index_o;

    always @(posedge clk)   begin
        if(rst) begin
            pred_info <= 0;
            pred_taken <= 0;
        end else begin
            pred_info <= pred_info_o;
            pred_taken <= pred_taken_o;
        end
    end



endmodule