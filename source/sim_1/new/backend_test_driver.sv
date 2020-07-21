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
    .allocatable(allocatable_rename)
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

wire alu_queue_ready, lsu_queue_ready, mdu_queue_ready;

ALU_Queue_Meta dispatch_alu_0, dispatch_alu_1;
LSU_Queue_Meta dispatch_lsu_0, dispatch_lsu_1;
MDU_Queue_Meta dispatch_mdu_0;


// wire busy_dispatch_inst0_r0;
// wire busy_dispatch_inst0_r1;
// wire busy_dispatch_inst1_r0;
// wire busy_dispatch_inst1_r1;
// PRFNum dispatch_inst0_r0;
// PRFNum dispatch_inst0_r1;
// PRFNum dispatch_inst1_r0;
// PRFNum dispatch_inst1_r1;

// Common Data /////////////////////////////
wire set_busy_0, set_busy_1;
PRFNum set_busy_num_0, set_busy_num_1;
Dispatch_ROB dispatch_rob();

/////////////////////////////////////////////
dispatch u_dispatch(
    .inst_0_ops                         (dispatch_inst0_in), 
    .inst_1_ops                         (dispatch_inst1_in),
    // To Scoreboards
    // .busy_dispatch_inst0_r0             (busy_dispatch_inst0_r0),
    // .busy_dispatch_inst0_r1             (busy_dispatch_inst0_r1),
    // .busy_dispatch_inst1_r0             (busy_dispatch_inst1_r0),
    // .busy_dispatch_inst1_r1             (busy_dispatch_inst1_r1),
    // .dispatch_inst0_r0                  (dispatch_inst0_r0),
    // .dispatch_inst0_r1                  (dispatch_inst0_r1),
    // .dispatch_inst1_r0                  (dispatch_inst1_r0),
    // .dispatch_inst1_r1                  (dispatch_inst1_r1),
    // To Issue Queues
    .rs_alu_wen_0                       (rs_alu_wen_0), 
    .rs_alu_wen_1                       (rs_alu_wen_1), 
    .rs_mdu_wen_0                       (rs_mdu_wen_0), 
    .rs_lsu_wen_0                       (rs_lsu_wen_0), 
    .rs_lsu_wen_1                       (rs_lsu_wen_1),
    .rs_alu_dout_0                      (dispatch_alu_0), 
    .rs_alu_dout_1                      (dispatch_alu_1),
    .rs_mdu_dout_0                      (dispatch_mdu_0), 
    .rs_lsu_dout_0                      (dispatch_lsu_0), 
    .rs_lsu_dout_1                      (dispatch_lsu_1),
    .dispatch_inst0_wnum                (set_busy_num_0),
    .dispatch_inst1_wnum                (set_busy_num_1),
    .dispatch_inst0_wen                 (set_busy_0),
    .dispatch_inst1_wen                 (set_busy_1),
    .dispatch_rob                       (dispatch_rob)
    );




// Register wake //////////////////////////////////////////
PRFNum wake_reg_ALU_0, wake_reg_ALU_1, wake_reg_LSU, wake_reg_MDU;
wire wake_reg_ALU_0_en, wake_reg_ALU_1_en, wake_reg_LSU_en, wake_reg_MDU_en;
Wake_Info wake_info_to_ALU, wake_info_to_LSU, wake_info_to_MDU;
///////////////////////////////////////////////////////////

// TODO:FOR debug///////////////////
assign wake_reg_LSU_en = 0;
assign wake_reg_MDU_en = 0;
assign wake_reg_LSU = 0;
assign wake_reg_MDU = 0;
////////////////////////////////////

// Dispatch to queue

UOPBundle issue_alu_inst_0, issue_alu_inst_1;
wire issue_alu_0_en, issue_alu_1_en;
UOPBundle issue_mdu_inst_hi, issue_mdu_inst_lo;
wire issue_mdu_en;
UOPBundle issue_lsu_inst;
wire issue_lsu_en;

