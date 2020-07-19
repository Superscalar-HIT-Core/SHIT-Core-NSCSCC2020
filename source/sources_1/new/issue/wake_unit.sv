`timescale 1ns / 1ps
`include "../defines/defines.svh"

module wake_unit(
    input clk,
    input rst,
    input flush,
    input PRFNum wake_reg_ALU_0, wake_reg_ALU_1, wake_reg_LSU, wake_reg_MDU,
    input wake_reg_ALU_0_en, wake_reg_ALU_1_en, wake_reg_LSU_en, wake_reg_MDU_en,
    output Wake_Info wake_info_to_ALU, 
    output Wake_Info wake_info_to_LSU, 
    output Wake_Info wake_info_to_MDU
    );

// To ALU
assign wake_info_to_ALU.wb_num0_i = wake_reg_ALU_0;
assign wake_info_to_ALU.wb_num1_i = wake_reg_ALU_1;
assign wake_info_to_ALU.wb_num2_i = wake_reg_LSU;
assign wake_info_to_ALU.wb_num3_i = wake_reg_MDU;

assign wake_info_to_ALU.wen_0 = wake_reg_ALU_0_en;
assign wake_info_to_ALU.wen_1 = wake_reg_ALU_1_en;
assign wake_info_to_ALU.wen_2 = wake_reg_LSU_en;
assign wake_info_to_ALU.wen_3 = wake_reg_MDU_en;

assign wake_info_to_LSU.wb_num0_i = wake_reg_ALU_0;
assign wake_info_to_LSU.wb_num1_i = wake_reg_ALU_1;
assign wake_info_to_LSU.wb_num2_i = wake_reg_LSU;
assign wake_info_to_LSU.wb_num3_i = wake_reg_MDU;

assign wake_info_to_LSU.wen_0 = wake_reg_ALU_0_en;
assign wake_info_to_LSU.wen_1 = wake_reg_ALU_1_en;
assign wake_info_to_LSU.wen_2 = wake_reg_LSU_en;
assign wake_info_to_LSU.wen_3 = wake_reg_MDU_en;

assign wake_info_to_MDU.wb_num0_i = wake_reg_ALU_0;
assign wake_info_to_MDU.wb_num1_i = wake_reg_ALU_1;
assign wake_info_to_MDU.wb_num2_i = wake_reg_LSU;
assign wake_info_to_MDU.wb_num3_i = wake_reg_MDU;

assign wake_info_to_MDU.wen_0 = wake_reg_ALU_0_en;
assign wake_info_to_MDU.wen_1 = wake_reg_ALU_1_en;
assign wake_info_to_MDU.wen_2 = wake_reg_LSU_en;
assign wake_info_to_MDU.wen_3 = wake_reg_MDU_en;
// always_ff @(posedge clk) begin
//     if(rst || flush)    begin
//         wake_info_dly_1cyc <= 0;
//         wake_info_dly_2cyc <= 0;
//     end else begin
//         wake_info_dly_1cyc <= wake_info;
//         wake_info_dly_2cyc <= wake_info_dly_1cyc;
//     end
// end

endmodule
