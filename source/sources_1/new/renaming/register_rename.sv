`timescale 1ns / 1ps
`include "../defines/defines.svh"


module register_rename(
    input clk, 
    input rst,
    input recover, 
    input UOPBundle inst0_ops_in, inst1_ops_in,
    output UOPBundle inst0_ops_out, inst1_ops_out,
    input commit_valid_0, commit_valid_1,
    input commit_info commit_req_0, commit_req_1,
    output allocatable
    );
wire PRFNum free_prf_0, free_prf_1;

free_list u_free_list(
	.clk         (clk         ),
    .rst         (rst         ),
    .recover     (recover     ),
    .inst_0_req  (inst0_ops_in.dstwe && inst0_ops_in.valid ),
    .inst_1_req  (inst1_ops_in.dstwe && inst1_ops_in.valid  ),
    .inst_0_prf      (free_prf_0      ),
    .inst_1_prf      (free_prf_1      ),
    .commit_valid_0     (commit_valid_0),
    .commit_valid_1     (commit_valid_1),
    .commit_info_0 (commit_req_0 ),
    .commit_info_1 (commit_req_1 ),
    .allocatable (allocatable )
);
rename_table_input rnamet_input_inst0, rnamet_input_inst1;

rename_req rename_req0, rename_req1;
assign rename_req0.ars1 = inst0_ops_in.op0LAddr;
assign rename_req0.ars2 = inst0_ops_in.op1LAddr;
assign rename_req0.ard = inst0_ops_in.dstLAddr;
assign rename_req0.wen = inst0_ops_in.dstwe;

assign rename_req1.ars1 = inst1_ops_in.op0LAddr;
assign rename_req1.ars2 = inst1_ops_in.op1LAddr;
assign rename_req1.ard = inst1_ops_in.dstLAddr;
assign rename_req1.wen = inst1_ops_in.dstwe;

assign rnamet_input_inst0.req = rename_req0;
assign rnamet_input_inst0.prf_rd_new = free_prf_0;
assign rnamet_input_inst1.req = rename_req1;
assign rnamet_input_inst1.prf_rd_new = free_prf_1;

rename_table_output rnamet_output_inst0, rnamet_output_inst1;

map_table u_map_table(
	.clk                 (clk                 ),
    .rst                 (rst                 ),
    .recover             (recover             ),
    .inst_0_valid        (inst0_ops_in.valid  && allocatable ),
    .inst_1_valid        (inst1_ops_in.valid  && allocatable ),
    .rname_input_inst0  (rnamet_input_inst0  ),
    .rname_input_inst1  (rnamet_input_inst1  ),
    .rname_output_inst0 (rnamet_output_inst0 ),
    .rname_output_inst1 (rnamet_output_inst1 ),
    .commit_valid_0     (commit_valid_0),
    .commit_valid_1     (commit_valid_1),
    .commit_info_0         (commit_req_0         ),
    .commit_info_1         (commit_req_1         )
);




always_comb begin
    inst0_ops_out = inst0_ops_in;
    inst0_ops_out.op0PAddr = rnamet_output_inst0.prf_rs1;
    inst0_ops_out.op1PAddr = rnamet_output_inst0.prf_rs2;
    inst0_ops_out.dstPAddr = free_prf_0;
    inst0_ops_out.dstPStale = rnamet_output_inst0.prf_rd_stale;
end


always_comb begin
    inst1_ops_out = inst1_ops_in;
    inst1_ops_out.op0PAddr = rnamet_output_inst1.prf_rs1;
    inst1_ops_out.op1PAddr = rnamet_output_inst1.prf_rs2;
    inst1_ops_out.dstPAddr = free_prf_1;
    inst1_ops_out.dstPStale = rnamet_output_inst1.prf_rd_stale;
end

`ifdef DEBUG
always @(posedge clk) begin
    #5
    if(inst0_ops_in.valid)    begin
        if(rename_req0.wen)    begin
        $strobe("Inst_0: RS1 %d -> %d ; RS2 %d -> %d ; RD %d -> %d (stale %d)", 
            rename_req0.ars1,  inst0_ops_out.op0PAddr,
            rename_req0.ars2,  inst0_ops_out.op1PAddr,
            rename_req0.ard,  inst0_ops_out.dstPAddr,
            inst0_ops_out.dstPStale
            );
        end else begin
        $strobe("Inst_0: RS1 %d -> %d ; RS2 %d -> %d ; RD %d -> %d (stale %d), Do not rename", 
            rename_req0.ars1,  inst0_ops_out.op0PAddr,
            rename_req0.ars2,  inst0_ops_out.op1PAddr,
            rename_req0.ard,  inst0_ops_out.dstPAddr,
            inst0_ops_out.dstPStale
            );
        end
    end
    if(inst1_ops_in.valid)    begin
        if(rename_req1.wen)    begin
        $strobe("Inst_1: RS1 %d -> %d ; RS2 %d -> %d ; RD %d -> %d (stale %d)", 
            rename_req1.ars1,  inst1_ops_out.op0PAddr,
            rename_req1.ars2,  inst1_ops_out.op1PAddr,
            rename_req1.ard,  inst1_ops_out.dstPAddr,
            inst1_ops_out.dstPStale
            );
    end else begin
        $strobe("Inst_1: RS1 %d -> %d ; RS2 %d -> %d ; RD %d -> %d (stale %d), Do not rename", 
            rename_req1.ars1,  inst1_ops_out.op0PAddr,
            rename_req1.ars2,  inst1_ops_out.op1PAddr,
            rename_req1.ard,  inst1_ops_out.dstPAddr,
            inst1_ops_out.dstPStale
            );
        end
    end
end
`endif

endmodule