// ALU Queue Scoreboard
PRFNum [9:0] scoreboard_rd_num_l_aluiq2sb;
PRFNum [9:0] scoreboard_rd_num_r_aluiq2sb;
wire [9:0] busyvec_l_sb2aluiq;
wire [9:0] busyvec_r_sb2aluiq;
scoreboard_20r6w scoreboard_alu(
    .clk                                (clk),
    .rst                                (rst),
    .flush                              (flush),
    // dispatched instructions
    .set_busy_0                         (set_busy_0),
    .set_busy_1                         (set_busy_1),
    .set_busy_num_0                     (set_busy_num_0),
    .set_busy_num_1                     (set_busy_num_1),
    // issued instructions(at most 4 instructions issue at a time)
    .clr_busy_ALU0                      (wake_reg_ALU_0_en),
    .clr_busy_ALU1                      (wake_reg_ALU_1_en),
    .clr_busy_LSU                       (wake_reg_LSU_en),
    .clr_busy_MDU                       (wake_reg_MDU_en),
    .clr_busy_num_ALU0                  (wake_reg_ALU_0),
    .clr_busy_num_ALU1                  (wake_reg_ALU_1),
    .clr_busy_num_LSU                   (wake_reg_LSU),
    .clr_busy_num_MDU                   (wake_reg_MDU),
    .rd_num_l                           (scoreboard_rd_num_l_aluiq2sb),
    .rd_num_r                           (scoreboard_rd_num_r_aluiq2sb),
    .busyvec_l                          (busyvec_l_sb2aluiq),
    .busyvec_r                          (busyvec_r_sb2aluiq)
);

issue_unit_ALU issue_alu(
    .clk                                (clk),
    .rst                                (rst),
    .flush                              (0),
    .inst_Ops_0                         (dispatch_alu_0),
    .inst_Ops_1                         (dispatch_alu_1),
    .enq_req_0                          (rs_alu_wen_0),
    .enq_req_1                          (rs_alu_wen_1),
    .issue_info_0                       (issue_alu_inst_0),
    .issue_info_1                       (issue_alu_inst_1),
    .issue_en_0                         (issue_alu_0_en),
    .issue_en_1                         (issue_alu_1_en),
    .wake_reg_0                         (wake_reg_ALU_0),
    .wake_reg_1                         (wake_reg_ALU_1),
    .wake_reg_0_en                      (wake_reg_ALU_0_en),
    .wake_reg_1_en                      (wake_reg_ALU_1_en),
    .ready                              (alu_queue_ready),
    // To scoreboard
    .scoreboard_rd_num_l                (scoreboard_rd_num_l_aluiq2sb),
    .scoreboard_rd_num_r                (scoreboard_rd_num_r_aluiq2sb),
    .busyvec_l                          (busyvec_l_sb2aluiq),
    .busyvec_r                          (busyvec_r_sb2aluiq)
);

wire lsu_busy;

// TODO: For DEBUG
assign lsu_busy = 0;
///////////////////////////////

// ALU Queue Scoreboard
PRFNum [9:0] scoreboard_rd_num_l_lsuiq2sb;
PRFNum [9:0] scoreboard_rd_num_r_lsuiq2sb;
wire [9:0] busyvec_l_sb2lsuiq;
wire [9:0] busyvec_r_sb2lsuiq;
scoreboard_20r6w scoreboard_lsu(
    .clk                                (clk),
    .rst                                (rst),
    .flush                              (flush),
    // dispatched instructions
    .set_busy_0                         (set_busy_0),
    .set_busy_1                         (set_busy_1),
    .set_busy_num_0                     (set_busy_num_0),
    .set_busy_num_1                     (set_busy_num_1),
    // issued instructions(at most 4 instructions issue at a time)
    .clr_busy_ALU0                      (wake_reg_ALU_0_en),
    .clr_busy_ALU1                      (wake_reg_ALU_1_en),
    .clr_busy_LSU                       (wake_reg_LSU_en),
    .clr_busy_MDU                       (wake_reg_MDU_en),
    .clr_busy_num_ALU0                  (wake_reg_ALU_0),
    .clr_busy_num_ALU1                  (wake_reg_ALU_1),
    .clr_busy_num_LSU                   (wake_reg_LSU),
    .clr_busy_num_MDU                   (wake_reg_MDU),
    .rd_num_l                           (scoreboard_rd_num_l_lsuiq2sb),
    .rd_num_r                           (scoreboard_rd_num_r_lsuiq2sb),
    .busyvec_l                          (busyvec_l_sb2lsuiq),
    .busyvec_r                          (busyvec_r_sb2lsuiq)
);

