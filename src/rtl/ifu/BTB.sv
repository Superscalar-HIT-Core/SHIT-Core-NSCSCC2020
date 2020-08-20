`timescale 1ns / 1ps
`include "../defines/defines.svh"

module BTB(
    input wire              clk,
    input wire              rst,
    input [31:0]            br_PC,
    output [31:0]           pred_target,
    output                  pred_valid,
    output BTBIndex         pred_btb_index,
    input BHREntry          BHR,
    input                   commit_update_en,
    input BTBIndex          commit_update_index,
    input [31:0]            commit_update_target
    );  
    // Target Cache, using lower history bits as the index
    reg [31:0] Branch_Targets[255:0];
    assign pred_btb_index = br_PC[10:3] ^ BHR;
    assign pred_target = Branch_Targets[pred_btb_index];
    reg [255:0] valid;
    always_ff @(posedge clk)    begin
        if(rst) begin
            for(integer i=0; i<256; i++)   begin
                Branch_Targets[i] <= 32'b0;
            end 
            valid <= 0;
        end else if(commit_update_en) begin
            Branch_Targets[commit_update_index] <= commit_update_target;
            valid[commit_update_index] <= 1'b1;
        end
    end
    
endmodule