`ifndef DEFINES
`define DEFINES
`define REG_WIDTH 32
`define PRF_NUM_WIDTH 6
`define ARF_NUM_WIDTH 5
`define PRF_NUM 64
`define IQ_ALU_LENGTH 8
`define ALU_OP_WIDTH 4

`define CMPQ_SEL_DIN1    2'b00
`define CMPQ_SEL_DIN2    2'b01
`define CMPQ_SEL_UP1    2'b10
`define CMPQ_SEL_UP2    2'b11

typedef logic [5:0] PRFNum; // 物理寄存器编号
typedef logic [4:0] ARFNum; // 逻辑寄存器编号
typedef logic [63:0] PRF_Vec;

typedef struct packed {
    PRFNum prf_rs1;
    PRFNum prf_rs2;
    PRFNum prf_rd_stale;
} rename_table_output;          // 重命名表的三个输出

typedef struct packed {
    ARFNum ars1, ars2, ard;      // 指令的两个源寄存器，逻辑寄存器
    logic wen;              // 指令写寄存器
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
    logic commit_req;         // the instruction actually write the register
} commit_info;

typedef struct packed {
    PRFNum prf_rs1;
    PRFNum prf_rs2;
    PRFNum prf_rd_stale;
    PRFNum new_prd;
} rename_resp;

`define DEBUG

`endif