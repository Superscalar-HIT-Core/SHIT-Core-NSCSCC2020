`timescale 1ns / 1ps
`include "../../sources_1/new/defines/defines.svh"
module backend_test_driver(

    );
reg clk,rst;

Regs_Decode  regs_decode();
Decode_Regs  decode_regs();

decode dec0(.*);



register_rename u_register_rename(
	.clk          (clk          ),
    .rst          (rst          ),
    .recover      (recover      ),
    // From instruction
    .inst_0_valid (inst_0_valid ),
    .inst_1_valid (inst_1_valid ),
    .rename_req_0   (rename_req_0   ),
    .rename_req_1   (rename_req_1   ),
    .rename_resp_0  (rename_resp_0  ),
    .rename_resp_1  (rename_resp_1  ),
    .allocatable  (allocatable  ),

    .commit_req_0  (commit_req_0  ),
    .commit_req_1  (commit_req_1  ),
    .commit_valid_0 (commit_valid_0),
    .commit_valid_1 (commit_valid_1)
);

integer fp;
integer count;
initial begin
    #0 fp = $fopen("../../../../source/instr.hex","r");
    regs_decode.inst.valid = 1;
    #0 clk = 0;rst = 1;
    #22 rst = 0;
    #20 regs_decode.inst = 0;     regs_decode.inst.valid = 1;
end

// Insturction Generator
always @(posedge clk)   begin
    if(!rst)  begin
        count <= $fscanf(fp,"%h" ,regs_decode.inst.inst);
        regs_decode.inst.pc <= regs_decode.inst.pc+4;
        #2
        if (decode_regs.uOP0.op1re)     begin
            $display("OP: %s %d, %d, %d", 
                dec0.decode_regs.uOP0.uOP.name,
                dec0.decode_regs.uOP0.dstLAddr,
                dec0.decode_regs.uOP0.op0LAddr,
                dec0.decode_regs.uOP0.op1LAddr
        );
        end else begin
            $display("OP: %s %d, %d, IMM %d", 
                dec0.decode_regs.uOP0.uOP.name,
                dec0.decode_regs.uOP0.dstLAddr,
                dec0.decode_regs.uOP0.op0LAddr,
                dec0.decode_regs.uOP0.imm
        );
        end
    end
end



always begin
    #10 clk = ~clk;
end

endmodule
