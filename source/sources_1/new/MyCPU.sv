`timescale 1ns / 1ps
`include "defines/defines.svh"

module MyCPU(
    input clk,
    input rst,

    output wire rsta_busy               ,
    output wire rstb_busy               ,

    output wire         s_aclk          ,
    output wire         s_aresetn       ,
    output wire [ 3:0]  s_axi_awid      ,
    output wire [31:0]  s_axi_awaddr    ,
    output wire [ 7:0]  s_axi_awlen     ,
    output wire [ 2:0]  s_axi_awsize    ,
    output wire [ 1:0]  s_axi_awburst   ,
    output wire         s_axi_awvalid   ,
    input  wire         s_axi_awready   ,
    output wire [31:0]  s_axi_wdata     ,
    output wire [ 3:0]  s_axi_wstrb     ,
    output wire         s_axi_wlast     ,
    output wire         s_axi_wvalid    ,
    input  wire         s_axi_wready    ,
    input  wire [ 3:0]  s_axi_bid       ,
    input  wire [ 1:0]  s_axi_bresp     ,
    input  wire         s_axi_bvalid    ,
    output wire         s_axi_bready    ,
    output wire [ 3:0]  s_axi_arid      ,
    output wire [31:0]  s_axi_araddr    ,
    output wire [ 7:0]  s_axi_arlen     ,
    output wire [ 2:0]  s_axi_arsize    ,
    output wire [ 1:0]  s_axi_arburst   ,
    output wire         s_axi_arvalid   ,
    input  wire         s_axi_arready   ,
    input  wire [ 3:0]  s_axi_rid       ,
    input  wire [31:0]  s_axi_rdata     ,
    input  wire [ 1:0]  s_axi_rresp     ,
    input  wire         s_axi_rlast     ,
    input  wire         s_axi_rvalid    ,
    output wire         s_axi_rready    
);
    
    AXIReadAddr         axiReadAddr();
    AXIReadData         axiReadData();
    AXIWriteAddr        axiWriteAddr();
    AXIWriteData        axiWriteData();
    AXIWriteResp        axiWriteResp();

    InstReq             instReq();
    InstResp            instResp();
    DataReq             dataReq();
    DataResp            dataResp();
    DCacheReq           dCacheReq();
    DCacheResp          dCacheResp();
    
    Ctrl                backend_ctrl();
    Ctrl                ctrl_if0_1_regs();
    Ctrl                ctrl_if2_3_regs();
    Ctrl                ctrl_iCache();
    Ctrl                ctrl_if3();
    Ctrl                ctrl_if3_output_regs();
    Ctrl                ctrl_instBuffer();
    Ctrl                ctrl_nlp();
    Ctrl                ctrl_decode_rename_regs();
    Ctrl                ctrl_instBuffer_decode_regs();
    Ctrl                ctrl_rob();
    Ctrl                ctrl_issue_alu0_regs();
    Ctrl                ctrl_issue_alu1_regs();
    Ctrl                ctrl_issue_mdu_regs();
    Ctrl                ctrl_issue_lsu_regs();
    Ctrl                ctrl_rf_alu0_regs();
    Ctrl                ctrl_rf_alu1_regs();
    Ctrl                ctrl_rf_mdu_regs();
    Ctrl                ctrl_rf_lsu_regs();
    Ctrl                ctrl_alu0_output_regs();
    Ctrl                ctrl_alu1_output_regs();
    Ctrl                ctrl_mdu_output_regs();
    Ctrl                ctrl_lsu_output_regs();
    Ctrl                ctrl_commit();


    BackendRedirect     backend_if0();
    BPDUpdate           backend_bpd();
    NLPUpdate           backend_nlp();

    ICache_TLB          iCache_tlb();
    
    IFU_InstBuffer      ifu_instBuffer();
    InstBuffer_Backend  instBuffer_backend();

    Regs_Decode         regs_decode0();
    Regs_Decode         regs_decode1();
    Decode_Regs         decode_regs0();
    Decode_Regs         decode_regs1();
    Regs_Rename         regs_rename();

    UOPBundle           rename_dispatch_0, rename_dispatch_1;
    wire                allocatable_rename;

    UOPBundle           dispatch_inst0_in, dispatch_inst1_in;

    wire                rs_alu_wen_0;
    wire                rs_alu_wen_1;
    wire                rs_mdu_wen_0;
    wire                rs_lsu_wen_0;
    wire                rs_lsu_wen_1;
    
    wire                alu_queue_ready, lsu_queue_ready, mdu_queue_ready;

    ALU_Queue_Meta      dispatch_alu_0, dispatch_alu_1;
    LSU_Queue_Meta      dispatch_lsu_0, dispatch_lsu_1;
    MDU_Queue_Meta      dispatch_mdu_0;

    Dispatch_ROB        dispatch_rob();

    wire                set_busy_0, set_busy_1;
    PRFNum              set_busy_num_0, set_busy_num_1;

    PRFNum              wake_reg_ALU_0, wake_reg_ALU_1, wake_reg_LSU, wake_reg_MDU;
    wire                wake_reg_ALU_0_en, wake_reg_ALU_1_en, wake_reg_LSU_en, wake_reg_MDU_en;
    Wake_Info           wake_info_to_ALU, wake_info_to_LSU, wake_info_to_MDU;

    UOPBundle           issue_alu_inst_0, issue_alu_inst_1;
    wire                issue_alu_0_en, issue_alu_1_en;

    UOPBundle           issue_mdu_inst_hi, issue_mdu_inst_lo;
    wire                issue_mdu_en;

    UOPBundle           issue_lsu_inst;
    wire                issue_lsu_en;

    PRFNum [9:0]        scoreboard_rd_num_l_aluiq2sb;
    PRFNum [9:0]        scoreboard_rd_num_r_aluiq2sb;
    wire [9:0]          busyvec_l_sb2aluiq;
    wire [9:0]          busyvec_r_sb2aluiq;

    wire                lsu_busy;
    wire                mul_busy, div_busy;

    UOPBundle           alu0RFBundle;
    UOPBundle           alu1RFBundle;
    UOPBundle           lsuRFBundle;
    UOPBundle           mduRFBundleHi;
    UOPBundle           mduRFBundleLo;

    PRFrNums            alu0RFReq;
    PRFrNums            alu1RFReq;
    PRFrNums            lsuRFReq;
    PRFrNums            mduRFReq;

    PRFrData            alu0RFResp;
    PRFrData            alu1RFResp;
    PRFrData            lsuRFResp;
    PRFrData            mduRFResp;

    PRFrData            alu0Oprands;
    PRFrData            alu1Oprands;
    PRFrData            lsuOprands;
    PRFrData            mduOprands;

    UOPBundle           alu0UOPBundle;
    UOPBundle           alu1UOPBundle;
    UOPBundle           lsuUOPBundle;
    UOPBundle           mduUOPBundleHi;
    UOPBundle           mduUOPBundleLo;

    FU_ROB              alu0_commit_reg();
    FU_ROB              alu1_commit_reg();
    FU_ROB              mdu_commit_reg();
    FU_ROB              lsu_commit_reg();

    FU_ROB              alu0_rob();
    FU_ROB              alu1_rob();
    FU_ROB              mdu_rob();
    FU_ROB              lsu_rob();

    ROB_Commit          rob_commit();

    PRFwInfo            alu0WBReq;
    PRFwInfo            alu1WBReq;
    PRFwInfo            mduWBReq;
    PRFwInfo            lsuWBReq;

    PRFwInfo            alu0WBOut;
    PRFwInfo            alu1WBOut;
    PRFwInfo            mduWBOut;
    PRFwInfo            lsuWBOut;

    logic                commit_rename_valid_0;
    logic                commit_rename_valid_1;
    commit_info          commit_rename_req_0;
    commit_info          commit_rename_req_1;

    assign wake_reg_LSU_en = 0;
    assign wake_reg_MDU_en = 0;
    assign wake_reg_LSU = 0;
    assign wake_reg_MDU = 0;
    assign lsu_busy = 0;

    wire           aluIQReady;
    wire           lsuIQReady;
    wire           mduIQReady;
    wire           renameAllocatable;
    wire           renameRecover;
    wire           aluIQFlush;
    wire           lsuIQFlush;
    wire           mduIQFlush;
    wire           pauseRename;
    wire           pauseRename_dispatch_reg;

    CtrlUnit                cu(.*);
    CtrlUnitBackend         cub(.*);
    AXIInterface            axiInterface(.*);
    AXIWarp                 axiWarp(.*);
    IFU                     ifu(.*);
    InstBuffer              instBuffer(.*);
    InstBuffer_decode_regs  InstBuffer_decode_regs(.*);
    decode                  dec0(.regs_decode(regs_decode0), .decode_regs(decode_regs0));
    decode                  dec1(.regs_decode(regs_decode1), .decode_regs(decode_regs1));
    decode_rename_regs      dec_rename( .*, .decode0_regs(decode_regs0), .decode1_regs(decode_regs1));
    register_rename rr(
        .clk(clk), 
        .rst(rst),
        .recover(renameRecover), 
        .inst0_ops_in(regs_rename.uOP0), 
        .inst1_ops_in(regs_rename.uOP1),
        .inst0_ops_out(rename_dispatch_0), 
        .inst1_ops_out(rename_dispatch_1),

        .commit_valid_0(commit_rename_valid_0), 
        .commit_valid_1(commit_rename_valid_1),
        .commit_req_0(commit_rename_req_0), 
        .commit_req_1(commit_rename_req_1),
        .allocatable(renameAllocatable),
        .pauseRename(pauseRename)
    );
    rename_dispatch_reg r_d_reg(
        .clk(clk),
        .rst(rst),
        .pauseRename_dispatch_reg(pauseRename_dispatch_reg),
        .inst0_in(rename_dispatch_0), 
        .inst1_in(rename_dispatch_1),
        .inst0_out(dispatch_inst0_in), 
        .inst1_out(dispatch_inst1_in),
        .flush(renameRecover)
    );
    dispatch u_dispatch(
        .inst_0_ops                         (dispatch_inst0_in), 
        .inst_1_ops                         (dispatch_inst1_in),
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
    ROB rob(.*);
    scoreboard_20r6w scoreboard_alu(
        .clk                                (clk),
        .rst                                (rst),
        .flush                              (aluIQFlush),
        // dispatched instructions
        .set_busy_0                         (set_busy_0),
        .set_busy_1                         (set_busy_1),
        .set_busy_num_0                     (set_busy_num_0),
        .set_busy_num_1                     (set_busy_num_1),
        // issued instructions(at most 4 instructions issue at a time)
        .clr_busy_ALU0                      (wake_reg_ALU_0_en),
        .clr_busy_ALU1                      (wake_reg_ALU_1_en),
        .clr_busy_LSU                       (wake_reg_LSU_en),
        .clr_busy_MDU                       (mduWBReq.wen),
        .clr_busy_num_ALU0                  (wake_reg_ALU_0),
        .clr_busy_num_ALU1                  (wake_reg_ALU_1),
        .clr_busy_num_LSU                   (wake_reg_LSU),
        .clr_busy_num_MDU                   (mduWBReq.rd), 
        .rd_num_l                           (scoreboard_rd_num_l_aluiq2sb),
        .rd_num_r                           (scoreboard_rd_num_r_aluiq2sb),
        .busyvec_l                          (busyvec_l_sb2aluiq),
        .busyvec_r                          (busyvec_r_sb2aluiq)
    );
    issue_unit_ALU issue_alu(
        .clk                                (clk),
        .rst                                (rst),
        .flush                              (aluIQFlush),
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
        .ready                              (aluIQReady),
        // To scoreboard
        .scoreboard_rd_num_l                (scoreboard_rd_num_l_aluiq2sb),
        .scoreboard_rd_num_r                (scoreboard_rd_num_r_aluiq2sb),
        .busyvec_l                          (busyvec_l_sb2aluiq),
        .busyvec_r                          (busyvec_r_sb2aluiq)
    );

    // LSU Queue Scoreboard
    PRFNum [9:0] scoreboard_rd_num_l_lsuiq2sb;
    PRFNum [9:0] scoreboard_rd_num_r_lsuiq2sb;
    wire [9:0] busyvec_l_sb2lsuiq;
    wire [9:0] busyvec_r_sb2lsuiq;
    scoreboard_20r6w scoreboard_lsu(
        .clk                                (clk),
        .rst                                (rst),
        .flush                              (lsuIQFlush),
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
        .flush                              (lsuIQFlush),
        .inst_Ops_0                         (dispatch_lsu_0),
        .inst_Ops_1                         (dispatch_lsu_0),
        .enq_req_0                          (rs_lsu_wen_0),
        .enq_req_1                          (rs_lsu_wen_1),
        .lsu_busy                           (lsu_busy),
        .issue_info_0                       (issue_lsu_inst),
        .issue_en_0                         (issue_lsu_en),
        .ready                              (lsuIQReady),
        // Scoreboard
        .scoreboard_rd_num_l                (scoreboard_rd_num_l_lsuiq2sb),
        .scoreboard_rd_num_r                (scoreboard_rd_num_r_lsuiq2sb),
        .busyvec_l                          (busyvec_l_sb2lsuiq),
        .busyvec_r                          (busyvec_r_sb2lsuiq)
    );

    PRFNum [9:0] scoreboard_rd_num_l_mduiq2sb;
    PRFNum [9:0] scoreboard_rd_num_r_mduiq2sb;
    wire [9:0] busyvec_l_sb2mduiq;
    wire [9:0] busyvec_r_sb2mduiq;
    scoreboard_20r6w scoreboard_mdu(
        .clk                                (clk),
        .rst                                (rst),
        .flush                              (mduIQFlush),
        // dispatched instructions
        .set_busy_0                         (set_busy_0),
        .set_busy_1                         (set_busy_1),
        .set_busy_num_0                     (set_busy_num_0),
        .set_busy_num_1                     (set_busy_num_1),
        // issued instructions(at most 4 instructions issue at a time)
        .clr_busy_ALU0                      (alu0WBReq.wen),
        .clr_busy_ALU1                      (alu1WBReq.wen),
        .clr_busy_LSU                       (wake_reg_LSU_en),
        .clr_busy_MDU                       (mduWBReq.wen),
        .clr_busy_num_ALU0                  (alu0WBReq.rd),
        .clr_busy_num_ALU1                  (alu1WBReq.rd),
        .clr_busy_num_LSU                   (wake_reg_LSU),
        .clr_busy_num_MDU                   (mduWBReq.rd),
        .rd_num_l                           (scoreboard_rd_num_l_mduiq2sb),
        .rd_num_r                           (scoreboard_rd_num_r_mduiq2sb),
        .busyvec_l                          (busyvec_l_sb2mduiq),
        .busyvec_r                          (busyvec_r_sb2mduiq)
    );

    issue_unit_MDU issue_mdu(
        .clk                                (clk),
        .rst                                (rst),
        .flush                              (mduIQFlush),
        .inst_Ops_0                         (dispatch_mdu_0),
        .enq_req_0                          (rs_mdu_wen_0),
        .mul_busy                           (mul_busy),
        .div_busy                           (div_busy),
        .issue_info_hi                      (issue_mdu_inst_hi),
        .issue_info_lo                      (issue_mdu_inst_lo),
        .issue_en_0                         (issue_mdu_en),
        .ready                              (mduIQReady),
        // Scoreboard
        .scoreboard_rd_num_l                (scoreboard_rd_num_l_mduiq2sb),
        .scoreboard_rd_num_r                (scoreboard_rd_num_r_mduiq2sb),
        .busyvec_l                          (busyvec_l_sb2mduiq),
        .busyvec_r                          (busyvec_r_sb2mduiq)
    );
    Issue_RF_regs issue_alu0_regs(
        .*,
        .ctrl_issue_rf_regs                 (ctrl_issue_alu0_regs),
        .issueBundle                        (issue_alu_inst_0),
        .primPauseReq                       (`FALSE),
        .rfBundle                           (alu0RFBundle),
        .prfRequest                         (alu0RFReq)
    );
    Issue_RF_regs issue_alu1_regs(
        .*,
        .ctrl_issue_rf_regs                 (ctrl_issue_alu1_regs),
        .issueBundle                        (issue_alu_inst_1),
        .primPauseReq                       (`FALSE),
        .rfBundle                           (alu1RFBundle),
        .prfRequest                         (alu1RFReq)
    );
    Issue_RF_regs issue_lsu_regs(
        .*,
        .ctrl_issue_rf_regs                 (ctrl_issue_lsu_regs),
        .issueBundle                        (issue_alu_inst_0),
        .primPauseReq                       (lsu_busy),
        .rfBundle                           (lsuRFBundle),
        .prfRequest                         (lsuRFReq)
    );
    MDUIQ_RF_regs  issue_mdu_regs(
        .*,
        .issueBundleHi                      (issue_mdu_inst_hi),
        .issueBundleLo                      (issue_mdu_inst_lo),
        .primPauseReq                       (`FALSE),
        .rfBundleHi                         (mduRFBundleHi),
        .rfBundleLo                         (mduRFBundleLo),
        .prfRequest                         (mduRFReq),
        .mulBusy                            (mul_busy),
        .divBusy                            (div_busy)
    );
    prf prf_u(
        .*,
        .rnum_ALU_0                         (alu0RFReq),
        .rnum_ALU_1                         (alu1RFReq),
        .rnum_MDU                           (lsuRFReq),
        .rnum_LSU                           (mduRFReq),
        .rdata_ALU_0                        (alu0RFResp),
        .rdata_ALU_1                        (alu1RFResp),
        .rdata_MDU                          (lsuRFResp),
        .rdata_LSU                          (mduRFResp),
        .wb_ALU_0                           (alu0WBReq),
        .wb_ALU_1                           (alu1WBReq),
        .wb_MDU                             (mduWBReq),
        .wb_LSU                             (lsuWBReq)
    );
    RF_FU_regs rf_alu0_regs(
        .*,
        .ctrl_rf_fu_regs                    (ctrl_rf_alu0_regs),
        .primPauseReq                       (`FALSE),
        .rfBundle                           (alu0RFBundle),
        .rfRes                              (alu0RFResp),
        .fuBundle                           (alu0UOPBundle),
        .fuOprands                          (alu0Oprands)
    );
    RF_FU_regs rf_alu1_regs(
        .*,
        .ctrl_rf_fu_regs                    (ctrl_rf_alu1_regs),
        .primPauseReq                       (`FALSE),
        .rfBundle                           (alu1RFBundle),
        .rfRes                              (alu1RFResp),
        .fuBundle                           (alu1UOPBundle),
        .fuOprands                          (alu1Oprands)
    );
    RF_FU_regs rf_lsu_regs(
        .*,
        .ctrl_rf_fu_regs                    (ctrl_rf_lsu_regs),
        .primPauseReq                       (lsu_busy),
        .rfBundle                           (lsuRFBundle),
        .rfRes                              (lsuRFResp),
        .fuBundle                           (lsuUOPBundle),
        .fuOprands                          (lsuOprands)
    );
    RF_MDU_regs rf_mdu_regs(
        .*,
        .ctrl_rf_fu_regs                    (ctrl_rf_mdu_regs),
        .primPauseReq                       (`FALSE),
        .rfBundleHi                         (mduRFBundleHi),
        .rfBundleLo                         (mduRFBundleLo),
        .rfRes                              (mduRFResp),
        .fuBundleHi                         (mduUOPBundleHi),
        .fuBundleLo                         (mduUOPBundleLo),
        .fuOprands                          (mduOprands)
    );
    ALU alu0(
        .uops                               (alu0UOPBundle),
        .rdata                              (alu0Oprands),
        .bypass_alu0                        (alu0WBReq),
        .bypass_alu1                        (alu1WBReq),
        .wbData                             (alu0WBOut),
        .alu_rob                            (alu0_commit_reg)
    );
    ALU alu1(
        .uops                               (alu1UOPBundle),
        .rdata                              (alu1Oprands),
        .bypass_alu0                        (alu0WBReq),
        .bypass_alu1                        (alu1WBReq),
        .wbData                             (alu1WBOut),
        .alu_rob                            (alu1_commit_reg)
    );
    // lsu?
    MDU mdu(
        .*,
        .uopHi                              (mduUOPBundleHi),
        .uopLo                              (mduUOPBundleLo),
        .rdata                              (mduOprands),
        .wbData                             (mduWBOut),
        .mdu_rob                            (mdu_commit_reg)
    );
    FU_Output_regs alu0_output_regs(
        .*,
        .ctrl_fu_output_regs                (ctrl_alu0_output_regs),
        .fuWbData                           (alu0WBOut),
        .fuCommitInfo                       (alu0_commit_reg),
        .prfWReq                            (alu0WBReq),
        .commitInfo                         (alu0_rob)
    );
    FU_Output_regs alu1_output_regs(
        .*,
        .ctrl_fu_output_regs                (ctrl_alu1_output_regs),
        .fuWbData                           (alu1WBOut),
        .fuCommitInfo                       (alu1_commit_reg),
        .prfWReq                            (alu1WBReq),
        .commitInfo                         (alu1_rob)
    );
    FU_Output_regs lsu_output_regs(
        .*,
        .ctrl_fu_output_regs                (ctrl_lsu_output_regs),
        .fuWbData                           (lsuWBOut),
        .fuCommitInfo                       (lsu_commit_reg),
        .prfWReq                            (lsuWBReq),
        .commitInfo                         (lsu_rob)
    );
    FU_Output_regs mdu_output_regs(
        .*,
        .ctrl_fu_output_regs                (ctrl_mdu_output_regs),
        .fuWbData                           (mduWBOut),
        .fuCommitInfo                       (mdu_commit_reg),
        .prfWReq                            (mduWBReq),
        .commitInfo                         (mdu_rob)
    );
    Commit commit(.*);

    // synopsys translate_off
    always @ (posedge clk) begin
        if(rob_commit.valid) #21 begin
            for(integer i = 0; i <= 34; i++) begin
                $display("reg %d : %d", i, prf_u.prfs_bank0[rr.u_map_table.committed_rename_map_table_bank0[i]]);
            end
        end
    end
    // synopsys translate_on
endmodule
