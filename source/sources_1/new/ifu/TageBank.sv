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
    input TAGEIndex update_index,
    input TAGETag update_tag,
    input TAGECtr update_ctr,
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
        UsefulBits[update_index] <= UsefulBits[update_index] == 2'b11 ? 2'b11 : UsefulBits[update_index] + 2'b1;
    end else if (update_useful && dec_useful) begin
        UsefulBits[update_index] <= UsefulBits[update_index] == 2'b00 ? 2'b00 : UsefulBits[update_index] - 2'b1;
    end else if(reset_useful)   begin
        UsefulBits[update_index] <= 0;
    end
end
assign bypass = update_index == index_in;
wire [10:0] dout;
assign tag_read = ~bypass ? dout[10:3] : update_tag;
assign ctr_out = ~bypass ? dout[2:0] : update_ctr;
assign hit_out = ~bypass ? (tag_read == tag_in) : (update_tag == tag_in);
assign useful_out = UsefulBits[index_in];
assign wen = update_en;
wire [10:0] din;
// 8 Bits for Tag and 3 Bits for counter
assign din[10:3] = update_tag;
assign din[2:0] = update_ctr;


// dist_mem_gen_0 tag_ctr (
//   .a(update_index),        // Write address
//   .d(din),        // input wire [10 : 0] d
//   .dpra(index_in),  // Read address
//   .clk(clk),    // input wire clk
//   .we(update_en),      // input wire we
//   .dpo(dout)    // output wire [10 : 0] dpo
// );

// TAGEHist history (
//   .clk(clk),    // input wire clka
//   .wea(update_en), // input wire [0 : 0] wea
//   .addra(update_index),  // input wire [9 : 0] addra
//   .dina(din),    // input wire [10 : 0] dina
//   .addrb(index_in),  // input wire [9 : 0] addrb
//   .doutb(dout)  // output wire [10 : 0] doutb
// );

blk_mem_gen_0 history (
  .clka(clk),    // input wire clka
  .wea(update_en),      // input wire [0 : 0] wea
  .addra(update_index),  // input wire [9 : 0] addra
  .dina(din),    // input wire [10 : 0] dina
  .clkb(clk),    // input wire clkb
  .enb(~bypass),
  .addrb(index_in),  // input wire [9 : 0] addrb
  .doutb(dout)  // output wire [10 : 0] doutb
);
endmodule