issue_unit_LSU issue_lsu(
    .clk                                (clk),
    .rst                                (rst),
    .flush                              (0),
    .inst_Ops_0                         (dispatch_lsu_0),
    .inst_Ops_1                         (dispatch_lsu_0),
    .enq_req_0                          (rs_lsu_wen_0),
    .enq_req_1                          (rs_lsu_wen_1),
    .lsu_busy                           (lsu_busy),
    .issue_info_0                       (issue_lsu_inst),
    .issue_en_0                         (issue_lsu_en),
    .ready                              (lsu_queue_ready),
    // Scoreboard
    .scoreboard_rd_num_l                (scoreboard_rd_num_l_lsuiq2sb),
    .scoreboard_rd_num_r                (scoreboard_rd_num_r_lsuiq2sb),
    .busyvec_l                          (busyvec_l_sb2lsuiq),
    .busyvec_r                          (busyvec_r_sb2lsuiq)
);

wire mul_busy, div_busy;
assign mul_busy = 0;
assign div_busy = 0;
PRFNum [9:0] scoreboard_rd_num_l_mduiq2sb;
PRFNum [9:0] scoreboard_rd_num_r_mduiq2sb;
wire [9:0] busyvec_l_sb2mduiq;
wire [9:0] busyvec_r_sb2mduiq;
scoreboard_20r6w scoreboard_mdu(
    .clk                                (clk),
    .rst                                (rst),
    .flush                              (flush),
    // dispatched instructions
    .set_busy_0                         (set_busy_0),
    .set_busy_1                         (set_busy_1),
    .set_busy_num_0                     (set_busy_num_0),
    .set_busy_num_1                     (set_busy_num_1),
    // issued instructions(at most 4 instructions issue at a time)
    .clr_busy_ALU0                      (wake_reg_ALU_0_en),
    .clr_busy_ALU1                      (wake_reg_ALU_1_en),
    .clr_busy_LSU                       (wake_reg_LSU_en),
    .clr_busy_MDU                       (wake_reg_MDU_en),
    .clr_busy_num_ALU0                  (wake_reg_ALU_0),
    .clr_busy_num_ALU1                  (wake_reg_ALU_1),
    .clr_busy_num_LSU                   (wake_reg_LSU),
    .clr_busy_num_MDU                   (wake_reg_MDU),
    .rd_num_l                           (scoreboard_rd_num_l_mduiq2sb),
    .rd_num_r                           (scoreboard_rd_num_r_mduiq2sb),
    .busyvec_l                          (busyvec_l_sb2mduiq),
    .busyvec_r                          (busyvec_r_sb2mduiq)
);

issue_unit_MDU issue_mdu(
    .clk                                (clk),
    .rst                                (rst),
    .flush                              (0),
    .inst_Ops_0                         (dispatch_mdu_0),
    .enq_req_0                          (rs_mdu_wen_0),
    .mul_busy                           (mul_busy),
    .div_busy                           (div_busy),
    .issue_info_hi                      (issue_mdu_inst_hi),
    .issue_info_lo                      (issue_mdu_inst_lo),
    .issue_en_0                         (issue_mdu_en),
    .ready                              (mdu_queue_ready),
    // Scoreboard
    .scoreboard_rd_num_l                (scoreboard_rd_num_l_mduiq2sb),
    .scoreboard_rd_num_r                (scoreboard_rd_num_r_mduiq2sb),
    .busyvec_l                          (busyvec_l_sb2mduiq),
    .busyvec_r                          (busyvec_r_sb2mduiq)
    );


integer fp;
integer count;
initial begin
    #0 fp = $fopen("D:\\SHIT-Core\\source\\instr.hex","r");
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
        // $display("Busy:");
        // for(i=0;i<64;i++)   begin
        //     if(u_bt.busytable_bank0[i] == 1) begin
        //         $display(i);
        //     end
        // end
    end else begin
        regs_decode0.inst.valid <= 1;
        regs_decode1.inst.valid <= 1;
    end
end



always begin
    #10 clk = ~clk;
end

endmodule
