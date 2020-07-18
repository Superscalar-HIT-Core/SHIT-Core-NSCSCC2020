`timescale 1ns / 1ps
`include "../defines/defines.svh"
module iq_entry_ALU(
    input clk,
    input rst,
    input flush,
    input Wake_Info wake_Info,
    input Queue_Ctrl_Meta queue_ctrl,
    input ALU_Queue_Meta din0, din1, up0, up1,
    output ALU_Queue_Meta dout,
    output rdy
    );

ALU_Queue_Meta up_data; 
wire rs1waked, rs2waked, new_prs1_rdy, new_prs2_rdy;
assign up_data = ( queue_ctrl.cmp_sel == 1'b0 ) ? up0 : up1;
ALU_Queue_Meta enq_data; 
assign enq_data = ( queue_ctrl.enq_sel == 1'b0 ) ? din0: din1;
ALU_Queue_Meta next_data;
assign next_data =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_data :
                    ( queue_ctrl.cmp_en ) ? up_data : dout;
UOPBundle ops;
assign ops = next_data.ops;

assign rs1waked =   (wake_Info.wen_0 && (wake_Info.wb_num0_i == ops.op0PAddr)) || 
                    (wake_Info.wen_1 && (wake_Info.wb_num1_i == ops.op0PAddr)) || 
                    (wake_Info.wen_2 && (wake_Info.wb_num2_i == ops.op0PAddr)) || 
                    (wake_Info.wen_3 && (wake_Info.wb_num3_i == ops.op0PAddr));

assign rs2waked =   (wake_Info.wen_0 && (wake_Info.wb_num0_i == ops.op1PAddr)) || 
                    (wake_Info.wen_1 && (wake_Info.wb_num1_i == ops.op1PAddr)) || 
                    (wake_Info.wen_2 && (wake_Info.wb_num2_i == ops.op1PAddr)) || 
                    (wake_Info.wen_3 && (wake_Info.wb_num3_i == ops.op1PAddr));

assign new_prs1_rdy = next_data.rdys.prs1_rdy || rs1waked;
assign new_prs2_rdy = next_data.rdys.prs2_rdy || rs2waked;

Arbitration_Info rdys;
assign rdys.prs1_rdy = new_prs1_rdy;
assign rdys.prs2_rdy = new_prs2_rdy;

ALU_Queue_Meta next_data_with_wake;
assign next_data_with_wake.ops = next_data.ops;
assign next_data_with_wake.rdys = rdys;

assign rdy = dout.rdys.prs1_rdy && dout.rdys.prs2_rdy;

always_ff @(posedge clk)    begin
    if(rst || flush) begin
        dout <= 0;
    end else begin
        dout <= next_data_with_wake;
    end
end


endmodule

module iq_entry_MDU(
    input clk,
    input rst,
    input flush,
    input Wake_Info wake_Info,
    input Queue_Ctrl_Meta queue_ctrl,
    input MDU_Queue_Meta din0, din1, up0, up1,
    output MDU_Queue_Meta dout,
    output rdy
    );

MDU_Queue_Meta up_data; 
wire rs1waked, rs2waked, new_prs1_rdy, new_prs2_rdy;
assign up_data = ( queue_ctrl.cmp_sel == 1'b0 ) ? up0 : up1;
MDU_Queue_Meta enq_data; 
assign enq_data = ( queue_ctrl.enq_sel == 1'b0 ) ? din0: din1;
MDU_Queue_Meta next_data;
assign next_data =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_data :
                    ( queue_ctrl.cmp_en ) ? up_data : dout;
UOPBundle ops;
assign ops = next_data.ops;

assign rs1waked =   (wake_Info.wen_0 && (wake_Info.wb_num0_i == ops.op0PAddr)) || 
                    (wake_Info.wen_1 && (wake_Info.wb_num1_i == ops.op0PAddr)) || 
                    (wake_Info.wen_2 && (wake_Info.wb_num2_i == ops.op0PAddr)) || 
                    (wake_Info.wen_3 && (wake_Info.wb_num3_i == ops.op0PAddr));

assign rs2waked =   (wake_Info.wen_0 && (wake_Info.wb_num0_i == ops.op1PAddr)) || 
                    (wake_Info.wen_1 && (wake_Info.wb_num1_i == ops.op1PAddr)) || 
                    (wake_Info.wen_2 && (wake_Info.wb_num2_i == ops.op1PAddr)) || 
                    (wake_Info.wen_3 && (wake_Info.wb_num3_i == ops.op1PAddr));

assign new_prs1_rdy = next_data.rdys.prs1_rdy || rs1waked;
assign new_prs2_rdy = next_data.rdys.prs2_rdy || rs2waked;

Arbitration_Info rdys;
assign rdys.prs1_rdy = new_prs1_rdy;
assign rdys.prs2_rdy = new_prs2_rdy;

ALU_Queue_Meta next_data_with_wake;
assign next_data_with_wake.ops = next_data.ops;
assign next_data_with_wake.rdys = rdys;

assign rdy = dout.rdys.prs1_rdy && dout.rdys.prs2_rdy;

always_ff @(posedge clk)    begin
    if(rst || flush) begin
        dout <= 0;
    end else begin
        dout <= next_data_with_wake;
    end
end


endmodule


module iq_entry_LSU(
    input clk,
    input rst,
    input flush,
    input Wake_Info wake_Info,
    input Queue_Ctrl_Meta queue_ctrl,
    input LSU_Queue_Meta din0, din1, up0, up1,
    output LSU_Queue_Meta dout,
    output rdy
    );

LSU_Queue_Meta up_data; 
wire rs1waked, rs2waked, new_prs1_rdy, new_prs2_rdy;
assign up_data = ( queue_ctrl.cmp_sel == 1'b0 ) ? up0 : up1;
LSU_Queue_Meta enq_data; 
assign enq_data = ( queue_ctrl.enq_sel == 1'b0 ) ? din0: din1;
LSU_Queue_Meta next_data;
assign next_data =  ( queue_ctrl.enq_en && ~(queue_ctrl.freeze)) ? enq_data :
                    ( queue_ctrl.cmp_en ) ? up_data : dout;
UOPBundle ops;
assign ops = next_data.ops;

assign rs1waked =   (wake_Info.wen_0 && (wake_Info.wb_num0_i == ops.op0PAddr)) || 
                    (wake_Info.wen_1 && (wake_Info.wb_num1_i == ops.op0PAddr)) || 
                    (wake_Info.wen_2 && (wake_Info.wb_num2_i == ops.op0PAddr)) || 
                    (wake_Info.wen_3 && (wake_Info.wb_num3_i == ops.op0PAddr));

assign rs2waked =   (wake_Info.wen_0 && (wake_Info.wb_num0_i == ops.op1PAddr)) || 
                    (wake_Info.wen_1 && (wake_Info.wb_num1_i == ops.op1PAddr)) || 
                    (wake_Info.wen_2 && (wake_Info.wb_num2_i == ops.op1PAddr)) || 
                    (wake_Info.wen_3 && (wake_Info.wb_num3_i == ops.op1PAddr));

assign new_prs1_rdy = next_data.rdys.prs1_rdy || rs1waked;
assign new_prs2_rdy = next_data.rdys.prs2_rdy || rs2waked;

Arbitration_Info rdys;
assign rdys.prs1_rdy = new_prs1_rdy;
assign rdys.prs2_rdy = new_prs2_rdy;

ALU_Queue_Meta next_data_with_wake;
assign next_data_with_wake.ops = next_data.ops;
assign next_data_with_wake.rdys = rdys;

assign rdy = dout.rdys.prs1_rdy && dout.rdys.prs2_rdy;

always_ff @(posedge clk)    begin
    if(rst || flush) begin
        dout <= 0;
    end else begin
        dout <= next_data_with_wake;
    end
end


endmodule
