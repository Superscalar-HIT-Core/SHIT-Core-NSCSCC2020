`timescale 1ns / 1ps
`include "defines/defines.svh"

module mycpu_top(
    input aclk,
    input aresetn,

    input [5:0] ext_int,

<<<<<<< HEAD
(*mark_debug = "true"*)output wire [ 3:0]  awid      ,
(*mark_debug = "true"*)output wire [31:0]  awaddr    ,
    output wire [ 7:0]  awlen     ,
    output wire [ 2:0]  awsize    ,
=======
    output wire [ 3:0]  awid      ,
    (* mark_debug = "yes" *)output wire [31:0]  awaddr    ,
    (* mark_debug = "yes" *)output wire [ 3:0]  awlen     ,
    (* mark_debug = "yes" *)output wire [ 2:0]  awsize    ,
>>>>>>> bd15dcd3c36bdc0d3b4b681a506e36ae6ae2052a
    output wire [ 1:0]  awburst   ,
    output wire [ 1:0]  awlock    ,
    output wire [ 3:0]  awcache   ,
    output wire [ 2:0]  awprot    ,
<<<<<<< HEAD
(*mark_debug = "true"*)output wire         awvalid   ,
(*mark_debug = "true"*)input  wire         awready   ,

(*mark_debug = "true"*)output wire [ 3:0]  wid       ,
(*mark_debug = "true"*)output wire [31:0]  wdata     ,
    output wire [ 3:0]  wstrb     ,
    output wire         wlast     ,
(*mark_debug = "true"*)output wire         wvalid    ,
(*mark_debug = "true"*)input  wire         wready    ,
=======
    (* mark_debug = "yes" *)output wire         awvalid   ,
    (* mark_debug = "yes" *)input  wire         awready   ,

    output wire [ 3:0]  wid       ,
    (* mark_debug = "yes" *)output wire [31:0]  wdata     ,
    (* mark_debug = "yes" *)output wire [ 3:0]  wstrb     ,
    (* mark_debug = "yes" *)output wire         wlast     ,
    (* mark_debug = "yes" *)output wire         wvalid    ,
    (* mark_debug = "yes" *)input  wire         wready    ,
>>>>>>> bd15dcd3c36bdc0d3b4b681a506e36ae6ae2052a

    input  wire [ 3:0]  bid       ,
    (* mark_debug = "yes" *)input  wire [ 1:0]  bresp     ,
    (* mark_debug = "yes" *)input  wire         bvalid    ,
    (* mark_debug = "yes" *)output wire         bready    ,

    output wire [ 3:0]  arid      ,
    (* mark_debug = "yes" *)output wire [31:0]  araddr    ,
    (* mark_debug = "yes" *)output wire [ 3:0]  arlen     ,
    (* mark_debug = "yes" *)output wire [ 2:0]  arsize    ,
    output wire [ 1:0]  arburst   ,
    output wire [ 1:0]  arlock    ,
    output wire [ 3:0]  arcache   ,
    output wire [ 2:0]  arprot    ,
    (* mark_debug = "yes" *)output wire         arvalid   ,
    (* mark_debug = "yes" *)input  wire         arready   ,

    input  wire [ 3:0]  rid       ,
    (* mark_debug = "yes" *)input  wire [31:0]  rdata     ,
    input  wire [ 1:0]  rresp     ,
    (* mark_debug = "yes" *)input  wire         rlast     ,
    (* mark_debug = "yes" *)input  wire         rvalid    ,
    (* mark_debug = "yes" *)output wire         rready    ,
    output wire [31:0]  debug_wb_pc            ,
    output wire [3:0]   debug_wb_rf_wen        ,
    output wire [4:0]   debug_wb_rf_wnum       ,
    output wire [31:0]  debug_wb_rf_wdata      
);

    // In order to pass the synthesis
    assign debug_wb_pc       = 0;
    assign debug_wb_rf_wen   = 0;
    assign debug_wb_rf_wnum  = 0;
    assign debug_wb_rf_wdata = 0;
    wire clk;
    assign clk = aclk;
    wire rst;
    assign rst = ~aresetn;
    reg [31:0] debug_branch_cnt;
    reg [31:0] debug_redirect_cnt;
    always @(posedge clk)   begin
        if(rst) begin
            debug_branch_cnt <= 0;
            debug_redirect_cnt <= 0;
        end else begin
            if(commit.debug_is_branch)  begin
                debug_branch_cnt <= debug_branch_cnt + 1'b1;
            end 
            if(commit.debug_redirect)   begin
                debug_redirect_cnt <= debug_redirect_cnt + 1'b1;
            end
        end
    end
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
    Ctrl                ctrl_lsu();
    Ctrl                ctrl_mdu();
    Ctrl                ctrl_alu0_output_regs();
    Ctrl                ctrl_alu1_output_regs();
    Ctrl                ctrl_mdu_output_regs();
    Ctrl                ctrl_lsu_output_regs();
    Ctrl                ctrl_commit();


    BackendRedirect     backend_if0();
    BPDUpdate           backend_bpd();
    NLPUpdate           backend_nlp();
    
    CP0WRInterface      alu0_cp0();
    CP0WRInterface      alu1_cp0_fake();
    CP0WRInterface      exception_cp0();
    CP0Exception        exceInfo();
    CommitExce          exce_commit();

    CP0_TLB             cp0_tlb();
    CP0StatusRegs       cp0StatusRegs();

    ICache_TLB          iCache_tlb();

    always_ff @ (posedge clk) begin
        if(iCache_tlb.virAddr0 > 32'hC0000000 || iCache_tlb.virAddr0 < 32'h3FFFFFFF) begin
            iCache_tlb.phyAddr0 = iCache_tlb.virAddr0;
        end else if (iCache_tlb.virAddr0 > 32'h9fff_ffff) begin
            iCache_tlb.phyAddr0 = iCache_tlb.virAddr0 - 32'h9FFF_FFFF;
        end else begin
            iCache_tlb.phyAddr0 = iCache_tlb.virAddr0 - 32'h7FFF_FFFF;
        end
        if(iCache_tlb.virAddr1 > 32'hC0000000 || iCache_tlb.virAddr1 < 32'h3FFFFFFF) begin
            iCache_tlb.phyAddr1 = iCache_tlb.virAddr1;
        end else if (iCache_tlb.virAddr1 > 32'h9fff_ffff) begin
            iCache_tlb.phyAddr1 = iCache_tlb.virAddr1 - 32'h9FFF_FFFF;
        end else begin
            iCache_tlb.phyAddr1 = iCache_tlb.virAddr1 - 32'h7FFF_FFFF;
        end
    end
    
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
    wire                rs_alu_wen_0_reg;
    wire                rs_alu_wen_1_reg;
    wire                rs_mdu_wen_0_reg;
    wire                rs_lsu_wen_0_reg;
    wire                rs_lsu_wen_1_reg;
    
    wire                alu_queue_ready, lsu_queue_ready, mdu_queue_ready;

    ALU_Queue_Meta      dispatch_alu_0, dispatch_alu_1;
    LSU_Queue_Meta      dispatch_lsu_0, dispatch_lsu_1;
    MDU_Queue_Meta      dispatch_mdu_0;

    ALU_Queue_Meta      dispatch_alu_0_reg, dispatch_alu_1_reg;
    LSU_Queue_Meta      dispatch_lsu_0_reg, dispatch_lsu_1_reg;
    MDU_Queue_Meta      dispatch_mdu_0_reg;

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

    wire                hasPendingUncachedLoad;

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

    UncachedLoadInfo    uncachedLoadInfo();

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
    PRFNum alu0_wake_reg, alu1_wake_reg;
    logic  alu0_wake_ena, alu1_wake_ena;
    // assign lsu_busy = 0;

    wire           dispatch_pause_req;
    wire           aluIQReady;
    wire           lsuIQReady;
    wire           mduIQReady;
    wire           renameAllocatable;
    wire           renameRecover;
    wire           aluIQFlush;
    wire           lsuIQFlush;
    wire           mduIQFlush;
    wire           pauseRename;
    wire           pauseDispatch;
    wire           pauseRename_dispatch_reg;
    wire           pauseDispatch_iq_reg;
    wire           fireStore;
    wire           fireStore1;

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
        .clk(aclk), 
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
        .clk(aclk),
        .rst(rst),
        .pauseRename_dispatch_reg(pauseRename_dispatch_reg),
        .inst0_in(rename_dispatch_0), 
        .inst1_in(rename_dispatch_1),
        .inst0_out(dispatch_inst0_in), 
        .inst1_out(dispatch_inst1_in),
        .flush(renameRecover)
    );
    dispatch u_dispatch(
        .clk                                (clk),
        .rst                                (rst),
        .pause                              (pauseDispatch),
        .inst_0_ops                         (dispatch_inst0_in), 
        .inst_1_ops                         (dispatch_inst1_in),
        // To Pipeline Regs
        .rs_alu_wen_0                       (rs_alu_wen_0_reg), 
        .rs_alu_wen_1                       (rs_alu_wen_1_reg), 
        .rs_mdu_wen_0                       (rs_mdu_wen_0_reg), 
        .rs_lsu_wen_0                       (rs_lsu_wen_0_reg), 
        .rs_lsu_wen_1                       (rs_lsu_wen_1_reg),
        .rs_alu_dout_0                      (dispatch_alu_0_reg), 
        .rs_alu_dout_1                      (dispatch_alu_1_reg),
        .rs_mdu_dout_0                      (dispatch_mdu_0_reg), 
        .rs_lsu_dout_0                      (dispatch_lsu_0_reg), 
        .rs_lsu_dout_1                      (dispatch_lsu_1_reg),
        .dispatch_inst0_wnum                (set_busy_num_0),
        .dispatch_inst1_wnum                (set_busy_num_1),
        .dispatch_inst0_wen                 (set_busy_0),
        .dispatch_inst1_wen                 (set_busy_1),
        .dispatch_rob                       (dispatch_rob),
        .pause_req                          (dispatch_pause_req)
    );
    dispatch_iq_regs dispatch_iq(
    .clk                                (aclk),
    .rst                                (rst),
    .flush                              (aluIQFlush),
    .rs_alu_ready                       (aluIQReady), 
    .rs_mdu_ready                       (mduIQReady),
    .rs_lsu_ready                       (lsuIQReady), 
    .rs_alu_wen_0_i                     (rs_alu_wen_0_reg), 
    .rs_alu_wen_1_i                     (rs_alu_wen_1_reg), 
    .rs_mdu_wen_0_i                     (rs_mdu_wen_0_reg), 
    .rs_lsu_wen_0_i                     (rs_lsu_wen_0_reg), 
    .rs_lsu_wen_1_i                     (rs_lsu_wen_1_reg),
    .rs_alu_dout_0_i                    (dispatch_alu_0_reg), 
    .rs_alu_dout_1_i                    (dispatch_alu_1_reg),
    .rs_mdu_dout_0_i                    (dispatch_mdu_0_reg), 
    .rs_lsu_dout_0_i                    (dispatch_lsu_0_reg), 
    .rs_lsu_dout_1_i                    (dispatch_lsu_1_reg),
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

    ROB rob(.*);
    scoreboard_20r6w scoreboard_alu(
        .clk                                (aclk),
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
        .clr_busy_LSU                       (lsuWBReq.wen),
        .clr_busy_MDU                       (mduWBReq.wen),
        .clr_busy_num_ALU0                  (wake_reg_ALU_0),
        .clr_busy_num_ALU1                  (wake_reg_ALU_1),
        .clr_busy_num_LSU                   (lsuWBReq.rd),
        .clr_busy_num_MDU                   (mduWBReq.rd), 
        .rd_num_l                           (scoreboard_rd_num_l_aluiq2sb),
        .rd_num_r                           (scoreboard_rd_num_r_aluiq2sb),
        .busyvec_l                          (busyvec_l_sb2aluiq),
        .busyvec_r                          (busyvec_r_sb2aluiq)
    );
    issue_unit_ALU issue_alu(
        .clk                                (aclk),
        .rst                                (rst),
        .flush                              (aluIQFlush),
        .stall                              (0),
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
        .clk                                (aclk),
        .rst                                (rst),
        .flush                              (lsuIQFlush),
        // dispatched instructions
        .set_busy_0                         (set_busy_0),
        .set_busy_1                         (set_busy_1),
        .set_busy_num_0                     (set_busy_num_0),
        .set_busy_num_1                     (set_busy_num_1),
        // issued instructions(at most 4 instructions issue at a time)
        .clr_busy_ALU0                      (alu0_wake_ena),
        .clr_busy_ALU1                      (alu1_wake_ena),
        .clr_busy_LSU                       (lsuWBReq.wen),
        .clr_busy_MDU                       (mduWBReq.wen),
        .clr_busy_num_ALU0                  (alu0_wake_reg),
        .clr_busy_num_ALU1                  (alu1_wake_reg),
        .clr_busy_num_LSU                   (lsuWBReq.rd),
        .clr_busy_num_MDU                   (mduWBReq.rd),
        .rd_num_l                           (scoreboard_rd_num_l_lsuiq2sb),
        .rd_num_r                           (scoreboard_rd_num_r_lsuiq2sb),
        .busyvec_l                          (busyvec_l_sb2lsuiq),
        .busyvec_r                          (busyvec_r_sb2lsuiq)
    );
	wire LSU_half;

    issue_unit_LSU issue_lsu(
        .clk                                (aclk),
        .rst                                (rst),
        .flush                              (lsuIQFlush),
		.lsu_half_full					    (LSU_half),
        .inst_Ops_0                         (dispatch_lsu_0),
        .inst_Ops_1                         (dispatch_lsu_1),
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
        .clk                                (aclk),
        .rst                                (rst),
        .flush                              (mduIQFlush),
        // dispatched instructions
        .set_busy_0                         (set_busy_0),
        .set_busy_1                         (set_busy_1),
        .set_busy_num_0                     (set_busy_num_0),
        .set_busy_num_1                     (set_busy_num_1),
        // issued instructions(at most 4 instructions issue at a time)
        .clr_busy_ALU0                      (alu0_wake_ena),
        .clr_busy_ALU1                      (alu1_wake_ena),
        .clr_busy_LSU                       (lsuWBReq.wen),
        .clr_busy_MDU                       (mduWBReq.wen),
        .clr_busy_num_ALU0                  (alu0_wake_reg),
        .clr_busy_num_ALU1                  (alu1_wake_reg),
        .clr_busy_num_LSU                   (lsuWBReq.rd),
        .clr_busy_num_MDU                   (mduWBReq.rd),
        .rd_num_l                           (scoreboard_rd_num_l_mduiq2sb),
        .rd_num_r                           (scoreboard_rd_num_r_mduiq2sb),
        .busyvec_l                          (busyvec_l_sb2mduiq),
        .busyvec_r                          (busyvec_r_sb2mduiq)
    );

    issue_unit_MDU issue_mdu(
        .clk                                (aclk),
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
        .prfRequest                         (alu0RFReq),
        .wakeReg                            (alu0_wake_reg),
        .wakeEna                            (alu0_wake_ena)
    );
    Issue_RF_regs issue_alu1_regs(
        .*,
        .ctrl_issue_rf_regs                 (ctrl_issue_alu1_regs),
        .issueBundle                        (issue_alu_inst_1),
        .primPauseReq                       (`FALSE),
        .rfBundle                           (alu1RFBundle),
        .prfRequest                         (alu1RFReq),
        .wakeReg                            (alu1_wake_reg),
        .wakeEna                            (alu1_wake_ena)
    );
    Issue_RF_regs issue_lsu_regs(
        .*,
        .ctrl_issue_rf_regs                 (ctrl_issue_lsu_regs),
        .issueBundle                        (issue_lsu_inst),
        .primPauseReq                       (lsu_busy),
        .rfBundle                           (lsuRFBundle),
        .prfRequest                         (lsuRFReq),
        .wakeReg(),
        .wakeEna()
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
        .alu_cp0                            (alu0_cp0),
        .rdata                              (alu0Oprands),
        .bypass_alu0                        (alu0WBReq),
        .bypass_alu1                        (alu1WBReq),
        .wbData                             (alu0WBOut),
        .alu_rob                            (alu0_commit_reg)
    );
    ALU alu1(
        .uops                               (alu1UOPBundle),
        .alu_cp0                            (alu1_cp0_fake),
        .rdata                              (alu1Oprands),
        .bypass_alu0                        (alu0WBReq),
        .bypass_alu1                        (alu1WBReq),
        .wbData                             (alu1WBOut),
        .alu_rob                            (alu1_commit_reg)
    );
    LSU lsu(
        .*,
        .uOP                                (lsuUOPBundle),
        .oprands                            (lsuOprands),
        .wbData                             (lsuWBOut),
		.half_full							(LSU_half)
    );
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
    CP0 cp0(.*);
    Commit commit(.*);


    // synopsys translate_off
    logic sanityCheck0;
    PRFNum sanityCheck0ARF;
    logic sanityCheck1;
    PRFNum sanityCheck1ARF;
    UOPBundle delayedCommitInfo0;
    UOPBundle delayedCommitInfo1;
    always @ (posedge aclk) begin
        // if(commit_rename_valid_0 || commit_rename_valid_1) #1 begin
        //     for(integer i = 0; i < 34; i++) begin
        //         $display("reg %d : %d", i, prf_u.prfs_bank0[rr.u_map_table.committed_rename_map_table_bank0[i]]);
        //     end
        // end
        delayedCommitInfo0 <= rob_commit.uOP0;
        delayedCommitInfo1 <= rob_commit.uOP1;
        // if (commit_rename_valid_0 && commit_rename_req_0.wr_reg_commit) begin
        //     $display("(pAddr %d) regs %d <= 0x%h", commit_rename_req_0.committed_prf, commit_rename_req_0.committed_arf, prf_u.prfs_bank0[commit_rename_req_0.committed_prf]);
        //     $display("instruction info: %s @ 0x%h, isDS = %d", delayedCommitInfo0.uOP.name(), delayedCommitInfo0.pc, delayedCommitInfo0.isDS);
        //     sanityCheck0 <= `TRUE;
        //     sanityCheck0ARF <= commit_rename_req_0.committed_arf;
        // end else sanityCheck0 <= `FALSE;
        // if (commit_rename_valid_1 && commit_rename_req_1.wr_reg_commit) begin
        //     $display("(pAddr %d) regs %d <= 0x%h", commit_rename_req_1.committed_prf, commit_rename_req_1.committed_arf, prf_u.prfs_bank0[commit_rename_req_1.committed_prf]);
        //     $display("instruction info: %s @ 0x%h, isDS = %d", delayedCommitInfo1.uOP.name(), delayedCommitInfo1.pc, delayedCommitInfo1.isDS);
        //     sanityCheck1 <= `TRUE;
        //     sanityCheck1ARF <= commit_rename_req_1.committed_arf;
        // end else sanityCheck1 <= `FALSE;
        // if (commit_rename_valid_0 && commit_rename_req_0.wr_reg_commit) begin
        //     $display("1 %h %h %h", delayedCommitInfo0.pc, commit_rename_req_0.committed_arf, prf_u.prfs_bank0[commit_rename_req_0.committed_prf]);
        // end
        // if (commit_rename_valid_1 && commit_rename_req_1.wr_reg_commit) begin
        //     $display("1 %h %h %h", delayedCommitInfo1.pc, commit_rename_req_1.committed_arf, prf_u.prfs_bank0[commit_rename_req_1.committed_prf]);
        // end
        
    end
    always @ (posedge aclk) begin
        if (sanityCheck0) begin
            $fdisplay("sanity check : reg %d is 0x%h", sanityCheck0ARF, prf_u.prfs_bank0[rr.u_map_table.committed_rename_map_table_bank0[sanityCheck0ARF]]);
        end
        if (sanityCheck1) begin
            $fdisplay("sanity check : reg %d is 0x%h", sanityCheck1ARF, prf_u.prfs_bank0[rr.u_map_table.committed_rename_map_table_bank0[sanityCheck1ARF]]);
        end
    end

    // always @ (negedge ctrl_commit.flushReq) #1 begin
    //     $display("Detect branch prediction failed. redirecting...");
    //     #1
    //     $display("========== arf after refresh ==========");
    //     for(integer i = 0; i < 34; i++) begin
    //         $display("reg %d : 0x%h", i, prf_u.prfs_bank0[rr.u_map_table.committed_rename_map_table_bank0[i]]);
    //     end
    //     $display("========== arf disp finished ==========");
    // end
    
    wire [31:0] debug_regfile[31:0];
    genvar k;
    generate
    for(k=0;k<32;k=k+1) begin
        assign debug_regfile[k] = soc_axi_lite_top.cpu.prf_u.prfs_bank0[soc_axi_lite_top.cpu.rr.u_map_table.committed_rename_map_table_bank0[k]];
    end
    endgenerate
    
    wire debug_pause_by_iCache      = ctrl_iCache.pauseReq;
    wire debug_pause_by_backend     = ctrl_instBuffer.pauseReq;
    
    wire debug_pause_by_alu         = ~aluIQReady;
    wire debug_pause_by_lsu         = ~lsuIQReady;
    wire debug_pause_by_mdu         = ~mduIQReady;
    wire debug_pause_by_rr          = ~renameAllocatable;
    
    wire debug_redirect             = backend_if0.redirect;
    
    logic [31:0]    debug_frontend_pause_count;
    logic [31:0]    debug_backend_pause_count;
    
    logic [31:0]    debug_alu_pause_count;
    logic [31:0]    debug_lsu_pause_count;
    logic [31:0]    debug_mdu_pause_count;
    logic [31:0]    debug_rr_pause_count;
    
    logic [31:0]    debug_redirect_penalty;
    logic [31:0]    debug_total_cycle_count;
    
    wire [31:0]     debug_total_penalty = debug_frontend_pause_count + debug_backend_pause_count + debug_redirect_penalty;
    
    wire            debug_rob_dual_commit = rob_commit.valid && rob_commit.ready && commit.inst0Good && commit.inst1Good;
    wire            debug_rob_single_commit = rob_commit.valid && rob_commit.ready && !debug_rob_dual_commit;
    wire            debug_rob_no_commit = !debug_rob_dual_commit && !debug_rob_single_commit;
    
    logic [31:0]    debug_rob_dual_commit_count;
    logic [31:0]    debug_rob_single_commit_count;
    logic [31:0]    debug_rob_no_commit_count;
    
    always_ff @ (posedge clk) begin
        if(rst) begin
            debug_frontend_pause_count <= 0;
            debug_backend_pause_count <= 0;
            debug_alu_pause_count <= 0;
            debug_lsu_pause_count <= 0;
            debug_mdu_pause_count <= 0;
            debug_rr_pause_count <= 0;
            debug_redirect_penalty <= 0;
            debug_total_cycle_count <= 0;
            debug_rob_dual_commit_count <= 0;
            debug_rob_single_commit_count <= 0;
            debug_rob_no_commit_count <= 0;
        end else begin
            if(debug_pause_by_iCache) debug_frontend_pause_count <= debug_frontend_pause_count + 1;
            if(debug_pause_by_backend) debug_backend_pause_count <= debug_backend_pause_count + 1;
            if(debug_pause_by_alu) debug_alu_pause_count <= debug_alu_pause_count + 1;
            if(debug_pause_by_lsu) debug_lsu_pause_count <= debug_lsu_pause_count + 1;
            if(debug_pause_by_mdu) debug_mdu_pause_count <= debug_mdu_pause_count + 1;
            if(debug_pause_by_rr) debug_rr_pause_count <= debug_rr_pause_count + 1;
            if(debug_redirect) debug_redirect_penalty <= debug_redirect_penalty + 12;
            debug_total_cycle_count <= debug_total_cycle_count + 1;
            
            if(debug_rob_dual_commit) debug_rob_dual_commit_count <= debug_rob_dual_commit_count + 1;
            if(debug_rob_single_commit) debug_rob_single_commit_count <= debug_rob_single_commit_count + 1;
            if(debug_rob_no_commit) debug_rob_no_commit_count <= debug_rob_no_commit_count + 1;
        end
    end
    
    // synopsys translate_on
    
endmodule
