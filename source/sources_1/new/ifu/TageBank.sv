`timescale 1ns / 1ps



module TageBank(
    input clk,
    input rst,
    // For Prediction
    input TAGEIndex index,
    output TAGECtr ctr,
    output TAGEUseful useful,
    output TAGETag tag,
    // For updating
    input update_hist,
    input TAGEIndex ,
    input TAGEPred update_info,
    input update_useful,
    input inc_useful,
    input dec_useful,
    // For periodically refreshing useful bit
    input refreshUsefulHi,
    input refreshUsefulLo
    );

TAGEUseful UsefulBits[1023:0];

always_ff @(posedge clk) begin
    if(rst) begin
        for(integer i=0; i<1024;i++)begin
            UsefulBits[i] <= 0;
        end
    end else if(refreshUsefulHi) begin
        for(integer i=0; i<1024;i++)begin
            UsefulBits[i][1] <= 0;
        end
    end else if(refreshUsefulLo) begin
        for(integer i=0; i<1024;i++)begin
            UsefulBits[i][0] <= 0;
        end        
    end else if (update_useful && inc_useful) begin
        UsefulBits[update_index] <= UsefulBits[update_index] == 2'b11 ? 2'b11 : UsefulBits + 2'b1;
    end else if (update_useful && dec_useful) begin
        UsefulBits[update_index] <= UsefulBits[update_index] == 2'b00 ? 2'b00 : UsefulBits - 2'b1;
    end
end
wire [14:0] dout;
assign tag = dout[14:3];
assign ctr = dout[2:0];
assign wen = update_hist;
wire [14:0] din;
// 10 Bits for Tag and 3 Bits for counter
assign din[14:3] = update_info.tag;
assign din[2:0] = update_info.counter;
// 实例化Block  RAM


endmodule
