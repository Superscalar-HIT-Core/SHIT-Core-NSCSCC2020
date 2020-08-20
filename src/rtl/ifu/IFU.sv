`timescale 1ns / 1ps
`include "../defs.sv"

module IFU(
    input wire          clk,
    input wire          rst,

    InstReq             instReq,
    InstResp            instResp,
    
    Ctrl                ctrl_if0_1_regs,
    Ctrl                ctrl_if2_3_regs,
    Ctrl                ctrl_iCache,
    Ctrl                ctrl_if3,
    Ctrl                ctrl_if3_output_regs,
    Ctrl                ctrl_nlp,
    Ctrl                ctrl_bpd_s0,
    Ctrl                ctrl_bpd_s1,
    ICache_TLB          iCache_tlb,
    BackendRedirect     backend_if0,
    BPDUpdate           backend_bpd,
    NLPUpdate           backend_nlp,

    IFU_InstBuffer      ifu_instBuffer
);
    
    NLP_IF0             nlp_if0();
    IF3Redirect         if3_0();
    IF0_Regs            if0_regs();

    //Regs_IF1            regs_if1();
    Regs_NLP            regs_nlp();
    Regs_BPD            regs_bpd();
    Regs_ICache         regs_iCache();

    ICache_Regs         iCache_regs();

    Regs_IF3            regs_if3();
    BPD_IF3             bpd_if3();

    IF3_Regs            if3_regs();
    NLPUpdate           if3_nlp();
    
    IF_0            if0(.*);
    IF0_1_reg       if01reg(.*);
    NLP             nlp(.*);
    ICache          iCache(.*);
    IF2_3_reg       if23reg(.*);
    IF_3            if3(.*);
    IF3_Output_reg  if3OutputReg(.*);

    // TAGEPred pred_info;
    // TAGE u_TAGE(
    //     .clk                    (clk                    ),
    //     .rst                    (rst                    ),
    //     .pause                  (ctrl_tage.pause        ),
    //     .recover                (ctrl_tage.flush        ),
    //     .IF3_isBranch           (IF3_isBranch           ),
    //     .IF3_isJ                (IF3_isJ                ),
    //     .br_pc                  (regs_iCache.PC         ),
    //     // 送出的结�?
    //     .pred_valid             (pred_valid             ),
    //     .pred_taken             (pred_taken             ),
    //     .pred_target            (pred_target            ),
    //     .pred_info              (pred_info              ),
    //     // 从commit阶段来的
    //     .commit_valid           (backend_bpd.updValid   ),
    //     .committed_target       (backend_bpd.updTarget  ),
    //     .committed_pred_info    (backend_bpd.updInfo    ),
    //     .committed_branch_taken (backend_bpd.updTaken   ),
    //     .committed_mispred      (backend_bpd.updMisPred )
    // );
    logic IF3_isBranch, IF3_isJ;
    wire [31:0] pred_target;
    wire pred_valid, pred_taken;
    PredInfo pred_info;
    Predictor bpd_u(
        .clk                    (clk                    ),
        .rst                    (rst                    ),
        .pause                  (ctrl_bpd_s0.pause      ),
        .hold                   (ctrl_bpd_s1.pause      ),
        .pred_valid             (pred_valid             ),
    // 注意：此处的recover接的是regfile的recover，需要等分支指令提交进来了再进行恢复
        .recover                (ctrl_bpd_s0.flush        ),
        .IF3_isBR               (IF3_isBranch           ),
        .IF3_isJ                (IF3_isJ                ),
        .br_PC                  (regs_iCache.PC         ),
        .pred_info              (pred_info              ),
        .pred_taken             (pred_taken             ),
        .pred_target            (pred_target            ),
        .commit_valid           (backend_bpd.updValid   ),
        .committed_pred_info    (backend_bpd.updInfo    ),
        .committed_branch_taken (backend_bpd.updTaken   ),
        .committed_mispred      (backend_bpd.updMisPred ),
        .commit_update_target_en(backend_bpd.updTarget_en),
        .committed_target       (backend_bpd.updTarget   )
);  
endmodule