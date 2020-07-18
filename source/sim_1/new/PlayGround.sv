`timescale 1ns / 1ps
`include "../../sources_1/new/defines/defines.svh"
module PlayGround(

    );
reg clk,rst;
reg recover;

IFU_InstBuffer      ifu_instBuffer();
InstBuffer_Backend  instBuffer_backend();
Regs_Decode         regs_decode0();
Regs_Decode         regs_decode1();
Decode_Regs         decode_regs0();
Decode_Regs         decode_regs1();
Regs_Rename         regs_rename();

Ctrl     ctrl_instBuffer_decode_regs();
Ctrl     ctrl_decode_rename_regs();
Ctrl     ctrl_rob();
Ctrl     ctrl_iq_alu0();
Ctrl     ctrl_iq_alu1();
Ctrl     ctrl_iq_lsu();
Ctrl     ctrl_iq_mdu();
Ctrl     ctrl_commit();
Ctrl     ctrl_instBuffer();

CtrlUnitBackend ctrl(.*);

InstBuffer  instBuffer(.*);
InstBuffer_decode_regs  instBuffer_decode_regs(.*);
decode dec0(.regs_decode(regs_decode0), .decode_regs(decode_regs0));
decode dec1(.regs_decode(regs_decode1), .decode_regs(decode_regs1));
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
    .inst0_ops_in(regs_rename.uOP0), 
    .inst1_ops_in(regs_rename.uOP1),
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
    ifu_instBuffer.inst0.isJ    = `FALSE;
    ifu_instBuffer.inst0.isBr   = `FALSE;
    ifu_instBuffer.inst0.isDs   = `FALSE;
    ifu_instBuffer.inst1.isJ    = `FALSE;
    ifu_instBuffer.inst1.isBr   = `FALSE;
    ifu_instBuffer.inst1.isDs   = `FALSE;
    ctrl_decode_rename_regs.pause = 0;
    ctrl_decode_rename_regs.flush = 0;
    
    ctrl_rob.pauseReq = `FALSE;
    ctrl_iq_alu0.pauseReq = `FALSE;
    ctrl_iq_alu1.pauseReq = `FALSE;
    ctrl_iq_lsu.pauseReq = `FALSE;
    ctrl_iq_mdu.pauseReq = `FALSE;
    ctrl_commit.pauseReq = `FALSE;
    
    ctrl_rob.flushReq = `FALSE;
    ctrl_iq_alu0.flushReq = `FALSE;
    ctrl_iq_alu1.flushReq = `FALSE;
    ctrl_iq_lsu.flushReq = `FALSE;
    ctrl_iq_mdu.flushReq = `FALSE;
    ctrl_commit.flushReq = `FALSE;

    ifu_instBuffer.inst0.inst = 0; 
    ifu_instBuffer.inst1.inst = 0; 
    ifu_instBuffer.inst0.pc = 0;
    ifu_instBuffer.inst1.pc = 4;
    recover = 0;
    #0 clk = 0;rst = 1;
    #22 rst = 0;
end

// Insturction Generator
always @(posedge clk)   begin
    if(!rst && !ctrl_decode_rename_regs.pauseReq)  begin
        if(!$feof(fp))   begin
            ifu_instBuffer.inst0.valid <= 1;
            ifu_instBuffer.inst1.valid <= 1;
        end else begin
            ifu_instBuffer.inst0.valid <= 0;
            ifu_instBuffer.inst1.valid <= 0;
            $finish;
        end
        count <= $fscanf(fp,"%h" ,ifu_instBuffer.inst0.inst);
        ifu_instBuffer.inst0.pc <= ifu_instBuffer.inst0.pc+8;
        count <= $fscanf(fp,"%h" ,ifu_instBuffer.inst1.inst);
        ifu_instBuffer.inst1.pc <= ifu_instBuffer.inst1.pc+8;
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
        ifu_instBuffer.inst0.valid <= 1;
        ifu_instBuffer.inst1.valid <= 1;
    end
end



always begin
    #10 clk = ~clk;
end

endmodule
