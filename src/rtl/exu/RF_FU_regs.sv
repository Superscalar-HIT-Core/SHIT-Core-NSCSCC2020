//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/21 20:18:05
// Design Name: 
// Module Name: RF_FU_regs
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "../defines/defines.svh"

module RF_FU_regs(
    input  wire         clk,
    input  wire         rst,
    
    Ctrl.slave          ctrl_rf_fu_regs,
    input  wire         primPauseReq,

    input  UOPBundle    rfBundle,
    input  PRFrData     rfRes,

    output UOPBundle    fuBundle,
    output PRFrData     fuOprands
);

    always_ff @ (posedge clk) begin
        if(rst || ctrl_rf_fu_regs.flush) begin
            fuBundle        <= 0;
            fuOprands       <= 0;
        end else if(primPauseReq || ctrl_rf_fu_regs.pause) begin
            fuBundle        <= fuBundle;
            fuOprands       <= fuOprands;
        end else begin
            fuBundle        <= rfBundle;
            fuOprands       <= rfRes;
        end
    end

endmodule



module RF_LSU_regs(
    input  wire         clk,
    input  wire         rst,
    
    Ctrl.slave          ctrl_rf_fu_regs,
    input  wire         primPauseReq,

    input  UOPBundle    rfBundle,
    input  PRFrData     rfRes,
    input  PRFwInfo     bypass_alu0,
    input  PRFwInfo     bypass_alu1,

    output UOPBundle    fuBundle,
    output PRFrData     fuOprands
);
    PRFrData currentOperands;
    wire bypass_alu0_src0_en = bypass_alu0.wen && (bypass_alu0.rd == rfBundle.op0PAddr);
    wire bypass_alu0_src1_en = bypass_alu0.wen && (bypass_alu0.rd == rfBundle.op1PAddr);
    wire bypass_alu1_src0_en = bypass_alu1.wen && (bypass_alu1.rd == rfBundle.op0PAddr);
    wire bypass_alu1_src1_en = bypass_alu1.wen && (bypass_alu1.rd == rfBundle.op1PAddr);
    Word src0, src1;
    assign src0 =   bypass_alu0_src0_en ? bypass_alu0.wdata : 
                    ( bypass_alu1_src0_en ? bypass_alu1.wdata : rfRes.rs0_data );
    assign src1 =   bypass_alu0_src1_en ? bypass_alu0.wdata : 
                    ( bypass_alu1_src1_en ? bypass_alu1.wdata : rfRes.rs1_data );
    assign currentOperands.rs0_data = src0;
    assign currentOperands.rs1_data = src1;
    always_ff @ (posedge clk) begin
        if(rst || ctrl_rf_fu_regs.flush) begin
            fuBundle        <= 0;
            fuOprands       <= 0;
        end else if(primPauseReq || ctrl_rf_fu_regs.pause) begin
            fuBundle        <= fuBundle;
            fuOprands       <= fuOprands;
        end else begin
            fuBundle        <= rfBundle;
            fuOprands       <= currentOperands;
        end
    end

endmodule