`timescale 1ns / 1ps
`include "../defines/defines.svh"
module freelist_enc64_r(
    input [`PRF_NUM-1:0] free_list,
    output reg free_valid,
    output reg [`PRF_NUM_WIDTH-1:0] free_num
    );
// wire [2:0] free_nums_low3[7:0];
// wire [2:0] free_nums_hi3;
// wire [7:0] free_valid_l1;
// wire free_valid_l2;
// Encode a free list vector
// Level 1
// 8 * 8 -> 1 encoder
// genvar i;
// generate 
//     for (i=0;i<8;i=i+1) begin
//         fl_encoder_8 u1(.src(free_list[i*8+7: i*8]), .freenum(free_nums_low3[i]), .free_valid(free_valid_l1[i]));
//     end
// endgenerate
// // Level 2
// // 8 -> 1 encoder
// fl_encoder_8 l2(.src(~free_valid_l1), .freenum(free_nums_hi3), .free_valid(free_valid_l2));
// assign free_num = { free_nums_hi3, free_nums_low3[free_nums_hi3] };
// assign free_valid = free_valid_l2;

always_comb begin
    free_valid = 1;
    priority casez(free_list)    
        64'b0???????????????????????????????????????????????????????????????: free_num = 6'd0;
        64'b10??????????????????????????????????????????????????????????????: free_num = 6'd1;
        64'b110?????????????????????????????????????????????????????????????: free_num = 6'd2;
        64'b1110????????????????????????????????????????????????????????????: free_num = 6'd3;
        64'b11110???????????????????????????????????????????????????????????: free_num = 6'd4;
        64'b111110??????????????????????????????????????????????????????????: free_num = 6'd5;
        64'b1111110?????????????????????????????????????????????????????????: free_num = 6'd6;
        64'b11111110????????????????????????????????????????????????????????: free_num = 6'd7;
        64'b111111110???????????????????????????????????????????????????????: free_num = 6'd8;
        64'b1111111110??????????????????????????????????????????????????????: free_num = 6'd9;
        64'b11111111110?????????????????????????????????????????????????????: free_num = 6'd10;
        64'b111111111110????????????????????????????????????????????????????: free_num = 6'd11;
        64'b1111111111110???????????????????????????????????????????????????: free_num = 6'd12;
        64'b11111111111110??????????????????????????????????????????????????: free_num = 6'd13;
        64'b111111111111110?????????????????????????????????????????????????: free_num = 6'd14;
        64'b1111111111111110????????????????????????????????????????????????: free_num = 6'd15;
        64'b11111111111111110???????????????????????????????????????????????: free_num = 6'd16;
        64'b111111111111111110??????????????????????????????????????????????: free_num = 6'd17;
        64'b1111111111111111110?????????????????????????????????????????????: free_num = 6'd18;
        64'b11111111111111111110????????????????????????????????????????????: free_num = 6'd19;
        64'b111111111111111111110???????????????????????????????????????????: free_num = 6'd20;
        64'b1111111111111111111110??????????????????????????????????????????: free_num = 6'd21;
        64'b11111111111111111111110?????????????????????????????????????????: free_num = 6'd22;
        64'b111111111111111111111110????????????????????????????????????????: free_num = 6'd23;
        64'b1111111111111111111111110???????????????????????????????????????: free_num = 6'd24;
        64'b11111111111111111111111110??????????????????????????????????????: free_num = 6'd25;
        64'b111111111111111111111111110?????????????????????????????????????: free_num = 6'd26;
        64'b1111111111111111111111111110????????????????????????????????????: free_num = 6'd27;
        64'b11111111111111111111111111110???????????????????????????????????: free_num = 6'd28;
        64'b111111111111111111111111111110??????????????????????????????????: free_num = 6'd29;
        64'b1111111111111111111111111111110?????????????????????????????????: free_num = 6'd30;
        64'b11111111111111111111111111111110????????????????????????????????: free_num = 6'd31;
        64'b111111111111111111111111111111110???????????????????????????????: free_num = 6'd32;
        64'b1111111111111111111111111111111110??????????????????????????????: free_num = 6'd33;
        64'b11111111111111111111111111111111110?????????????????????????????: free_num = 6'd34;
        64'b111111111111111111111111111111111110????????????????????????????: free_num = 6'd35;
        64'b1111111111111111111111111111111111110???????????????????????????: free_num = 6'd36;
        64'b11111111111111111111111111111111111110??????????????????????????: free_num = 6'd37;
        64'b111111111111111111111111111111111111110?????????????????????????: free_num = 6'd38;
        64'b1111111111111111111111111111111111111110????????????????????????: free_num = 6'd39;
        64'b11111111111111111111111111111111111111110???????????????????????: free_num = 6'd40;
        64'b111111111111111111111111111111111111111110??????????????????????: free_num = 6'd41;
        64'b1111111111111111111111111111111111111111110?????????????????????: free_num = 6'd42;
        64'b11111111111111111111111111111111111111111110????????????????????: free_num = 6'd43;
        64'b111111111111111111111111111111111111111111110???????????????????: free_num = 6'd44;
        64'b1111111111111111111111111111111111111111111110??????????????????: free_num = 6'd45;
        64'b11111111111111111111111111111111111111111111110?????????????????: free_num = 6'd46;
        64'b111111111111111111111111111111111111111111111110????????????????: free_num = 6'd47;
        64'b1111111111111111111111111111111111111111111111110???????????????: free_num = 6'd48;
        64'b11111111111111111111111111111111111111111111111110??????????????: free_num = 6'd49;
        64'b111111111111111111111111111111111111111111111111110?????????????: free_num = 6'd50;
        64'b1111111111111111111111111111111111111111111111111110????????????: free_num = 6'd51;
        64'b11111111111111111111111111111111111111111111111111110???????????: free_num = 6'd52;
        64'b111111111111111111111111111111111111111111111111111110??????????: free_num = 6'd53;
        64'b1111111111111111111111111111111111111111111111111111110?????????: free_num = 6'd54;
        64'b11111111111111111111111111111111111111111111111111111110????????: free_num = 6'd55;
        64'b111111111111111111111111111111111111111111111111111111110???????: free_num = 6'd56;
        64'b1111111111111111111111111111111111111111111111111111111110??????: free_num = 6'd57;
        64'b11111111111111111111111111111111111111111111111111111111110?????: free_num = 6'd58;
        64'b111111111111111111111111111111111111111111111111111111111110????: free_num = 6'd59;
        64'b1111111111111111111111111111111111111111111111111111111111110???: free_num = 6'd60;
        64'b11111111111111111111111111111111111111111111111111111111111110??: free_num = 6'd61;
        64'b111111111111111111111111111111111111111111111111111111111111110?: free_num = 6'd62;
        64'b1111111111111111111111111111111111111111111111111111111111111110: free_num = 6'd63;
        default: begin
            free_num = 6'd0 ;
            free_valid = 0;
        end
    endcase
end
endmodule
