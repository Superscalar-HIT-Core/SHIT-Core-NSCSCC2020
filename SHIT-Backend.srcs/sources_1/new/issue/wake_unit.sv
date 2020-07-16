`timescale 1ns / 1ps
`include "../defines/defines.svh"

module wake_unit(
    input PRFNum wake_reg_0, wake_reg_1, wake_reg_2, wake_reg_3,
    input wake_reg_0_en, wake_reg_1_en, wake_reg_2_en, wake_reg_3_en,
    output Wake_Info wake_Info
    );
    assign wake_Info.wb_num0_i = wake_reg_0;
    assign wake_Info.wb_num1_i = wake_reg_1;
    assign wake_Info.wb_num2_i = wake_reg_2;
    assign wake_Info.wb_num3_i = wake_reg_3;

    assign wake_Info.wen_0 = wake_reg_0_en;
    assign wake_Info.wen_1 = wake_reg_1_en;
    assign wake_Info.wen_2 = wake_reg_2_en;
    assign wake_Info.wen_3 = wake_reg_3_en;
endmodule
