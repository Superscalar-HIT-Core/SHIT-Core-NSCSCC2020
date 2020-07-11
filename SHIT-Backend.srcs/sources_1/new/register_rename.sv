`timescale 1ns / 1ps
`include "defines/defines.svh"


module register_rename(
    input clk, 
    input rst,
    input recover, 
    input inst_0_valid, inst_1_valid,               // 指令是否有效（指Fetch Buffer出来的层面，译码之后）
    input rename_req rename_req_0, rename_req_1,
    input commit_info commit_req_0, commit_req_1,
    output rename_resp rename_resp_0, rename_resp_1,
    output allocatable
    );
wire PRFNum free_prf_0, free_prf_1;

free_list u_free_list(
	.clk         (clk         ),
    .rst         (rst         ),
    .recover     (recover     ),
    .inst_0_req  (rename_req_0.wen && inst_0_valid ),
    .inst_1_req  (rename_req_1.wen && inst_1_valid  ),
    .inst_0_prf      (free_prf_0      ),
    .inst_1_prf      (free_prf_1      ),
    .commit_info_0 (commit_req_0 ),
    .commit_info_1 (commit_req_1 ),
    .allocatable (allocatable )
);
rename_table_input rnamet_input_inst0, rnamet_input_inst1;

assign rnamet_input_inst0.req = rename_req_0;
assign rnamet_input_inst0.prf_rd_new = free_prf_0;
assign rnamet_input_inst1.req = rename_req_1;
assign rnamet_input_inst1.prf_rd_new = free_prf_1;

rename_table_output rnamet_output_inst0, rnamet_output_inst1;

map_table u_map_table(
	.clk                 (clk                 ),
    .rst                 (rst                 ),
    .recover             (recover             ),
    .inst_0_valid        (inst_0_valid  && allocatable ),
    .inst_1_valid        (inst_1_valid  && allocatable ),
    .rname_input_inst0  (rnamet_input_inst0  ),
    .rname_input_inst1  (rnamet_input_inst1  ),
    .rname_output_inst0 (rnamet_output_inst0 ),
    .rname_output_inst1 (rnamet_output_inst1 ),
    .commit_info_0         (commit_req_0         ),
    .commit_info_1         (commit_req_1         )
);

assign rename_resp_0.prf_rs1 = rnamet_output_inst0.prf_rs1;
assign rename_resp_0.prf_rs2 = rnamet_output_inst0.prf_rs2;
assign rename_resp_0.prf_rd_stale = rnamet_output_inst0.prf_rd_stale;
assign rename_resp_0.new_prd = free_prf_0;

assign rename_resp_1.prf_rs1 = rnamet_output_inst1.prf_rs1;
assign rename_resp_1.prf_rs2 = rnamet_output_inst1.prf_rs2;
assign rename_resp_1.prf_rd_stale = rnamet_output_inst1.prf_rd_stale;
assign rename_resp_1.new_prd = free_prf_1;

`ifdef DEBUG
always @(posedge clk) begin
    #5
    if(inst_0_valid)    begin
        if(rename_req_0.wen)    begin
        $strobe("Inst_0: RS1 %d -> %d ; RS2 %d -> %d ; RD %d -> %d (stale %d)", 
            rename_req_0.ars1,  rename_resp_0.prf_rs1,
            rename_req_0.ars2,  rename_resp_0.prf_rs2,
            rename_req_0.ard,  rename_resp_0.new_prd,
            rename_resp_0.prf_rd_stale
            );
        end else begin
        $strobe("Inst_0: RS1 %d -> %d ; RS2 %d -> %d ; RD %d -> %d (stale %d), Do not rename", 
            rename_req_0.ars1,  rename_resp_0.prf_rs1,
            rename_req_0.ars2,  rename_resp_0.prf_rs2,
            rename_req_0.ard,  rename_resp_0.new_prd,
            rename_resp_0.prf_rd_stale
            );
        end
    end
    if(inst_1_valid)    begin
        if(rename_req_1.wen)    begin
        $strobe("Inst_1: RS1 %d -> %d ; RS2 %d -> %d ; RD %d -> %d (stale %d)", 
        rename_req_1.ars1,  rename_resp_1.prf_rs1,
        rename_req_1.ars2,  rename_resp_1.prf_rs2,
        rename_req_1.ard,  rename_resp_1.new_prd,
        rename_resp_1.prf_rd_stale
        );
    end else begin
        $strobe("Inst_1: RS1 %d -> %d ; RS2 %d -> %d ; RD %d -> %d (stale %d), Do not rename", 
        rename_req_1.ars1,  rename_resp_1.prf_rs1,
        rename_req_1.ars2,  rename_resp_1.prf_rs2,
        rename_req_1.ard,  rename_resp_1.new_prd,
        rename_resp_1.prf_rd_stale
        );
        end
    end
end
`endif

endmodule
