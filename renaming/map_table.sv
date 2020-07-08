`include "defines.svh"

typedef struct packed {
    logic [`PRF_NUM_WIDTH-1:0] prf_rs1;
    logic [`PRF_NUM_WIDTH-1:0] prf_rs2;
    logic [`PRF_NUM_WIDTH-1:0] prf_rd_stale;
} rename_output;

typedef struct packed {
    // From the instruction
    logic [`ARF_NUM_WIDTH-1:0] arf_rs1;
    logic [`ARF_NUM_WIDTH-1:0] arf_rs2;
    logic [`ARF_NUM_WIDTH-1:0] arf_rd;
    logic rename_en;
    // From the free list
    logic [`PRF_NUM_WIDTH-1:0] prf_rd_new;
} rename_input;

typedef struct packed {
    // From the instruction
    logic [`ARF_NUM_WIDTH-1:0] commited_arf;
    logic commit_valid; // the instruction actually write the register
} commit_info;

module map_table(
    input clk,
    input rst,
    // 需要恢复状态，在最后两条指令提交后延迟给出（需要允许两个指令写入）
    input recover,
    // 指令是否有效（并不包括指令是否写寄存器，只是单纯的从指令队列输入）
    input inst_0_valid,
    input inst_1_valid,
    // 结构体，包含rs1, rs2, rd, 并指明是否需要写寄存器，以判定是否需要写重命名的表
    input rename_input rname_input_inst0,
    input rename_input rname_input_inst1,
    // 输出prs1, prs2, prd, 并做好旁路的处理
    output rename_output rname_output_inst0,
    output rename_output rname_output_inst1,
    // commit 阶段的输入，表示状态的确认
    input commit_0_valid,
    input commit_1_valid,
    input commit_info commit_info_0,
    input commit_info commit_info_1
    // TODO: 处理HILO寄存器，重命名是统一的重命名，但是映射表中进行单独的记录
);


// Rename Map Table
reg [31:0] rename_map_table_bank0 [`PRF_NUM_WIDTH-1:0];
reg [31:0] rename_map_table_bank1 [`PRF_NUM_WIDTH-1:0];

reg [31:0] committed_rename_map_table_bank0 [`PRF_NUM_WIDTH-1:0];
reg [31:0] committed_rename_map_table_bank1 [`PRF_NUM_WIDTH-1:0];

wire wr_rename_inst0 = (rname_input_inst0.rename_en && inst_0_valid);
wire wr_rename_inst1 = (rname_input_inst1.rename_en && inst_1_valid);

wire dst_eq = (rname_input_inst1.arf_rd == rname_input_inst0.arf_rd);

// Rename read port, note the bypass logic
// For instruction1, needn't consider the bypass
// TODO: do we need to consider add a1, a1, a1?
// a1 will be renamed
assign rname_output_inst0.prf_rs1 = rename_map_table_bank0[rname_input_inst0.arf_rs1];
assign rname_output_inst0.prf_rs2 = rename_map_table_bank0[rname_input_inst0.arf_rs2];

// For instruction2, need to consider the bypass logic when inst0.rd == inst1.rs 
assign rname_output_inst1.prf_rs1 = (wr_rename_inst0 && rname_input_inst0.arf_rd == rname_input_inst1.arf_rs1) ? rname_input_inst0.prf_rd_new :
                                        rename_map_table_bank1[rname_input_inst1.arf_rs1];
assign rname_output_inst1.prf_rs2 = (wr_rename_inst0 && rname_input_inst0.arf_rd == rname_input_inst1.arf_rs2) ? rname_input_inst0.prf_rd_new :
                                        rename_map_table_bank1[rname_input_inst1.arf_rs2];

assign rname_output_inst0.prf_rd_stale = rename_map_table_bank0[rname_input_inst0.arf_rd];
// Attention the bypass logic
assign rname_output_inst1.prf_rd_stale = (wr_rename_inst0 && (wr_rename_inst1 && dst_eq)) ? rname_input_inst0.prf_rd_new :
                                            rename_map_table_bank1[rname_input_inst1.arf_rd];


integer i;
always @(posedge clk)   begin
    if(rst) begin
        // reset the rename map
        for(i=0;i<32;i++)   begin
            rename_map_table_bank0[i] <= 6'b0;
            rename_map_table_bank1[i] <= 6'b0;
        end
    end else if(recover)    begin
        for(i=0;i<32;i++)   begin
            rename_map_table_bank0[i] <= committed_rename_map_table_bank0[i];
            rename_map_table_bank1[i] <= committed_rename_map_table_bank1[i];
        end
    end else begin
       // Write the 2 banks of rename map (SPECULATIVELY)
       // TODO: 考虑后一条指令和前一条同时写同一个寄存器
       // Inst 0 Rename Update
       if( wr_rename_inst0 && !(wr_rename_inst1 && dst_eq) )   begin
            rename_map_table_bank0[rname_input_inst0.arf_rd] <= rname_input_inst0.prf_rd_new;
            rename_map_table_bank1[rname_input_inst0.arf_rd] <= rname_input_inst0.prf_rd_new;
       end else if ( wr_rename_inst0 && (wr_rename_inst1 && dst_eq) ) begin
            rename_map_table_bank0[rname_input_inst0.arf_rd] <= rname_input_inst1.prf_rd_new;
            rename_map_table_bank1[rname_input_inst0.arf_rd] <= rname_input_inst1.prf_rd_new;
       end
       // Inst 1 Rename Update
       if( wr_rename_inst1 ) begin
            rename_map_table_bank0[rname_input_inst1.arf_rd] <= rname_input_inst1.prf_rd_new;
            rename_map_table_bank1[rname_input_inst1.arf_rd] <= rname_input_inst1.prf_rd_new;
       end
   end
end


always @(posedge clk)   begin
    if(rst) begin
        // reset the committed map
        for(i=0;i<32;i++)   begin
            committed_rename_map_table_bank0[i] <= 6'b0;
            committed_rename_map_table_bank1[i] <= 6'b0;
        end
    end else begin
        if(commit_0_valid && commit_info_0.commit_valid)    begin
            // Copy the commited state from the bank 
            committed_rename_map_table_bank0[commit_info_0.commited_arf] <= rename_map_table_bank0[commit_info_0.commited_arf];
            committed_rename_map_table_bank1[commit_info_0.commited_arf] <= rename_map_table_bank1[commit_info_0.commited_arf];
        end 
        if(commit_1_valid && commit_info_1.commit_valid)    begin
            // Copy the commited state from the bank 
            committed_rename_map_table_bank0[commit_info_1.commited_arf] <= rename_map_table_bank0[commit_info_1.commited_arf];
            committed_rename_map_table_bank1[commit_info_1.commited_arf] <= rename_map_table_bank1[commit_info_1.commited_arf];
        end
    end
end

endmodule