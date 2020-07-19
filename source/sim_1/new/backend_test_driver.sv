`timescale 1ns / 1ps
`include "../../sources_1/new/defines/defines.svh"
module backend_test_driver(

    );
reg clk,rst;
reg recover;
Regs_Decode  regs_decode0();
Regs_Decode  regs_decode1();
Decode_Regs  decode_regs0();
Decode_Regs  decode_regs1();
decode dec0(.regs_decode(regs_decode0), .decode_regs(decode_regs0));
decode dec1(.regs_decode(regs_decode1), .decode_regs(decode_regs1));
Ctrl         ctrl_decode_rename_regs();
Regs_Rename regs_rename();
decode_rename_regs dec_rename(
    .clk(clk),
    .rst(rst),
    .ctrl_decode_rename_regs(ctrl_decode_rename_regs),
    .decode0_regs(decode_regs0),
    .decode1_regs(decode_regs1),
    .regs_rename(regs_rename)
);

UOPBundle rename_dispatch_0, rename_dispatch_1;
wire allocatable_rename;
PRFNum rr_bs_set_busy0,rr_bs_set_busy1;
wire set_busy_0, set_busy_1;
register_rename rr(
    .clk(clk), 
    .rst(rst),
    .recover(recover), 
    .inst0_ops_in(regs_rename.uOP0), 
    .inst1_ops_in(regs_rename.uOP1),
    .inst0_ops_out(rename_dispatch_0), 
    .inst1_ops_out(rename_dispatch_1),

    .commit_valid_0(0), 
    .commit_valid_1(0),
    .commit_req_0(0), 
    .commit_req_1(0),
    .allocatable(allocatable_rename),
    .set_busy_num_0(rr_bs_set_busy0),
    .set_busy_num_1(rr_bs_set_busy1),
    .set_busy_0(set_busy_0),
    .set_busy_1(set_busy_1)
    );

wire busy_dispatch_inst0_r0;
wire busy_dispatch_inst0_r1;
wire busy_dispatch_inst1_r0;
wire busy_dispatch_inst1_r1;
PRFNum dispatch_inst0_r0;
PRFNum dispatch_inst0_r1;
PRFNum dispatch_inst1_r0;
PRFNum dispatch_inst1_r1;

busy_table u_bt( 
    // Handle the bypass logic in busy table instead of in the iq
    .clk(clk),
    .rst(rst),
    .flush(0),
    // 4 read ports for dispatching, handles bypass logic 
    .rd_port0(dispatch_inst0_r0),
    .rd_port1(dispatch_inst0_r1),
    .rd_port2(dispatch_inst1_r0),
    .rd_port3(dispatch_inst1_r1),
    // At most 2 instructions dispatched at one time 
    .set_busy_0(set_busy_0),
    .set_busy_1(set_busy_1),
    .set_busy_num_0(rr_bs_set_busy0),
    .set_busy_num_1(rr_bs_set_busy1),

    // At most 4 instructions finish at one time 
    .clr_busy_0(0),
    .clr_busy_1(0),
    .clr_busy_2(0),
    .clr_busy_3(0),

    .clr_busy_num_0(0),
    .clr_busy_num_1(0),
    .clr_busy_num_2(0),
    .clr_busy_num_3(0),
    
    .busy0(busy_dispatch_inst0_r0),
    .busy1(busy_dispatch_inst0_r1),
    .busy2(busy_dispatch_inst1_r0),
    .busy3(busy_dispatch_inst1_r1)
    );

UOPBundle dispatch_inst0_in, dispatch_inst1_in;
rename_dispatch_reg r_d_reg(
    .clk(clk),
    .rst(rst),
    .inst0_in(rename_dispatch_0), 
    .inst1_in(rename_dispatch_1),
    .inst0_out(dispatch_inst0_in), 
    .inst1_out(dispatch_inst1_in),
    .flush(0)
    );

wire rs_alu_wen_0;
wire rs_alu_wen_1;
wire rs_mdu_wen_0;
wire rs_lsu_wen_0;
wire rs_lsu_wen_1;

ALU_Queue_Meta dispatch_alu_0, dispatch_alu_1;
LSU_Queue_Meta dispatch_lsu_0, dispatch_lsu_1;
MDU_Queue_Meta dispatch_mdu_0;

dispatch u_dispatch(
    .inst_0_ops                         (dispatch_inst0_in), 
    .inst_1_ops                         (dispatch_inst1_in),
    .busy_dispatch_inst0_r0             (busy_dispatch_inst0_r0),
    .busy_dispatch_inst0_r1             (busy_dispatch_inst0_r1),
    .busy_dispatch_inst1_r0             (busy_dispatch_inst1_r0),
    .busy_dispatch_inst1_r1             (busy_dispatch_inst1_r1),
    .dispatch_inst0_r0                  (dispatch_inst0_r0),
    .dispatch_inst0_r1                  (dispatch_inst0_r1),
    .dispatch_inst1_r0                  (dispatch_inst1_r0),
    .dispatch_inst1_r1                  (dispatch_inst1_r1),
    .rs_alu_wen_0                       (rs_alu_wen_0), 
    .rs_alu_wen_1                       (rs_alu_wen_1), 
    .rs_mdu_wen_0                       (rs_mdu_wen_0), 
    .rs_lsu_wen_0                       (rs_lsu_wen_0), 
    .rs_lsu_wen_1                       (rs_lsu_wen_1),
    .rs_alu_dout_0                      (dispatch_alu_0), 
    .rs_alu_dout_1                      (dispatch_alu_1),
    .rs_mdu_dout_0                      (dispatch_mdu_0), 
    .rs_lsu_dout_0                      (dispatch_lsu_0), 
    .rs_lsu_dout_1                      (dispatch_lsu_1)
    );

