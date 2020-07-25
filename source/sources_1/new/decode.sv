`timescale 1ns / 1ps
`include "defines/defines.svh"


module decode(
    Regs_Decode.decode  regs_decode,
    Decode_Regs.decode  decode_regs
);
    logic   [ 5:0]  opcode;
    logic   [ 5:0]  rs;
    logic   [ 5:0]  rt;
    logic   [ 5:0]  rd;
    logic   [ 5:0]  funct;
    logic   [31:0]  imm;
    logic   [31:0]  imm2;
    logic   [31:0]  imm_ze;
    logic   [31:0]  imm_lui;
    logic   [25:0]  address;
    logic   [31:0]  inst_raw;
    InstBundle      inst;
    UOPBundle       uOP0, uOP1;

    
    assign decode_regs.uOP0 = uOP0;
    assign decode_regs.uOP1 = uOP1;


    assign inst     = regs_decode.inst;
    assign inst_raw = regs_decode.inst.inst;
    assign opcode   = inst_raw[31:26];
    assign rs       = {1'b0, inst_raw[25:21]};
    assign rt       = {1'b0, inst_raw[20:16]};
    assign rd       = {1'b0, inst_raw[15:11]};
    assign funct    = inst_raw[5: 0];
    assign imm      = {{16{inst_raw[15]}}, inst_raw[15: 0]};
    assign imm_ze   = {{16'h0000}, inst_raw[15: 0]};
    assign imm2     = {27'h0, inst_raw[10: 6]};
    assign imm_lui  = { inst_raw[15:0] , 16'b0 };
    assign address  = inst_raw[25: 0];
    // regs_decode.inst: InstBundle

    always_comb begin
        uOP0             = 0;
        uOP1             = 0;
        uOP0.uOP         = NOP_U;
        uOP0.nlpBimState = inst.nlpInfo.valid ? inst.nlpInfo.bimState : 2'b01;
        uOP1.uOP         = NOP_U;
        uOP0.pc          = inst.pc;
        uOP0.predTaken   = inst.predTaken;
        uOP0.predAddr    = inst.predAddr;
        uOP0.isDS        = inst.isDs;
        uOP0.committed   = `FALSE;
        uOP1.pc          = inst.pc;
        uOP1.isDS        = inst.isDs;
        uOP1.committed   = `FALSE;
        if(inst.valid) begin
            uOP0.isPriv     = `FALSE;
            uOP0.branchType = typeNormal;
            uOP0.imm        = imm;
            uOP0.valid      = `TRUE;
            uOP1.valid      = `FALSE;
            uOP0.causeExc   = `FALSE;
            priority casez(inst_raw)
                `NOP: begin
                    uOP0.valid      = `FALSE;
                end
                `ADD: begin
                    uOP0.uOP        = ADD_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `ADDU: begin
                    uOP0.uOP        = ADDU_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `ADDI: begin
                    uOP0.uOP        = ADDI_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `ADDIU: begin
                    uOP0.uOP        = ADDIU_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `SUB: begin
                    uOP0.uOP        = SUB_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `SUBU: begin
                    uOP0.uOP        = SUBU_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `SLT: begin
                    uOP0.uOP        = SLT_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `SLTU: begin
                    uOP0.uOP        = SLTU_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `SLTI: begin
                    uOP0.uOP        = SLTI_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `SLTIU: begin
                    uOP0.uOP        = SLTIU_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_ARITH;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `DIV: begin
                    uOP0.uOP        = DIVHI_U;
                    uOP0.rs_type    = RS_MDU;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = `REGHI;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;

                    uOP1.uOP        = DIVLO_U;
                    uOP1.rs_type    = RS_MDU;
                    uOP1.op0LAddr   = rs;
                    uOP1.op1LAddr   = rt;
                    uOP1.dstLAddr   = `REGLO;
                    uOP1.op0re      = `TRUE;
                    uOP1.op1re      = `TRUE;
                    uOP1.dstwe      = `TRUE;
                    uOP1.valid      = `TRUE;
                end
                `DIVU: begin
                    uOP0.uOP        = DIVUHI_U;
                    uOP0.rs_type    = RS_MDU;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = `REGHI;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;

                    uOP1.uOP        = DIVULO_U;
                    uOP1.rs_type    = RS_MDU;
                    uOP1.op0LAddr   = rs;
                    uOP1.op1LAddr   = rt;
                    uOP1.dstLAddr   = `REGLO;
                    uOP1.op0re      = `TRUE;
                    uOP1.op1re      = `TRUE;
                    uOP1.dstwe      = `TRUE;
                    uOP1.valid      = `TRUE;
                end
                `MULT: begin
                    uOP0.uOP        = MULTHI_U;
                    uOP0.rs_type    = RS_MDU;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = `REGHI;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;

                    uOP1.uOP        = MULTLO_U;
                    uOP1.rs_type    = RS_MDU;
                    uOP1.op0LAddr   = rs;
                    uOP1.op1LAddr   = rt;
                    uOP1.dstLAddr   = `REGLO;
                    uOP1.op0re      = `TRUE;
                    uOP1.op1re      = `TRUE;
                    uOP1.dstwe      = `TRUE;
                    uOP1.valid      = `TRUE;
                end
                `MULTU: begin
                    uOP0.uOP        = MULTUHI_U;
                    uOP0.rs_type    = RS_MDU;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = `REGHI;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;

                    uOP1.uOP        = MULTULO_U;
                    uOP1.rs_type    = RS_MDU;
                    uOP1.op0LAddr   = rs;
                    uOP1.op1LAddr   = rt;
                    uOP1.dstLAddr   = `REGLO;
                    uOP1.op0re      = `TRUE;
                    uOP1.op1re      = `TRUE;
                    uOP1.dstwe      = `TRUE;
                    uOP1.valid      = `TRUE;
                end
                `AND: begin
                    uOP0.uOP        = AND_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_LOGIC;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `ANDI: begin
                    uOP0.uOP        = ANDI_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_LOGIC;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                    uOP0.imm        = imm_ze;
                end
                `OR: begin
                    uOP0.uOP        = OR_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_LOGIC;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `ORI: begin
                    uOP0.uOP        = ORI_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_LOGIC;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                    uOP0.imm        = imm_ze;
                end
                `XOR: begin
                    uOP0.uOP        = XOR_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_LOGIC;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `XORI: begin
                    uOP0.uOP        = XORI_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_LOGIC;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                    uOP0.imm        = imm_ze;
                end
                `NOR: begin
                    uOP0.uOP        = NOR_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_LOGIC;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `LUI: begin         // LUI作为OR处理
                    uOP0.uOP        = LUI_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_LOGIC;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                    uOP0.imm        = imm_lui;
                end
                `SLL: begin
                    uOP0.uOP        = SLL_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_SHIFT;
                    uOP0.op0LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.imm        = imm2;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `SLLV: begin
                    uOP0.uOP        = SLLV_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_SHIFT;
                    uOP0.op0LAddr   = rt;
                    uOP0.op1LAddr   = rs;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `SRA: begin
                    uOP0.uOP        = SRA_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_SHIFT;
                    uOP0.op0LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.imm        = imm2;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `SRAV: begin
                    uOP0.uOP        = SRAV_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_SHIFT;
                    uOP0.op0LAddr   = rt;
                    uOP0.op1LAddr   = rs;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `SRL: begin
                    uOP0.uOP        = SRL_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_SHIFT;
                    uOP0.op0LAddr   = rt;
                    uOP0.dstLAddr   = rd;
                    uOP0.imm        = imm2;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `SRLV: begin
                    uOP0.uOP        = SRLV_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_SHIFT;
                    uOP0.op0LAddr   = rt;
                    uOP0.op1LAddr   = rs;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `TRUE;
                end
                `CLO: begin
                    uOP0.uOP        = CLO_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_COUNT;
                    uOP0.op0LAddr   = rs;
                    uOP1.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `CLZ: begin
                    uOP0.uOP        = CLZ_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_COUNT;
                    uOP0.op0LAddr   = rs;
                    uOP1.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `BEQ: begin
                    uOP0.uOP        = BEQ_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.branchType = typeBR;
                    uOP0.branchAddr = inst.pc + {{14{inst_raw[15]}}, inst_raw[15:0], 2'b00};
                end
                `BNE: begin
                    uOP0.uOP        = BNE_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.branchType = typeBR;
                    uOP0.branchAddr = inst.pc + {{14{inst_raw[15]}}, inst_raw[15:0], 2'b00};
                end
                `BGEZ: begin
                    uOP0.uOP        = BGEZ_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.branchType = typeBR;
                    uOP0.branchAddr = inst.pc + {{14{inst_raw[15]}}, inst_raw[15:0], 2'b00};
                end
                `BGTZ: begin
                    uOP0.uOP        = BGTZ_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.branchType = typeBR;
                    uOP0.branchAddr = inst.pc + {{14{inst_raw[15]}}, inst_raw[15:0], 2'b00};
                end
                `BLEZ: begin
                    uOP0.uOP        = BLEZ_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.branchType = typeBR;
                    uOP0.branchAddr = inst.pc + {{14{inst_raw[15]}}, inst_raw[15:0], 2'b00};
                end
                `BLTZ: begin
                    uOP0.uOP        = BLTZ_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.branchType = typeBR;
                    uOP0.branchAddr = inst.pc + {{14{inst_raw[15]}}, inst_raw[15:0], 2'b00};
                end
                `BGEZAL: begin
                    uOP0.uOP        = BGEZAL_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = `REG31;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                    uOP0.branchType = typeBR;
                    uOP0.branchAddr = inst.pc + {{14{inst_raw[15]}}, inst_raw[15:0], 2'b00};
                end
                `BLTZAL: begin
                    uOP0.uOP        = BLTZAL_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = `REG31;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                    uOP0.branchType = typeBR;
                    uOP0.branchAddr = inst.pc + {{14{inst_raw[15]}}, inst_raw[15:0], 2'b00} + 4;
                end
                `J: begin
                    uOP0.uOP        = J_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.branchType = typeJ;
                    uOP0.branchAddr = {uOP0.pc[31:28], inst_raw[25:0], 2'b00};
                end
                `JAL: begin
                    uOP0.uOP        = JAL_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.dstLAddr   = `REG31;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                    uOP0.branchType = typeJ;
                    uOP0.branchAddr = {uOP0.pc[31:28], inst_raw[25:0], 2'b00};
                end
                `JR: begin
                    uOP0.uOP        = JR_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.branchType = typeJR;
                end
                `JALR: begin
                    uOP0.uOP        = JALR_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_BRANCH;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                    uOP0.branchType = typeJR;
                end
                `MFHI: begin
                    uOP0.uOP        = MFHI_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MOVE;
                    uOP0.op0LAddr   = `REGHI;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `MFLO: begin
                    uOP0.uOP        = MFLO_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MOVE;
                    uOP0.op0LAddr   = `REGLO;
                    uOP0.dstLAddr   = rd;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `MTHI: begin
                    uOP0.uOP        = MTHI_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MOVE;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = `REGHI;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `MTLO: begin
                    uOP0.uOP        = MTLO_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MOVE;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = `REGLO;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `SYSCALL: begin
                    uOP0.uOP        = SYSCALL_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MISC;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.causeExc   = `TRUE;
                    uOP0.exception  = ExcSysCall;
                    uOP0.excCode    = inst[25:6];
                end
                `BREAK: begin
                    uOP0.uOP        = BREAK_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MISC;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.causeExc   = `TRUE;
                    uOP0.exception  = ExcBreak;
                    uOP0.excCode    = inst[25:6];
                end
                `LB: begin
                    uOP0.uOP        = LB_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `LH: begin
                    uOP0.uOP        = LH_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `LBU: begin
                    uOP0.uOP        = LBU_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `LHU: begin
                    uOP0.uOP        = LHU_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `LW: begin
                    uOP0.uOP        = LW_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                end
                `SB: begin
                    uOP0.uOP        = SB_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `FALSE;
                end
                `SH: begin
                    uOP0.uOP        = SH_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `FALSE;
                end
                `SWL: begin
                    uOP0.uOP        = SWL_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `FALSE;
                end
                `SW: begin
                    uOP0.uOP        = SW_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `FALSE;
                end
                `SWR: begin
                    uOP0.uOP        = SWL_U;
                    uOP0.rs_type    = RS_LSU;
                    uOP0.op0LAddr   = rs;
                    uOP0.op1LAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `TRUE;
                    uOP0.dstwe      = `FALSE;
                end
                `ERET: begin
                    uOP0.uOP        = ERET_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MISC;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.causeExc   = `TRUE;
                    uOP0.exception  = ExcEret;
                end
                `MFC0: begin
                    uOP0.uOP        = MFC0_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_CP0;
                    uOP0.dstLAddr   = rt;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `TRUE;
                    uOP0.isPriv     = `TRUE;
                    uOP0.cp0Addr    = rd;
                    uOP0.cp0Sel     = inst[2:0];
                end
                `MTC0: begin
                    uOP0.uOP        = MTC0_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_CP0;
                    uOP0.op0LAddr   = rt;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.isPriv     = `TRUE;
                    uOP0.cp0Addr    = rd;
                    uOP0.cp0Sel     = inst[2:0];
                end
                `TLBP: begin
                    uOP0.uOP        = TLBP_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MISC;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.isPriv     = `TRUE;
                    uOP0.cp0Addr    = `CP0INDEX;
                end
                `TLBWI: begin
                    uOP0.uOP        = TLBP_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MISC;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.isPriv     = `TRUE;
                    // use multiple cp0 reg (EntryHi, EntryLo0, EntryLo1)
                end
                `CACHE: begin
                    uOP0.uOP        = CACHE_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MISC;
                    uOP0.op0LAddr   = rs;
                    uOP0.op0re      = `TRUE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.cacheOP    = inst[16:10];
                end
                `WAIT: begin    // must be priv
                    uOP0.uOP        = WAIT_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MISC;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.isPriv     = `TRUE;
                end
                default: begin
                    uOP0.uOP        = NOP_U;
                    uOP0.rs_type    = RS_ALU;
                    uOP0.aluType    = ALU_MISC;
                    uOP0.op0re      = `FALSE;
                    uOP0.op1re      = `FALSE;
                    uOP0.dstwe      = `FALSE;
                    uOP0.valid      = `FALSE;
                end
            endcase
        end else begin
            uOP0.valid      = `FALSE;
            uOP1.valid      = `FALSE;
        end
    end

endmodule
