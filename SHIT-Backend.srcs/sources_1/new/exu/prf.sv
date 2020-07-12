`timescale 1ns / 1ps
`include "../defines/defines.svh"
//////////////////////////////////////////////////////////////////////////////////
// 物理寄存器堆文件
// 
//////////////////////////////////////////////////////////////////////////////////

module prf(
    input clk,
    input rst,
    PRFwrNums wrnum_ALU_0, wrnum_ALU_1, wrnum_MDU, wrnum_LSU,
    PRFrData rdata_ALU_0, rdata_ALU_1, rdata_MDU, rdata_LSU,
    input wr_hi,
    input wr_lo,
    input Word wdata_hi,
    input Word wdata_lo,
    output Word Hi, Lo
    );
// 4 Banks of prf
reg [31:0] prfs_bank0[63:0];
reg [31:0] prfs_bank1[63:0];
reg [31:0] prfs_bank2[63:0];
reg [31:0] prfs_bank3[63:0];

assign rdata_ALU_0.rs0_data = prfs_bank0[wrnum_ALU_0.rs0];
assign rdata_ALU_0.rs1_data = prfs_bank0[wrnum_ALU_0.rs1];

assign rdata_ALU_1.rs0_data = prfs_bank1[wrnum_ALU_1.rs0];
assign rdata_ALU_1.rs1_data = prfs_bank1[wrnum_ALU_1.rs1];

assign rdata_MDU.rs0_data = prfs_bank2[wrnum_MDU.rs0];
assign rdata_MDU.rs1_data = prfs_bank2[wrnum_MDU.rs1];

assign rdata_LSU.rs0_data = prfs_bank3[wrnum_MDU.rs0];
assign rdata_LSU.rs1_data = prfs_bank3[wrnum_MDU.rs1];

integer i;
always_ff @(posedge clk)    begin
    if(rst) begin
        for(i=0;i<64;i++)   begin
            prfs_bank0[i] <= 32'b0;
            prfs_bank1[i] <= 32'b0;
            prfs_bank2[i] <= 32'b0;
            prfs_bank3[i] <= 32'b0;
        end
    end else begin
        if(wrnum_ALU_0.wen) begin
            prfs_bank0[wrnum_ALU_0.rd] <= wrnum_ALU_0.wdata;
            prfs_bank1[wrnum_ALU_0.rd] <= wrnum_ALU_0.wdata;
            prfs_bank2[wrnum_ALU_0.rd] <= wrnum_ALU_0.wdata;
            prfs_bank3[wrnum_ALU_0.rd] <= wrnum_ALU_0.wdata;
        end
        if(wrnum_ALU_1.wen) begin
            prfs_bank0[wrnum_ALU_1.rd] <= wrnum_ALU_1.wdata;
            prfs_bank1[wrnum_ALU_1.rd] <= wrnum_ALU_1.wdata;
            prfs_bank2[wrnum_ALU_1.rd] <= wrnum_ALU_1.wdata;
            prfs_bank3[wrnum_ALU_1.rd] <= wrnum_ALU_1.wdata;
        end
        // if(wrnum_MDU.wen) begin                              // Impossible!
        //     prfs_bank0[wrnum_MDU.rd] <= wrnum_MDU.wdata;
        //     prfs_bank1[wrnum_MDU.rd] <= wrnum_MDU.wdata;
        //     prfs_bank2[wrnum_MDU.rd] <= wrnum_MDU.wdata;
        //     prfs_bank3[wrnum_MDU.rd] <= wrnum_MDU.wdata;
        // end
        if(wrnum_LSU.wen) begin
            prfs_bank0[wrnum_LSU.rd] <= wrnum_LSU.wdata;
            prfs_bank1[wrnum_LSU.rd] <= wrnum_LSU.wdata;
            prfs_bank2[wrnum_LSU.rd] <= wrnum_LSU.wdata;
            prfs_bank3[wrnum_LSU.rd] <= wrnum_LSU.wdata;
        end
    end
end

always_ff @(posedge clk)    begin
    if(rst) begin
        Hi <= 32'b0;
        Lo <= 32'b0;
    end else begin
        if(wr_hi)   begin
            Hi <= wdata_hi;
        end 
        if(wr_lo)   begin
            Lo <= wdata_lo;
        end
    end
end


endmodule
