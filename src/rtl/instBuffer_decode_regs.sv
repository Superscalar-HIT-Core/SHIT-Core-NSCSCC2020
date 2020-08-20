`timescale 1ns / 1ps
`include "defines/defines.svh"

module InstBuffer_decode_regs(
    input wire clk,
    input wire rst,
    
    Ctrl.slave                  ctrl_instBuffer_decode_regs,
    InstBuffer_Backend.backend  instBuffer_backend,
    Regs_Decode.regs            regs_decode0,
    Regs_Decode.regs            regs_decode1
);

    assign instBuffer_backend.flushReq  = ctrl_instBuffer_decode_regs.flush;
    assign instBuffer_backend.ready     = ~ctrl_instBuffer_decode_regs.pause;

    always_ff @ (posedge clk) begin
        if(rst || ctrl_instBuffer_decode_regs.flush || (!instBuffer_backend.valid && !ctrl_instBuffer_decode_regs.pause)) begin
            regs_decode0.inst.valid <= `FALSE;
            regs_decode1.inst.valid <= `FALSE;
        end else if(ctrl_instBuffer_decode_regs.pause) begin
            regs_decode0.inst       <= regs_decode0.inst;
            regs_decode1.inst       <= regs_decode1.inst;
        end else begin
            regs_decode0.inst       <= instBuffer_backend.inst0;
            regs_decode1.inst       <= instBuffer_backend.inst1;
        end
    end

endmodule
