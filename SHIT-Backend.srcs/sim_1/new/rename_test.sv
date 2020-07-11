`timescale 1ns / 1ps
`include "../../sources_1/new/defines/defines.svh"
module rename_test(

    );
reg inst_0_valid=0, inst_1_valid=0;
rename_req rename_req_0=0, rename_req_1=0;
commit_info commit_req_0=0, commit_req_1=0;
reg clk = 0, rst = 1, commit_valid_0 = 0, commit_valid_1 = 1;
reg recover = 0;
wire rename_resp rename_resp_0, rename_resp_1;
wire allocatable;

task automatic request_rename(
    ref inst_valid_0, 
    ref rename_req rename_req_0,
    ref inst_valid_1, 
    ref rename_req rename_req_1,
    input req0, req1,
    input ARFNum rs0_0, rs1_0, rd_0,
    logic wen_0,
    input ARFNum rs0_1, rs1_1, rd_1,
    logic wen_1
);
    inst_valid_0 = req0;
    rename_req_0.ars1 = rs0_0;
    rename_req_0.ars2 = rs1_0;
    rename_req_0.ard  = rd_0;
    rename_req_0.wen = wen_0;
    inst_valid_1 = 1;
    rename_req_1.ars1 = rs0_1;
    rename_req_1.ars2 = rs1_1;
    rename_req_1.ard  = rd_1;
    rename_req_1.wen = wen_1;
endtask

task automatic request_commit(
    ref inst_valid_0, 
    ref rename_req rename_req_0,
    ref inst_valid_1, 
    ref rename_req rename_req_1,
    input req0, req1,
    input ARFNum rs0_0, rs1_0, rd_0,
    logic wen_0,
    input ARFNum rs0_1, rs1_1, rd_1,
    logic wen_1
);
    inst_valid_0 = req0;
    rename_req_0.ars1 = rs0_0;
    rename_req_0.ars2 = rs1_0;
    rename_req_0.ard  = rd_0;
    rename_req_0.wen = wen_0;
    inst_valid_1 = 1;
    rename_req_1.ars1 = rs0_1;
    rename_req_1.ars2 = rs1_1;
    rename_req_1.ard  = rd_1;
    rename_req_1.wen = wen_1;
endtask

register_rename u_register_rename(
	.clk          (clk          ),
    .rst          (rst          ),
    .recover      (recover      ),
    .inst_0_valid (inst_0_valid ),
    .inst_1_valid (inst_1_valid ),
    .rename_req_0   (rename_req_0   ),
    .rename_req_1   (rename_req_1   ),
    .commit_req_0  (commit_req_0  ),
    .commit_req_1  (commit_req_1  ),
    .rename_resp_0  (rename_resp_0  ),
    .rename_resp_1  (rename_resp_1  ),
    .allocatable  (allocatable  ),
    .commit_valid_0 (commit_valid_0),
    .commit_valid_1 (commit_valid_1)
);

initial begin
    #32 rst = 0;
    #20 request_rename(
    .inst_valid_0(inst_0_valid), .rename_req_0(rename_req_0),.inst_valid_1(inst_1_valid), .rename_req_1(rename_req_1),
    .req0   (1),            .req1  (1),
    .rs0_0  (1),            .rs0_1 (2),
    .rs1_0  (2),            .rs1_1 (3),
    .rd_0   (3),            .rd_1  (4),
    .wen_0  (1),            .wen_1 (1)
);  
    #20 request_rename(
    .inst_valid_0(inst_0_valid), .rename_req_0(rename_req_0),.inst_valid_1(inst_1_valid), .rename_req_1(rename_req_1),
    .req0   (1),            .req1  (1),
    .rs0_0  (1),            .rs0_1 (2),
    .rs1_0  (2),            .rs1_1 (3),
    .rd_0   (3),            .rd_1  (4),
    .wen_0  (1),            .wen_1 (1)
);
    #20 request_rename(
    .inst_valid_0(inst_0_valid), .rename_req_0(rename_req_0),.inst_valid_1(inst_1_valid), .rename_req_1(rename_req_1),
    .req0   (1),            .req1  (1),
    .rs0_0  (4),            .rs0_1 (7),
    .rs1_0  (5),            .rs1_1 (8),
    .rd_0   (6),            .rd_1  (9),
    .wen_0  (0),            .wen_1 (1)
);
    #20 request_rename(
    .inst_valid_0(inst_0_valid), .rename_req_0(rename_req_0),.inst_valid_1(inst_1_valid), .rename_req_1(rename_req_1),
    .req0   (1),            .req1  (1),
    .rs0_0  (10),            .rs0_1 (12),
    .rs1_0  (11),            .rs1_1 (12),
    .rd_0   (12),            .rd_1  (13),
    .wen_0  (1),            .wen_1 (0)
);
    #20 request_rename(
    .inst_valid_0(inst_0_valid), .rename_req_0(rename_req_0),.inst_valid_1(inst_1_valid), .rename_req_1(rename_req_1),
    .req0   (1),            .req1  (1),
    .rs0_0  (13),            .rs0_1 (14),
    .rs1_0  (13),            .rs1_1 (15),
    .rd_0   (13),            .rd_1  (13),
    .wen_0  (1),            .wen_1 (1)
);
    #20     
    inst_0_valid = 0;
    rename_req_0.ars1 = 0;
    rename_req_0.ars2 = 0;
    rename_req_0.ard  = 0;
    rename_req_0.wen = 0;
    inst_1_valid = 0;
    rename_req_1.ars1 = 0;
    rename_req_1.ars2 = 0;
    rename_req_1.ard  = 0;
    rename_req_1.wen = 0;

$stop;
end

always begin
    #10 clk = ~clk;
end

endmodule
