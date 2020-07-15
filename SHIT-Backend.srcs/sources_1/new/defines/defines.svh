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

`define RS_ALU 2'b00
`define RS_MDU 2'b01
`define RS_LSU 2'b10

`define UOP_WIDTH   7:0
`define ROB_SIZE    64
`define ROB_ID_W    1+`ROB_ADDR_W
`define ROB_ADDR_W  5:0
`define TRUE        1'b1
`define FALSE       1'b0

typedef logic [5:0] PRFNum; // 物理寄存器编号
typedef logic [5:0] ARFNum; // 逻辑寄存器编号(共34个)
typedef logic [63:0] PRF_Vec;
typedef logic [31:0] Word;
typedef logic [`ALU_OP_WIDTH-1:0] ALUOP;
typedef logic [`RS_IDX_WIDTH-1:0] RSNum;

typedef struct packed {
    PRFNum prf_rs1;
    PRFNum prf_rs2;
    PRFNum prf_rd_stale;
} rename_table_output;          // 重命名表的三个输出

typedef struct packed {
    ARFNum ars1, ars2, ard;         // 指令的两个源寄存器，逻辑寄存器
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
    PRFNum stale_prf;           // 旧的PRF，需要被释放的
    logic wr_reg_commit;         // the instruction actually write the register
} commit_info;

typedef struct packed {
    PRFNum prf_rs1;
    PRFNum prf_rs2;
    PRFNum prf_rd_stale;
    PRFNum new_prd;
} rename_resp;

typedef struct packed {
    Word PC;  // 指令的PC
    // 只保存寄存器的编号，寄存器的值发射的时候再给
    PRFNum prs1;
    PRFNum prs2;
    // 需要读寄存器
    logic rs1_ren;
    logic rs2_ren;
    PRFNum prd;
    PRFNum prd_stale;
    logic wen;
    Word imm;
    ALUOP alu_op;
    logic is_ds_i; // 是否为延迟槽指令
    logic is_special_i;  // 是否是特殊的指令，例如CP0等等，需要单独的发射
} ALU_Inst_Ops;

typedef struct packed {
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

typedef struct packed {
    ALU_Inst_Ops ops;
    Arbitration_Info rdys;
} ALU_Queue_Meta;

typedef struct packed { // TODO
    ALU_Inst_Ops ops;
    Arbitration_Info rdys;
} MDU_Queue_Meta;

typedef struct packed { // TODO
    ALU_Inst_Ops ops;
    Arbitration_Info rdys;
} LSU_Queue_Meta;

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

typedef struct packed {
    logic   [`UOP_WIDTH]    uOP;
    logic   [`ROB_ID_W]     id;
    logic   [31:0]          pc;
    logic                   isDS;
    logic                   isPrev;
    logic   [4:0]           cp0Num;
    logic   [31:0]          cp0Data;
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

    modport dispatch(output uOP0, uOP1, valid, input ready, empty);
    modport rob(input uOP0, uOP1, valid, output ready, empty);

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

    task automatic sendFinish(logic [`ROB_ID_W] idIn, ref logic clk);
        id          = idIn;
        setFinish   = `TRUE;
        @(posedge clk) #1 begin
            setFinish   = `FALSE;
        end
    endtask //automatic

    modport fu(output setFinish, id);
    modport rob(input setFinish, id);
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

`define DEBUG

`endif