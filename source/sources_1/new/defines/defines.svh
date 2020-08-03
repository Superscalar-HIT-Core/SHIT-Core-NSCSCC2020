`include "../defs.sv"
`ifndef DEFINES
`define DEFINES
`define REG_WIDTH 32
`define PRF_NUM_WIDTH 6
`define ARF_NUM_WIDTH 6
`define PRF_NUM 64
`define IQ_ALU_LENGTH 8
`define ALU_OP_WIDTH 4
`define RS_IDX_WIDTH 2

`define CMPQ_SEL_DIN1    2'b00
`define CMPQ_SEL_DIN2    2'b01
`define CMPQ_SEL_UP1    2'b10
`define CMPQ_SEL_UP2    2'b11

`define UOP_WIDTH   7:0
`define ROB_SIZE    64
`define ROB_ID_W    1+`ROB_ADDR_W
`define ROB_ADDR_W  5:0
`define TRUE        1'b1
`define FALSE       1'b0

`define ALU_QUEUE_LEN 8
`define ALU_QUEUE_LEN_MINUS1 7
`define ALU_QUEUE_LEN_MINUS2 6
`define ALU_QUEUE_IDX_LEN 4

`define MDU_QUEUE_LEN 8
`define MDU_QUEUE_LEN_MINUS1 7
`define MDU_QUEUE_LEN_MINUS2 6
`define MDU_QUEUE_IDX_LEN 4

`define LSU_QUEUE_LEN 8
`define LSU_QUEUE_LEN_MINUS1 7
`define LSU_QUEUE_LEN_MINUS2 6
`define LSU_QUEUE_IDX_LEN 4

`define MDU_MUL_CYCLE 2
`define MDU_DIV_CYCLE 16

typedef logic [5:0] PRFNum; // 物理寄存器编�?
typedef logic [5:0] ARFNum; // 逻辑寄存器编�?(�?34�?)
`define REGHI       6'd32
`define REGLO       6'd33
`define REG31       6'd31

`define CP0INDEX    5'd0
`define CP0RANDOM   5'd1
`define CP0ENTRYLO0 5'd2
`define CP0ENTRYLO1 5'd3
`define CP0CONTEXT  5'd4
`define CP0PAGEMASK 5'd5
`define CP0WIRED    5'd6
`define CP0BADVADDR 5'd8
`define CP0COUNT    5'd9
`define CP0ENTRYHI  5'd10
`define CP0COMPARE  5'd11
`define CP0STATUS   5'd12
`define CP0CAUSE    5'd13
`define CP0EPC      5'd14
`define CP0PRID     5'd15
`define CP0EBASE    5'd15
`define CP0CONFIG   5'd16
`define CP0CONFIG1  5'd16
`define CP0ERROREPC 5'd30

`define CP0INDEXMASK    32'b00000000_00000000_00000000_00011111
`define CP0ENTRYLO0MASK 32'b00111111_11111111_11111111_11111111
`define CP0ENTRYLO1MASK 32'b00111111_11111111_11111111_11111111
`define CP0CONTEXTMASK  32'b11111111_10000000_00000000_00000000
`define CP0PAGEMASKMASK 32'b00011111_11111111_11100000_00000000
`define CP0WIREDMASK    32'b00000000_00000000_00000000_00011111
`define CP0COUNTMASK    32'b11111111_11111111_11111111_11111111
`define CP0ENTRYHIMASK  32'b11111111_11111111_11100000_11111111
`define CP0COMPAREMASK  32'b11111111_11111111_11111111_11111111
`define CP0STATUSMASK   32'b11111010_01111000_11111111_00010111
`define CP0CAUSEMASK    32'b00000000_11000000_00000011_00000000
`define CP0EPCMASK      32'b11111111_11111111_11111111_11111111
`define CP0EBASEMASK    32'b10111111_11111111_11110000_00000000
`define CP0CONFIGMASK   32'b00000000_00000000_00000000_00000111
`define CP0ERROREPCMASK 32'b11111111_11111111_11111111_11111111

