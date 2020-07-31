`timescale 1ns / 1ps



module TageBank(
    input clk,
    input rst,
    // For Prediction
    input TAGEIndex index_in,
    input TAGETag tag_in,
    output TAGECtr ctr_out,
    output TAGEUseful useful_out,
    output hit_out,
    // For updating
    input update_en,
    input TAGEIndex ,
    input TAGEPred update_info,
    input update_useful,
    input inc_useful,
    input dec_useful,
    input reset_useful,
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
wire [10:0] dout;
assign tag_read = dout[10:3];
assign ctr_read = dout[2:0];
assign hit = tag_read == tag_in;
assign wen = update_en;
wire [14:0] din;
// 10 Bits for Tag and 3 Bits for counter
assign din[14:3] = update_info.tag;
assign din[2:0] = update_info.counter;


endmodule
