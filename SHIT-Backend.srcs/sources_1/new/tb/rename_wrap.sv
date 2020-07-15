`timescale 1ns / 1ps
`include "../defines/defines.svh"
module rename_wrap(
    input clk, 
    input rst,
    input recover_i, 
    input inst_0_valid_i, inst_1_valid_i,               
    input commit_valid_0_i, commit_valid_1_i,
    input rename_req rename_req_0_i, rename_req_1_i,
    input commit_info commit_req_0_i, commit_req_1_i,
    output rename_resp rename_resp_0_o, rename_resp_1_o,
    output reg allocatable_o
    );
reg inst_0_valid, inst_1_valid, commit_valid_0, commit_valid_1;
rename_req rename_req_0, rename_req_1;
commit_info commit_req_0, commit_req_1;
rename_resp rename_resp_0, rename_resp_1;
wire allocatable;

always_ff @(posedge clk)   begin
    if(rst) begin
        inst_0_valid <= 0;
        inst_1_valid <= 0;
        commit_valid_0 <= 0;
        commit_valid_1 <= 0;
        rename_req_0 <= 0;
        rename_req_1 <= 0;
        commit_req_0 <= 0;
        commit_req_1 <= 0;
        allocatable_o <= 0;
    end else begin
        inst_0_valid      <= inst_0_valid_i;
        inst_1_valid      <= inst_1_valid_i;
        commit_valid_0    <= commit_valid_0_i;
        commit_valid_1    <= commit_valid_1_i;
        rename_req_0      <= rename_req_0_i;
        rename_req_1      <= rename_req_1_i;
        commit_req_0      <= commit_req_0_i;
        commit_req_1      <= commit_req_1_i;
        allocatable_o     <= allocatable;
    end
end

register_rename ut0(.*);


endmodule