// Cause ExcCode
`define Exc_INT 5'h00
`define Exc_ADEL 5'h04
`define Exc_ADES 5'h05
`define Exc_OV 5'h0c
`define Exc_SYS 5'h08
`define Exc_BP 5'h09
`define Exc_RI 5'h0a

`define CP0ADDR     4:0
`define CP0SEL      2:0

// arithmetic
`define ADD         32'b000000??_????????_?????000_00100000
`define ADDI        32'b001000??_????????_????????_????????
`define ADDU        32'b000000??_????????_?????000_00100001
`define ADDIU       32'b001001??_????????_????????_????????
`define SUB         32'b000000??_????????_?????000_00100010
`define SUBU        32'b000000??_????????_?????000_00100011
`define SLT         32'b000000??_????????_?????000_00101010
`define SLTI        32'b001010??_????????_????????_????????
`define SLTU        32'b000000??_????????_?????000_00101011
`define SLTIU       32'b001011??_????????_????????_????????
`define DIV         32'b000000??_????????_00000000_00011010
`define DIVU        32'b000000??_????????_00000000_00011011
`define MULT        32'b000000??_????????_00000000_00011000
`define MULTU       32'b000000??_????????_00000000_00011001

// logical
`define AND         32'b000000??_????????_?????000_00100100
`define ANDI        32'b001100??_????????_????????_????????
`define LUI         32'b00111100_000?????_????????_????????
`define NOR         32'b000000??_????????_?????000_00100111
`define OR          32'b000000??_????????_?????000_00100101
`define ORI         32'b001101??_????????_????????_????????
`define XOR         32'b000000??_????????_?????000_00100110
`define XORI        32'b001110??_????????_????????_????????
`define CLZ         32'b011100??_????????_?????000_00100000
`define CLO         32'b011100??_????????_?????000_00100001

// shift
`define SLL         32'b00000000_000?????_????????_??000000
`define SLLV        32'b000000??_????????_?????000_00000100
`define SRA         32'b00000000_000?????_????????_??000011
`define SRAV        32'b000000??_????????_?????000_00000111
`define SRL         32'b00000000_000?????_????????_??000010
`define SRLV        32'b000000??_????????_?????000_00000110

// branch
`define BEQ         32'b000100??_????????_????????_????????
`define BNE         32'b000101??_????????_????????_????????
`define BGEZ        32'b000001??_???00001_????????_????????
`define BGTZ        32'b000111??_???00000_????????_????????
`define BLEZ        32'b000110??_???00000_????????_????????
`define BLTZ        32'b000001??_???00000_????????_????????
`define BGEZAL      32'b000001??_???10001_????????_????????
`define BLTZAL      32'b000001??_???10000_????????_????????
`define J           32'b000010??_????????_????????_????????
`define JAL         32'b000011??_????????_????????_????????
`define JR          32'b000000??_???00000_00000000_00001000
`define JALR        32'b000000??_???00000_?????000_00001001

// move
`define MFHI        32'b00000000_00000000_?????000_00010000
`define MTHI        32'b000000??_???00000_00000000_00010001
`define MFLO        32'b00000000_00000000_?????000_00010010
`define MTLO        32'b000000??_???00000_00000000_00010011

// exception
`define SYSCALL     32'b000000??_????????_????????_??001100
`define BREAK       32'b000000??_????????_????????_??001101

// load/store
`define LB          32'b100000??_????????_????????_????????
`define LH          32'b100001??_????????_????????_????????
`define LBU         32'b100100??_????????_????????_????????
`define LHU         32'b100101??_????????_????????_????????
`define LW          32'b100011??_????????_????????_????????
`define SB          32'b101000??_????????_????????_????????
`define SH          32'b101001??_????????_????????_????????
`define SW          32'b101011??_????????_????????_????????
`define SWL         32'b101010??_????????_????????_????????
`define SWR         32'b101110??_????????_????????_????????

// privilege
`define ERET        32'b01000010_00000000_00000000_00011000
`define MFC0        32'b01000000_000?????_?????000_00000???
`define MTC0        32'b01000000_100?????_?????000_00000???

