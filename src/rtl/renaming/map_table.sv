`include "../defines/defines.svh"


// 0号寄存器永远不分配，永远被映射到0，所以不用进行特殊的处理！
module map_table(
    input clk,
    input rst,
    // 需要恢复状态，在最后两条指令提交后延迟给出（需要允许两个指令写入）
    input recover,
    // 指令是否有效（并不包括指令是否写寄存器，只是单纯的从指令队列输入）
    input inst_0_valid,
    input inst_1_valid,
    input commit_valid_0,
    input commit_valid_1,
    // 结构体，包含rs1, rs2, rd, 并指明是否需要写寄存器，以判定是否需要写重命名的表
    input rename_table_input  rname_input_inst0,
    input rename_table_input  rname_input_inst1,
    // 输出prs1, prs2, prd, 并做好旁路的处理
    output rename_table_output rname_output_inst0,
    output rename_table_output rname_output_inst1,
    // commit 阶段的输入，表示状态的确认
    input commit_info commit_info_0,
    input commit_info commit_info_1
);


// Rename Map Table，两个Bank
reg [`PRF_NUM_WIDTH-1:0] rename_map_table_bank0 [33:0];
reg [`PRF_NUM_WIDTH-1:0] rename_map_table_bank1 [33:0];

// 提交后的Map Table，也是两个Bank
reg [`PRF_NUM_WIDTH-1:0] committed_rename_map_table_bank0 [33:0] ;
reg [`PRF_NUM_WIDTH-1:0] committed_rename_map_table_bank1 [33:0] ;

wire wr_rename_inst0 = (rname_input_inst0.req.wen && inst_0_valid);
wire wr_rename_inst1 = (rname_input_inst1.req.wen && inst_1_valid);

// 两个指令的目的寄存器相等
wire dst_eq = (rname_input_inst1.req.ard == rname_input_inst0.req.ard);

// Rename read port, note the bypass logic
// For instruction1, needn't consider the bypass
// Do we need to consider add a1, a1, a1?
// a1 will be renamed
assign rname_output_inst0.prf_rs1 = rename_map_table_bank0[rname_input_inst0.req.ars1];
assign rname_output_inst0.prf_rs2 = rename_map_table_bank0[rname_input_inst0.req.ars2];

// For instruction2, need to consider the bypass logic when inst0.rd == inst1.rs 
assign rname_output_inst1.prf_rs1 = (wr_rename_inst0 && rname_input_inst0.req.ard == rname_input_inst1.req.ars1) ? rname_input_inst0.prf_rd_new :
                                        rename_map_table_bank1[rname_input_inst1.req.ars1];
assign rname_output_inst1.prf_rs2 = (wr_rename_inst0 && rname_input_inst0.req.ard == rname_input_inst1.req.ars2) ? rname_input_inst0.prf_rd_new :
                                        rename_map_table_bank1[rname_input_inst1.req.ars2];

assign rname_output_inst0.prf_rd_stale = rename_map_table_bank0[rname_input_inst0.req.ard];
// Attention the bypass logic
assign rname_output_inst1.prf_rd_stale = (wr_rename_inst0 && (wr_rename_inst1 && dst_eq)) ? rname_input_inst0.prf_rd_new :
                                            rename_map_table_bank1[rname_input_inst1.req.ard];


integer i;
always @(posedge clk)   begin
    if(rst) begin
        // reset the rename map
        for(i=0;i<34;i++)   begin
            rename_map_table_bank0[i] <= 6'b0;
            rename_map_table_bank1[i] <= 6'b0;
        end
    end else if(recover)    begin
        for(i=0;i<34;i++)   begin
            rename_map_table_bank0[i] <= committed_rename_map_table_bank0[i];
            rename_map_table_bank1[i] <= committed_rename_map_table_bank1[i];
        end
    end else begin
       // Write the 2 banks of rename map (SPECULATIVELY)
       // TODO: 考虑后一条指令和前一条同时写同一个寄存器
       // Inst 0 Rename Update
        if( wr_rename_inst0 && !(wr_rename_inst1 && dst_eq) )   begin
            rename_map_table_bank0[rname_input_inst0.req.ard] <= rname_input_inst0.prf_rd_new;
            rename_map_table_bank1[rname_input_inst0.req.ard] <= rname_input_inst0.prf_rd_new;
        end else if ( wr_rename_inst0 && (wr_rename_inst1 && dst_eq) ) begin
            rename_map_table_bank0[rname_input_inst0.req.ard] <= rname_input_inst1.prf_rd_new;
            rename_map_table_bank1[rname_input_inst0.req.ard] <= rname_input_inst1.prf_rd_new;
        end
       // Inst 1 Rename Update
        if( wr_rename_inst1 ) begin
            rename_map_table_bank0[rname_input_inst1.req.ard] <= rname_input_inst1.prf_rd_new;
            rename_map_table_bank1[rname_input_inst1.req.ard] <= rname_input_inst1.prf_rd_new;
        end
    end
end

`ifdef DEBUG
always @(posedge clk)   begin
    #5
    for(i=0;i<32;i++)   begin
        $display(i, "----->", rename_map_table_bank0[i], "(S)",
                    committed_rename_map_table_bank0[i], "(C)", );
    end
    $display("Hi ----->", rename_map_table_bank0[32], "(S)",
                    committed_rename_map_table_bank0[32], "(C)", );
    $display("Lo ----->", rename_map_table_bank0[33], "(S)",
                    committed_rename_map_table_bank0[33], "(C)", );
end
`endif

always @(posedge clk)   begin
    if(rst) begin
        // reset the committed map
        for(i=0;i<34;i++)   begin
            committed_rename_map_table_bank0[i] <= 6'b0;
            committed_rename_map_table_bank1[i] <= 6'b0;
        end
    end else begin
        if(commit_info_0.wr_reg_commit && commit_valid_0)    begin
            // Copy the commited state from the bank 
            committed_rename_map_table_bank0[commit_info_0.committed_arf] <= commit_info_0.committed_prf;
            committed_rename_map_table_bank1[commit_info_0.committed_arf] <= commit_info_0.committed_prf;
        end 
        if(commit_info_1.wr_reg_commit && commit_valid_1)    begin
            // Copy the commited state from the bank 
            committed_rename_map_table_bank0[commit_info_1.committed_arf] <= commit_info_1.committed_prf;
            committed_rename_map_table_bank1[commit_info_1.committed_arf] <= commit_info_1.committed_prf;
        end
    end
end

endmodule