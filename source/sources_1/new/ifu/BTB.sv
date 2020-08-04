`timescale 1ns / 1ps
`include "../defines/defines.svh"

module BTB(
    input wire              clk,
    input wire              rst,
    input [31:0]            br_PC,
    output [31:0]           pred_target,
    output BTBIndex         pred_btb_index,
    input BHREntry          BHR,
    input                   commit_update,
    input BTBIndex          commit_update_index,
    input [31:0]            commit_update_target
    );
    // 4路组相联BTB
    // Target Cache
    reg [1023:0] Branch_Targets[31:0];
    assign pred_btb_index = br_PC[12:3] ^ BHR;
    assign pred_target = Branch_Targets[pred_btb_index];

    always_ff @(posedge clk)    begin
        if(rst) begin
            for(integer i=0; i<1024; i++)   begin
                Branch_Targets[i] <= 32'b0;
            end 
        end else if(commit_update) begin
                Branch_Target[commit_update_index] <= commit_update_target;
            end
        end
    end
    
endmodule