// misc
`define CACHE       32'b101111??_????????_????????_????????
`define NOP         32'b00000000_00000000_00000000_00000000
`define TLBP        32'b01000010_00000000_00000000_00001000
`define TLBWI       32'b01000010_00000000_00000000_00000010
`define WAIT        32'b0100001?_????????_????????_??100000

//arithmetic
`define ADD_U       8'b00000000
`define ADDI_U      8'b00000001
`define ADDU_U      8'b00000010
`define ADDIU_U     8'b00000011
`define SUB_U       8'b00000100
`define SUBU_U      8'b00000101
`define SLT_U       8'b00000110
`define SLTI_U      8'b00000111
`define SLTU_U      8'b00001000
`define SLTIU_U     8'b00001001
`define DIVHI_U     8'b00001010
`define DIVLO_U     8'b00001011
`define DIVUHI_U    8'b00001100
`define DIVULO_U    8'b00001101
`define MULTHI_U    8'b00001110
`define MULTLO_U    8'b00001111
`define MULTUHI_U   8'b00010000
`define MULTULO_U   8'b00010001

//logical_U
`define AND_U       8'b00010010
`define ANDI_U      8'b00010011
`define LUI_U       8'b00010100
`define NOR_U       8'b00010101
`define OR_U        8'b00010110
`define ORI_U       8'b00010111
`define XOR_U       8'b00011000
`define XORI_U      8'b00011001
`define CLZ_U       8'b00011010
`define CLO_U       8'b00011011

//shift_U
`define SLL_U       8'b00011100
`define SLLV_U      8'b00011101
`define SRA_U       8'b00011110
`define SRAV_U      8'b00011111
`define SRL_U       8'b00100000
`define SRLV_U      8'b00100001

//branch_U
`define BEQ_U       8'b00100010
`define BNE_U       8'b00100011
`define BGEZ_U      8'b00100100
`define BGTZ_U      8'b00100101
`define BLEZ_U      8'b00100110
`define BLTZ_U      8'b00100111
`define BGEZAL_U    8'b00101000
`define BLTZAL_U    8'b00101001
`define J_U         8'b00101010
`define JAL_U       8'b00101011
`define JR_U        8'b00101100
`define JALR_U      8'b00101101

//move_U
`define MFHI_U      8'b00101110
`define MTHI_U      8'b00101111
`define MFLO_U      8'b00110000
`define MTLO_U      8'b00110001

//exception_U
`define SYSCALL_U   8'b00110010
`define BREAK_U     8'b00110011

//load/store_U
`define LB_U        8'b00110100
`define LH_U        8'b00110101
`define LBU_U       8'b00110110
`define LHU_U       8'b00110111
`define LW_U        8'b00111000
`define SB_U        8'b00111001
`define SH_U        8'b00111010
`define SW_U        8'b00111011
`define SWL_U       8'b00111100
`define SWR_U       8'b00111101

//privilege_U
`define ERET_U      8'b00111110
`define MFC0_U      8'b00111111
`define MTC0_U      8'b01000000
`define TLBP_U      8'b01000011
`define TLBWI_U     8'b01000100

//misc_U
`define CACHE_U     8'b01000001
`define NOP_U       8'b01000010
`define WAIT_U      8'b01000101

// BranchPred
`define GHLEN 20
`define BHRLEN 4
`define PHTIDXLEN_G 12 
typedef logic [`GHLEN-1:0] GlobalHist;           // Index used for indexing BHR Table
typedef logic [1:0] PHTEntry;           // One entry in PHT Table
typedef logic [`PHTIDXLEN_G-1:0] PHTIndex_G;           // PHT Index
typedef struct packed {
    PHTIndex_G pht_index_g;
} GlobalHistPred;