// Register wake //////////////////////////////////////////
PRFNum wake_reg_0, wake_reg_1, wake_reg_2, wake_reg_3;
wire wake_reg_0_en, wake_reg_1_en, wake_reg_2_en, wake_reg_3_en;
Wake_Info wake_info;
///////////////////////////////////////////////////////////

// TODO:FOR debug///////////////////
assign wake_reg_2_en = 0;
assign wake_reg_3_en = 0;
////////////////////////////////////

wake_unit wake_u(
    .wake_reg_0                         (wake_reg_0),
    .wake_reg_1                         (wake_reg_1),
    .wake_reg_2                         (wake_reg_2),
    .wake_reg_3                         (wake_reg_3),
    .wake_reg_0_en                      (wake_reg_0_en),
    .wake_reg_1_en                      (wake_reg_1_en),
    .wake_reg_2_en                      (wake_reg_2_en),
    .wake_reg_3_en                      (wake_reg_3_en),
    .wake_info                          (wake_info)
);

// Dispatch to queue

UOPBundle issue_alu_inst_0, issue_alu_inst_1;
wire issue_alu_0_en, issue_alu_1_en;
UOPBundle issue_mdu_hi, issue_mdu_lo;
wire issue_mdu_en;
UOPBundle issue_lsu_inst;
wire issue_lsu_en;

issue_unit_ALU issue_alu(
    .clk                                (clk),
    .rst                                (rst),
    .flush                              (0),
    .wake_Info                          (wake_info),
    .inst_Ops_0                         (dispatch_alu_0),
    .inst_Ops_1                         (dispatch_alu_1),
    .enq_req_0                          (rs_alu_wen_0),
    .enq_req_1                          (rs_alu_wen_1),
    .issue_info_0                       (issue_alu_inst_0),
    .issue_info_1                       (issue_alu_inst_1),
    .issue_en_0                         (issue_alu_0_en),
    .issue_en_1                         (issue_alu_1_en),
    .wake_reg_0                         (wake_reg_0),
    .wake_reg_1                         (wake_reg_1),
    .wake_reg_0_en                      (wake_reg_0_en),
    .wake_reg_1_en                      (wake_reg_1_en),
    .ready                              (alu_queue_ready)
    );

integer fp;
integer count;
initial begin
    #0 fp = $fopen("../../../../source/instr.hex","r");
    regs_decode0.inst.valid = 0;
    regs_decode1.inst.valid = 0;
    ctrl_decode_rename_regs.pause = 0;
    ctrl_decode_rename_regs.flush = 0;
    regs_decode0.inst = 0; 
    regs_decode1.inst = 0; 
    regs_decode1.inst.pc = 4;     
    recover = 0;
    #0 clk = 0;rst = 1;
    #22 rst = 0;
end

integer i;
// Insturction Generator
always @(posedge clk)   begin
    if(!rst && !ctrl_decode_rename_regs.pauseReq)  begin
        if(!$feof(fp))   begin
            regs_decode0.inst.valid <= 1;
            regs_decode1.inst.valid <= 1;
        end else begin
            regs_decode0.inst.valid <= 0;
            regs_decode1.inst.valid <= 0;
            $finish;
        end
        count <= $fscanf(fp,"%h" ,regs_decode0.inst.inst);
        regs_decode0.inst.pc <= regs_decode0.inst.pc+8;
        count <= $fscanf(fp,"%h" ,regs_decode1.inst.inst);
        regs_decode1.inst.pc <= regs_decode1.inst.pc+8;
        #2
        if (decode_regs0.uOP0.op1re)     begin
            $display("Decode0: %4s %2d,%2d,%2d @ PC %h", 
                decode_regs0.uOP0.uOP.name,
                decode_regs0.uOP0.dstLAddr,
                decode_regs0.uOP0.op0LAddr,
                decode_regs0.uOP0.op1LAddr,
                decode_regs0.uOP0.pc
        );
        end else begin
            $display("Decode0: %4s %2d,%2d,(IMM)%2d @ PC %h", 
                decode_regs0.uOP0.uOP.name,
                decode_regs0.uOP0.dstLAddr,
                decode_regs0.uOP0.op0LAddr,
                decode_regs0.uOP0.imm,
                decode_regs0.uOP0.pc
        );
        end
        if (decode_regs1.uOP0.op1re)     begin
            $display("Decode1: %4s %2d,%2d,%2d @ PC %h", 
                decode_regs1.uOP0.uOP.name,
                decode_regs1.uOP0.dstLAddr,
                decode_regs1.uOP0.op0LAddr,
                decode_regs1.uOP0.op1LAddr,
                decode_regs1.uOP0.pc
        );
        end else begin
            $display("Decode1: %4s %2d,%2d,(IMM)%2d @ PC %h", 
                decode_regs1.uOP0.uOP.name,
                decode_regs1.uOP0.dstLAddr,
                decode_regs1.uOP0.op0LAddr,
                decode_regs1.uOP0.imm,
                decode_regs1.uOP0.pc
        );
        end
        $display("Busy:");
        for(i=0;i<64;i++)   begin
            if(u_bt.busytable_bank0[i] == 1) begin
                $display(i);
            end
        end
    end else begin
        regs_decode0.inst.valid <= 1;
        regs_decode1.inst.valid <= 1;
    end
end



always begin
    #10 clk = ~clk;
end

endmodule
