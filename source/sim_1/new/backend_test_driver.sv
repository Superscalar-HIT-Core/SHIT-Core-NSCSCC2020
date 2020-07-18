`timescale 1ns / 1ps
`include "../../sources_1/new/defines/defines.svh"
module backend_test_driver(

    );
reg clk,rst;
reg recover;
Regs_Decode  regs_decode0();
Regs_Decode  regs_decode1();
Decode_Regs  decode_regs0();
Decode_Regs  decode_regs1();
decode dec0(.regs_decode(regs_decode0), .decode_regs(decode_regs0));
decode dec1(.regs_decode(regs_decode1), .decode_regs(decode_regs1));
Ctrl         ctrl_decode_rename_regs();
Regs_Rename regs_rename();
decode_rename_regs dec_rename(
    .clk(clk),
    .rst(rst),
    .ctrl_decode_rename_regs(ctrl_decode_rename_regs),
    .decode0_regs(decode_regs0),
    .decode1_regs(decode_regs1),
    .regs_rename(regs_rename)
);

UOPBundle rename_dispatch_0, rename_dispatch_1;
wire allocatable_rename;
register_rename rr(
    .clk(clk), 
    .rst(rst),
    .recover(recover), 
    .inst0_ops_in(decode_regs0.uOP0), 
    .inst1_ops_in(decode_regs1.uOP1),
    .inst0_ops_out(rename_dispatch_0), 
    .inst1_ops_out(rename_dispatch_1),

    .commit_valid_0(0), 
    .commit_valid_1(0),
    .commit_req_0(0), 
    .commit_req_1(0),
    .allocatable(allocatable_rename)
    );

integer fp;
integer count;
initial begin
    #0 fp = $fopen("../../../../source/instr.hex","r");
    regs_decode0.inst.valid = 0;
    regs_decode1.inst.valid = 0;
    ctrl_decode_rename_regs.pause = 0;
    ctrl_decode_rename_regs.flush = 0;
    regs_decode0.inst = 0; 
    regs_decode1.inst = 0; 
    regs_decode1.inst.pc = 4;     
    recover = 0;
    #0 clk = 0;rst = 1;
    #22 rst = 0;
end

// Insturction Generator
always @(posedge clk)   begin
    if(!rst && !ctrl_decode_rename_regs.pauseReq)  begin
        regs_decode0.inst.valid <= 1;
        regs_decode1.inst.valid <= 1;
        count <= $fscanf(fp,"%h" ,regs_decode0.inst.inst);
        regs_decode0.inst.pc <= regs_decode0.inst.pc+8;
        count <= $fscanf(fp,"%h" ,regs_decode1.inst.inst);
        regs_decode1.inst.pc <= regs_decode1.inst.pc+8;
        #2
        if (decode_regs0.uOP0.op1re)     begin
            $display("Decode0: %4s %2d,%2d,%2d @ PC %h", 
                decode_regs0.uOP0.uOP.name,
                decode_regs0.uOP0.dstLAddr,
                decode_regs0.uOP0.op0LAddr,
                decode_regs0.uOP0.op1LAddr,
                decode_regs0.uOP0.pc
        );
        end else begin
            $display("Decode0: %4s %2d,%2d,(IMM)%2d @ PC %h", 
                decode_regs0.uOP0.uOP.name,
                decode_regs0.uOP0.dstLAddr,
                decode_regs0.uOP0.op0LAddr,
                decode_regs0.uOP0.imm,
                decode_regs0.uOP0.pc
        );
        end
        if (decode_regs1.uOP0.op1re)     begin
            $display("Decode1: %4s %2d,%2d,%2d @ PC %h", 
                decode_regs1.uOP0.uOP.name,
                decode_regs1.uOP0.dstLAddr,
                decode_regs1.uOP0.op0LAddr,
                decode_regs1.uOP0.op1LAddr,
                decode_regs1.uOP0.pc
        );
        end else begin
            $display("Decode1: %4s %2d,%2d,(IMM)%2d @ PC %h", 
                decode_regs1.uOP0.uOP.name,
                decode_regs1.uOP0.dstLAddr,
                decode_regs1.uOP0.op0LAddr,
                decode_regs1.uOP0.imm,
                decode_regs1.uOP0.pc
        );
        end
    end else begin
        regs_decode0.inst.valid <= 1;
        regs_decode1.inst.valid <= 1;
    end
end



always begin
    #10 clk = ~clk;
end

endmodule
