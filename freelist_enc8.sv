`timescale 1ns / 1ps

module fl_encoder_8(
    input [7:0] src,
    output reg [2:0] freenum,
    output reg free_valid
    );
always @(*) begin
   free_valid = 1;
   casez(src)    
        8'b???????0: freenum = 3'b000;
        8'b??????01: freenum = 3'b001;
        8'b?????011: freenum = 3'b010;
        8'b????0111: freenum = 3'b011;
        8'b???01111: freenum = 3'b100;
        8'b??011111: freenum = 3'b101;
        8'b?0111111: freenum = 3'b110;
        8'b01111111: freenum = 3'b111;
        default: begin
            freenum = 3'b000 ;
            free_valid = 0;
        end
    endcase
end

endmodule
