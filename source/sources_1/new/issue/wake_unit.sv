`timescale 1ns / 1ps
`include "../defines/defines.svh"

module wake_unit(
    input clk,
    input rst,
    input flush,
    input PRFNum wake_reg_0, wake_reg_1, wake_reg_2, wake_reg_3,
    input wake_reg_0_en, wake_reg_1_en, wake_reg_2_en, wake_reg_3_en,
    output Wake_Info wake_info,wake_info_dly_1cyc, wake_info_dly_2cyc
    );
assign wake_info.wb_num0_i = wake_reg_0;
assign wake_info.wb_num1_i = wake_reg_1;
assign wake_info.wb_num2_i = wake_reg_2;
assign wake_info.wb_num3_i = wake_reg_3;

assign wake_info.wen_0 = wake_reg_0_en;
assign wake_info.wen_1 = wake_reg_1_en;
assign wake_info.wen_2 = wake_reg_2_en;
assign wake_info.wen_3 = wake_reg_3_en;


always_ff @(posedge clk) begin
    if(rst || flush)    begin
        wake_info_dly_1cyc <= 0;
        wake_info_dly_2cyc <= 0;
    end else begin
        wake_info_dly_1cyc <= wake_info;
        wake_info_dly_2cyc <= wake_info_dly_1cyc;
    end
end

endmodule
