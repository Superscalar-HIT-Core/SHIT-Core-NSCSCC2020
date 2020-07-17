`timescale 1ns / 1ps
`include "../../sources_1/new/defines/defines.svh"
module backend_test_driver(

    );
reg clk,rst;

Regs_Decode  regs_decode0(),regs_decode1();
Decode_Regs  decode_regs0(),decode_regs1();

decode dec0(.*);


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