`define BHTIDXLEN 8
`define BHRLEN 4
`define PHTIDXLEN 10 
`define CPHT_ENTRY 1024
typedef logic [`BHTIDXLEN-1:0] BHTIndex;           // Index used for indexing BHR Table
typedef logic [`BHRLEN-1:0] BHREntry;           // One entry in BHR Table
typedef logic [`PHTIDXLEN-1:0] PHTIndex;           // PHT Index
typedef logic [9:0] CPHTIndex;
typedef logic [1:0] CPHT_Entry;
typedef struct packed {
    BHTIndex bht_index;
    PHTIndex pht_index;
} LocalHistPred;

typedef struct packed {
    BHTIndex bht_index;
    PHTIndex pht_index;
    PHTIndex_G pht_index_g;
    CPHTIndex cpht_index;
    logic use_global;
} PredInfo;



typedef logic [9:0] TAGEIndex;
typedef logic [2:0] TAGECtr;
typedef logic [7:0] TAGETag;
typedef logic [1:0] TAGEUseful;

typedef struct packed {
    logic hit;                                            // 预测命中
    TAGEIndex hit_index;                                  // 预测的index，以防历史记录改�?
    TAGEIndex on_mispred_index;                           // 预测错误时，要分配的新项的index
    logic [1:0] on_mispred_bank;                          // 预测错误时，�?要分配哪个Bank
    TAGETag hit_tag;            // 命中的Tag
    TAGETag on_mispred_tag;     // 错误预测时，更新的新项的Tag
    logic has_free_to_alloc;    // 预测错误时，有新项可以分�?
    TAGECtr ctr;                // 三位饱和计数�?
    logic [1:0] provider;                             // 
    logic has_alter;
} TAGEPred;

typedef struct packed {
    logic   [31:0]  inst;
    logic   [31:0]  pc;
    logic           isBr;
    logic           isDs;
    logic           isJ;
    logic           valid;
    NLPPredInfo     nlpInfo;
    PredInfo        bpdInfo;
    logic           predTaken;
    logic   [31:0]  predAddr;
    logic           jBadAddr;
} InstBundle;

typedef enum bit[7:0] {
    //     NOP_U  移到第一个，为了方便观察
    NOP_U       ,
    //arithmetic
    ADD_U       ,
    ADDI_U      ,
    ADDU_U      ,
    ADDIU_U     ,
    SUB_U       ,
    SUBU_U      ,
    SLT_U       ,
    SLTI_U      ,
    SLTU_U      ,
    SLTIU_U     ,
    // MDU, not in ALU
    DIVHI_U     ,
    DIVLO_U     ,
    DIVUHI_U    ,
    DIVULO_U    ,
    MULTHI_U    ,
    MULTLO_U    ,
    MULTUHI_U   ,
    MULTULO_U   ,
    //logical_U,
    AND_U       ,
    ANDI_U      ,
    LUI_U       ,
    NOR_U       ,
    OR_U        ,
    ORI_U       ,
    XOR_U       ,
    XORI_U      ,
    CLZ_U       ,
    CLO_U       ,
    //shift_U,
    SLL_U       ,
    SLLV_U      ,
    SRA_U       ,
    SRAV_U      ,
    SRL_U       ,
    SRLV_U      ,
    //branch_U,
    BEQ_U       ,
    BNE_U       ,
    BGEZ_U      ,
    BGTZ_U      ,
    BLEZ_U      ,
    BLTZ_U      ,
    BGEZAL_U    ,
    BLTZAL_U    ,
    J_U         ,
    JAL_U       ,
    JR_U        ,
    JALR_U      ,
    //move_U,
    MFHI_U      ,
    MTHI_U      ,
    MFLO_U      ,
    MTLO_U      ,
    //exception_U
    SYSCALL_U   ,
    BREAK_U     ,
    //load/store_U
    LB_U        ,
    LH_U        ,
    LBU_U       ,
    LHU_U       ,
    LW_U        ,
    SB_U        ,
    SH_U        ,
    SW_U        ,
    SWL_U       ,
    SWR_U       ,
    //privilege_U,
    ERET_U      ,
    MFC0_U      ,
    MTC0_U      ,
    TLBP_U      ,
    TLBWI_U     ,
    //misc_U,
    CACHE_U     ,
    WAIT_U      ,
    MDBUBBLE_U  ,
    RESERVED_U
} uOP;

typedef enum bit [1:0] {
    RS_ALU, RS_MDU, RS_LSU, CP0
} RS_Type;

typedef logic [63:0] PRF_Vec;
typedef logic [31:0] Word;
typedef logic [`ALU_OP_WIDTH-1:0] ALUOP;
typedef logic [`RS_IDX_WIDTH-1:0] RSNum;

typedef enum bit[1:0] { typeJ, typeBR, typeJR, typeNormal } BranchType;


typedef enum bit[3:0] {
    ExcIntOverflow,
    ExcInterrupt,
    ExcCpUnuseable,
    ExcSysCall,
    ExcBreak,
    ExcReservedInst,
    ExcTLBErrL,
    ExcTLBErrS,
    ExcTLBModified,
    ExcAddressErrIF,
    ExcAddressErrL,
    ExcAddressErrS,
    ExcEret
} ExceptionType;

typedef struct packed {
    PRFNum prf_rs1;
    PRFNum prf_rs2;
    PRFNum prf_rd_stale;
} rename_table_output;          // 重命名表的三个输�?

typedef struct packed {
    ARFNum ars1, ars2, ard;         // 指令的两个源寄存器，逻辑寄存�?
    logic wen;                      // 指令写寄存器
} rename_req;

typedef struct packed {
    // From the instruction
    rename_req req;
    // 从Free List来的
    PRFNum prf_rd_new;
} rename_table_input ;

typedef struct packed {
    ARFNum committed_arf;        // 被提交的ARF信息
    PRFNum committed_prf;        // 被提交的PRF信息
    PRFNum stale_prf;           // 旧的PRF，需要被释放�?
    logic wr_reg_commit;         // the instruction actually write the register
} commit_info;

typedef struct packed {
    PRFNum prf_rs1;
    PRFNum prf_rs2;
    PRFNum prf_rd_stale;
    PRFNum new_prd;
} rename_resp;

// typedef struct packed {
//     Word PC;  // 指令的PC
//     // 只保存寄存器的编号，寄存器的值发射的时�?�再�?
//     PRFNum prs1;
//     PRFNum prs2;
//     // �?要读寄存�?
//     logic rs1_ren;
//     logic rs2_ren;
//     PRFNum prd;
//     PRFNum prd_stale;
//     logic wen;
//     Word imm;
//     ALUOP alu_op;
//     logic is_ds_i; // 是否为延迟槽指令
//     logic is_special_i;  // 是否是特殊的指令，例�?0等等，需要单独的发射
// } ALU_Inst_Ops;

typedef struct packed {
    logic wen_0, wen_1, wen_2, wen_3;
    PRFNum wb_num0_i, wb_num1_i, wb_num2_i, wb_num3_i;  //唤醒信息
} Wake_Info;

typedef struct packed {
    logic prs1_rdy, prs2_rdy;
} Arbitration_Info;
// *_rdy = waked_up | busy list[i] = not busy

typedef struct packed {
    logic cmp_en;
    logic enq_en;
    logic enq_sel;
    logic cmp_sel;
    logic freeze;
} Queue_Ctrl_Meta;

typedef struct packed { // TODO
    RSNum rs_num;
    logic[100:0] PlaceHolder;
} Decode_ops;

typedef struct packed {
    PRFNum rs0;
    PRFNum rs1;
} PRFrNums;

typedef struct packed { 
    PRFNum rd;
    logic wen;
    Word wdata;
} PRFwInfo;

typedef struct packed { // TODO
    Word rs0_data;
    Word rs1_data;
} PRFrData;

typedef enum bit[3:0] {
    ALU_LOGIC, ALU_SHIFT, ALU_ARITH, ALU_MOVE, ALU_BRANCH, ALU_COUNT, ALU_MISC, ALU_CP0
} ALUType;

typedef struct packed {
    logic [31:0]    pc;
    logic [1 :0]    bimState;
    logic [31:0]    targetAddr;
    logic           valid;
} NLPEntry;

typedef struct packed {
    // logic   [`UOP_WIDTH]    uOP;
    logic   [31:0]          pc;
    logic   [`ROB_ID_W]     id;
    uOP                     uOP;
    
    ALUType                 aluType;
    logic   [4:0]           cacheOP;
    RS_Type                 rs_type;

    ARFNum                  op0LAddr;   // logical
    PRFNum                  op0PAddr;   // physical
    logic                   op0re;

    ARFNum                  op1LAddr;
    PRFNum                  op1PAddr;
    logic                   op1re;

    ARFNum                  dstLAddr;
    PRFNum                  dstPAddr;
    PRFNum                  dstPStale;
    logic                   dstwe;

    logic   [31:0]          imm;

    BranchType              branchType;
    logic                   branchTaken;
    logic   [31:0]          branchAddr;

    logic                   predTaken;
    logic   [31:0]          predAddr;
    PredInfo                predInfo;
    logic   [1:0]           nlpBimState;

    logic                   causeExc;
    ExceptionType           exception;
    logic   [31:0]          BadVAddr;



    logic                   isDS;
    logic                   isPriv;
    logic   [4:0]           cp0Addr;
    logic   [31:0]          cp0Data;
    logic   [2:0]           cp0Sel;
    logic                   busy;
    logic                   valid;
    logic                   committed;  // is it committed before?
    // TODO
} UOPBundle;



interface Ctrl;
    logic   pauseReq;
    logic   flushReq;
    logic   pause;
    logic   flush;

    modport master(input pauseReq, flushReq, output pause, flush);
    modport slave(output pauseReq, flushReq, input pause, flush);

    task automatic startPause(ref logic clk);
        @(posedge clk) #1 pause = `TRUE;
    endtask //automatic

    task automatic stopPause(ref logic clk);
        @(posedge clk) #1 pause = `FALSE;
    endtask //automatic
endinterface //Ctrl

interface Dispatch_ROB;
    UOPBundle   uOP0;
    UOPBundle   uOP1;
    logic       ready;
    logic       valid;
    logic       empty;
    logic [`ROB_ID_W] robID;

    modport dispatch(output uOP0, uOP1, valid, input ready, empty, robID);
    modport rob(input uOP0, uOP1, valid, output ready, empty, robID);

    task automatic sendUOP(logic [31:0] pc0, logic valid0, logic [31:0] pc1, logic valid1, ref logic clk);
        #1
        uOP0.pc     = pc0;
        uOP0.valid  = valid0;
        uOP0.busy   = `TRUE;

        uOP1.pc     = pc1;
        uOP1.valid  = valid1;
        uOP1.busy   = `TRUE;

        valid       = `TRUE;
        do @(posedge clk);
        while(!ready);
        #1
        valid       = `FALSE;
    endtask //automatic
endinterface //Dispatch_ROB

interface FU_ROB;
    logic               setFinish;
    logic [`ROB_ID_W]   id;

    logic               setBranchStatus;
    logic               branchTaken;
    logic [31:0]        branchAddr;

    logic               setException;
    ExceptionType       exceptionType;
    logic [31:0]        BadVAddr;

    task automatic sendFinish(logic [`ROB_ID_W] idIn, ref logic clk);
        id          = idIn;
        setFinish   = `TRUE;
        @(posedge clk) #1 begin
            setFinish   = `FALSE;
        end
    endtask //automatic

    modport fu(output setFinish, id, setBranchStatus, branchTaken, branchAddr, setException, exceptionType, BadVAddr);
    modport rob(input setFinish, id, setBranchStatus, branchTaken, branchAddr, setException, exceptionType, BadVAddr);
endinterface //FU_ROB

interface ROB_Commit;
    UOPBundle   uOP0;
    UOPBundle   uOP1;
    logic       ready;
    logic       valid;
    
    modport rob(output uOP0, uOP1, valid, input ready);
    modport commit(input uOP0, uOP1, valid, output ready);

    task automatic commitUOP(ref logic clk);
        #1
        ready   = `TRUE;
        do  @(posedge clk);
        while(!valid);
        $display(
            "commit:%h, %h", 
            (!uOP0.busy && uOP0.valid && !uOP0.committed ? uOP0.pc : 32'hX), 
            (!uOP1.busy && uOP1.valid && !uOP1.committed ? uOP1.pc : 32'hx)
        );
        #1
        ready   = `FALSE;
    endtask //automatic
endinterface //ROB_Commit

interface ALU_ISSUE_INFO;
    // 发射的两条指令的ALU基本操作
    ALU_Inst_Ops   uOP;
    logic       ready;
    logic       valid;
    
    modport issue_unit(output uOP, valid, input ready);
    modport pipe_reg(input uOP, valid, output ready);

endinterface //ALU_ISSUE_INFO
interface InstBuffer_Backend;
    InstBundle      inst0;
    InstBundle      inst1;
    logic           valid;
    logic           ready;
    logic           flushReq;

    modport instBuffer(output inst0, inst1, valid, input ready, flushReq);
    modport backend(input inst0, inst1, valid, output ready, flushReq);
    
    task automatic getResp(ref logic clk);
        ready       =   `TRUE;
        flushReq    =   `FALSE;
        do @(posedge clk);
        while (!valid);
        $display("get pc: %h, %h", inst0.valid ? inst0.pc : 32'bX, inst1.valid ? inst1.pc : 32'bX);
        #1
        ready   =   `FALSE;
    endtask //automatic
endinterface //IFU_InstBuffer

interface Regs_Decode;
    InstBundle  inst;

    modport regs(output inst);
    modport decode(input inst);
endinterface //Regs_Decode

interface Decode_Regs;
    UOPBundle   uOP0;
    UOPBundle   uOP1;

    modport decode(output uOP0, uOP1);
    modport regs(input uOP0, uOP1);
endinterface //Decode_Regs

interface Regs_Rename;
    UOPBundle   uOP0;
    UOPBundle   uOP1;

    modport regs(output uOP0, uOP1);
    modport dispatch(input uOP0, uOP1);
endinterface //Regs_Dispatch

interface CP0WRInterface;
    logic [`CP0ADDR]    addr;
    logic [`CP0SEL]     sel;
    logic [31:0]        readData;
    logic [31:0]        writeData;
    logic               writeEn;
    modport req(output addr, writeData, writeEn, sel, input readData);
    modport cp0(input addr, writeData, writeEn, sel, output readData);
endinterface //CP0WRInterface

interface CP0StatusRegs;
    logic [31:0]    count;
    logic [31:0]    status;
    logic [31:0]    cause;
    logic [31:0]    ePc;
    logic [31:0]    eBase;
    logic [31:0]    random;
    logic           counterInt;

    modport cp0(output count, status, cause, ePc, eBase, random, counterInt);
    modport recv(input count, status, cause, ePc, eBase, random, counterInt);
endinterface //CP0Status

interface CP0Exception;
    logic         causeExce;
    ExceptionType exceType;
    Word          excePC;
    logic         isDS;
    logic[5:0]    interrupt;
    Word          reserved;
    logic         Counter_Int;
    logic         Status_IE;
    logic         Status_EXL;
    logic[5:0]    Status_IM;
    logic[1:0]    Status_IM_SW;
    logic[1:0]    Cause_IP_SW;
    Word          EPc;
    modport cp0(input causeExce, exceType, excePC, isDS, interrupt, reserved, output EPc, Status_IE, Status_EXL, Status_IM, Status_IM_SW, Cause_IP_SW, Counter_Int);
    modport exce(output causeExce, exceType, excePC, isDS, interrupt,  reserved, input EPc, Status_IE, Status_EXL, Status_IM, Status_IM_SW, Cause_IP_SW, Counter_Int);
endinterface //CP0 ----- Exception

interface CommitExce;
    logic         causeExce;
    ExceptionType exceType;
    Word          excePC;
    logic         isDS;
    Word          reserved;
    Word          redirectPC;
    logic         redirectReq;
    modport commit( input redirectPC, redirectReq,
                    output causeExce, exceType, excePC, isDS, reserved);
    modport exce( output redirectPC, redirectReq,
                    input causeExce, exceType, excePC, isDS, reserved);    
endinterface // Commit ---- Exception

interface CP0_TLB;
    logic           writeEn;
    logic   [31:0]  rEntryHi;
    logic   [31:0]  rPageMask;
    logic   [31:0]  rEntryLo0;
    logic   [31:0]  rEntryLo1;
    logic   [31:0]  wEntryHi;
    logic   [31:0]  wPageMask;
    logic   [31:0]  wEntryLo0;
    logic   [31:0]  wEntryLo1;

    modport cp0(
        output rEntryHi, rPageMask, rEntryLo0, rEntryLo1,
        input writeEn, wEntryHi, wPageMask, wEntryLo0, wEntryLo1
    );
    modport tlb(
        input rEntryHi, rPageMask, rEntryLo0, rEntryLo1,
        output writeEn, wEntryHi, wPageMask, wEntryLo0, wEntryLo1
    );
endinterface //CP0_TLB

interface MDUTestInterface_MUL;
    wire         clk;
    UOPBundle    uopHi;
    UOPBundle    uopLo;
    PRFrData     rdata;
    logic        mulBusy;

    task automatic init();
        uopHi           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
        uopLo           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
        rdata.rs0_data  = 32'hZZZZZZZZ;
        rdata.rs1_data  = 32'hZZZZZZZZ;
    endtask //automatic

    task automatic sendMul(logic [31:0] mul1, logic [31:0] mul2, logic[`ROB_ID_W] id);
        while (mulBusy) @(posedge clk) #1 begin
            uopHi           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
            uopLo           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
            rdata.rs0_data  = 32'hZZZZZZZZ;
            rdata.rs1_data  = 32'hZZZZZZZZ;
        end
        uopHi.valid     = `TRUE;
        uopLo.valid     = `TRUE;
        uopHi.uOP       = MULTHI_U;
        uopHi.id        = id;
        uopLo.id        = id + 1;
        uopLo.uOP       = MULTLO_U;
        rdata.rs0_data  = mul1;
        rdata.rs1_data  = mul2;
        @ (posedge clk) #1 begin
            uopHi           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
            uopLo           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
            rdata.rs0_data  = 32'hZZZZZZZZ;
            rdata.rs1_data  = 32'hZZZZZZZZ;
        end
    endtask //automatic
endinterface //MDUTestInterface_MUL

interface UncachedLoadInfo;
    UOPBundle   head0;
    UOPBundle   head1;
    logic       isEmpty;

    modport rob(output head0, head1, isEmpty);
    modport lsu(input head0, head1, isEmpty);
endinterface

interface MDUTestInterface_DIV;
    wire         clk;
    UOPBundle    uopHi;
    UOPBundle    uopLo;
    PRFrData     rdata;
    logic        divBusy;

    task automatic init();
        uopHi           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
        uopLo           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
        rdata.rs0_data  = 32'hZZZZZZZZ;
        rdata.rs1_data  = 32'hZZZZZZZZ;
    endtask //automatic

    task automatic sendDiv(logic [31:0] div1, logic [31:0] div2, logic[`ROB_ID_W] id, ref logic mulIsReq);
        while (divBusy || mulIsReq) @(posedge clk) #1 begin
            uopHi           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
            uopLo           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
            rdata.rs0_data  = 32'hZZZZZZZZ;
            rdata.rs1_data  = 32'hZZZZZZZZ;
        end
        uopHi.valid     = `TRUE;
        uopLo.valid     = `TRUE;
        uopHi.uOP       = DIVHI_U;
        uopLo.uOP       = DIVLO_U;
        uopHi.id        = id;
        uopLo.id        = id + 1;
        rdata.rs0_data  = div2;
        rdata.rs1_data  = div1;
        @ (posedge clk) #1 begin
            uopHi           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
            uopLo           = 300'hZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
            rdata.rs0_data  = 32'hZZZZZZZZ;
            rdata.rs1_data  = 32'hZZZZZZZZ;
        end
    endtask //automatic
endinterface //MDUTestInterface_DIV

typedef struct packed {
    UOPBundle ops;
    Arbitration_Info rdys;
} ALU_Queue_Meta;

typedef struct packed {
    UOPBundle ops_hi;
    UOPBundle ops_lo;
    Arbitration_Info rdys;
    logic isMul;
} MDU_Queue_Meta;

typedef struct packed {
    UOPBundle ops;
    logic isStore;
    Arbitration_Info rdys;
} LSU_Queue_Meta;

typedef struct packed {
    PRFNum wrNum;
    Word wData;
    logic wen;
} BypassInfo;

// `define DEBUG


`endif 