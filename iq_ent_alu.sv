`timescale 1ns / 1ps
`define ALU_OP_WIDTH 4
`define PRF_NUM_WIDTH 6
module iq_ent_alu(
    input clk,
    input rst,
    input wen,  // 写该项
    input [31:0] pc_i,  // 指令的PC
    // 只保存寄存器的编号，寄存器的值发射的时候再给
    input [`PRF_NUM_WIDTH-1:0] prf_rs_1_i,  
    input [`PRF_NUM_WIDTH-1:0] prf_rs_2_i,
    // 需要读寄存器
    input r_rs1_i,
    input r_rs2_i,
    input [`PRF_NUM_WIDTH-1:0] prf_rd_i,
    input [`PRF_NUM_WIDTH-1:0] prf_rd_stale_i,
    input wen_rd_i,
    input [31:0] imm_i, 
    // 进入队列的时候输入的，寄存器是否可用
    // 进入的时候同时也需要考虑旁路的因素
    input prf_rs_1_rdy_i, 
    input prf_rs_2_rdy_i,
    input [`ALU_OP_WIDTH-1:0] alu_op_i,
    input is_ds_i, // 是否为延迟槽指令
    input is_special_i,  // 是否是特殊的指令，例如CP0等等，需要单独的发射
    input selected,    // 被仲裁机构选中
    // 旁路信息(4个写寄存器的编号，进入时和在队列中都会监测)
    input [`PRF_NUM_WIDTH-1:0] wb_num0_i, wb_num1_i, wb_num2_i, wb_num3_i,  
    
    output reg [31:0] pc_o,
    output reg [`PRF_NUM_WIDTH-1:0] prf_rs_1_o,
    output reg [`PRF_NUM_WIDTH-1:0] prf_rs_2_o,
    output reg r_rs1_o,
    output reg r_rs2_o,
    output reg [`PRF_NUM_WIDTH-1:0] prf_rd_o,
    output reg [`PRF_NUM_WIDTH-1:0] prf_rd_stale_o,
    output reg wen_rd_o,
    output reg [31:0] imm_o,
    output reg [`ALU_OP_WIDTH-1:0] alu_op_o,
    output reg is_ds_o,
    output reg is_special_o,
    output reg rdy,         // 操作数准备好发射
    output reg valid        // 是否空闲
    );

always @(posedge clk)   begin
   if(rst)  begin
       pc_o <= 32'b0;
       prf_rs_1_o <= 6'b0;
       prf_rs_2_o <= 6'b0;
       prf_rd_o <= 6'b0;
       wen_rd_o <= 1'b0;
       imm_o <= 32'b0;
       valid <= 1'b0;
       is_ds_o <= 1'b0;
       is_special_o <= 1'b0;
       alu_op_o <= `ALU_OP_WIDTH'b0;
       prf_rd_stale_o <= 6'b0;
       r_rs1_o <= 1'b0;
       r_rs2_o <= 1'b0; 
   end else if(wen) begin
       pc_o <= pc_i;
       prf_rs_1_o <= prf_rs_1_i;
       prf_rs_2_o <= prf_rs_2_i;
       prf_rd_o <= prf_rd_i;
       wen_rd_o <= wen_rd_i;
       imm_o <= imm_i;
       alu_op_o <= alu_op_i;
       prf_rd_stale_o <= prf_rd_stale_i;
       r_rs1_o <= r_rs1_i;
       r_rs2_o <= r_rs2_i;
       is_ds_o <= is_ds_i;
       is_special_o <= is_special_i;
       valid <= 1'b1;
   end else if(selected)    begin
       valid <= 1'b0;
   end
end

// 在队列中作比较
wire rs1_bypass_rdy_inqueue =   ( wb_num0_i == prf_rs_1_o ) || 
                                ( wb_num1_i == prf_rs_1_o ) ||
                                ( wb_num2_i == prf_rs_1_o ) ||
                                ( wb_num3_i == prf_rs_1_o ) || 
                                ( ~r_rs1_o );

wire rs2_bypass_rdy_inqueue =   ( wb_num0_i == prf_rs_2_o ) || 
                                ( wb_num1_i == prf_rs_2_o ) ||
                                ( wb_num2_i == prf_rs_2_o ) ||
                                ( wb_num3_i == prf_rs_2_o ) ||
                                ( ~r_rs2_o );

// 进入时作比较
wire rs1_bypass_rdy_atentry =   ( wb_num0_i == prf_rs_1_i ) || 
                                ( wb_num1_i == prf_rs_1_i ) ||
                                ( wb_num2_i == prf_rs_1_i ) ||
                                ( wb_num3_i == prf_rs_1_i ) ||
                                ( ~r_rs1_i );

wire rs2_bypass_rdy_atentry =   ( wb_num0_i == prf_rs_2_i ) || 
                                ( wb_num1_i == prf_rs_2_i ) ||
                                ( wb_num2_i == prf_rs_2_i ) ||
                                ( wb_num3_i == prf_rs_2_i ) ||
                                ( ~r_rs2_i );

// 不读寄存器，永远是ready，否则需要入口判断
wire rs1_rdy_atentry = ( ~r_rs1_i ) || ( r_rs1_i && prf_rs_1_rdy_i ) || rs1_bypass_rdy_atentry ;  
wire rs2_rdy_atentry = ( ~r_rs2_i ) || ( r_rs2_i && prf_rs_2_rdy_i ) || rs2_bypass_rdy_atentry ;

reg rs1_rdy,rs2_rdy;

always @(posedge clk)   begin
    if(rst) begin
        rs1_rdy <= 1'b0;
    end else if( wen && rs1_rdy_atentry ) begin     // 进入队列
        rs1_rdy <= 1'b1;
    end else if( valid && !rs1_rdy && rs1_bypass_rdy_inqueue ) begin // 在队列中
        rs1_rdy <= 1'b1;
    end else if( selected )   begin // 发射出去
        rs1_rdy <= 1'b0;
    end
end

always @(posedge clk)   begin
    if(rst) begin
        rs2_rdy <= 1'b0;
    end else if( wen && rs2_rdy_atentry ) begin     // 进入队列
        rs2_rdy <= 1'b1;
    end else if( valid && !rs2_rdy && rs2_bypass_rdy_inqueue ) begin // 在队列中
        rs2_rdy <= 1'b1;
    end else if( selected )   begin // 发射出去
        rs2_rdy <= 1'b0;
    end
end

assign rdy = rs1_rdy && rs2_rdy && valid;

endmodule
