`timescale 1ns / 1ps
module queue_sim(

    );
reg clk,rst,enq1req,enq2req,deq1req,deq2req;
reg [3:0] din1,din2,deq1idx,deq2idx;
wire [3:0] deq1data,deq2data;
wire almost_full, almost_empty,full,empty;
compress_queue_prototype u_compress_queue_prototype(
	.clk          (clk          ),
    .rst          (rst          ),
    .enq1req      (enq1req      ),
    .enq2req      (enq2req      ),
    .din1         (din1         ),
    .din2         (din2         ),
    .deq1req      (deq1req      ),
    .deq2req      (deq2req      ),
    .deq1idx      (deq1idx      ),
    .deq2idx      (deq2idx      ),
    .deq1data     (deq1data     ),
    .deq2data     (deq2data     ),
    .almost_full  (almost_full  ),
    .almost_empty (almost_empty ),
    .full         (full         ),
    .empty        (empty        )
);

initial begin
    #0 clk=0;rst=1;enq1req=0;enq2req=0;deq1req=0;deq2req=0;din1=0;din2=0;deq1idx=0;deq2idx=0;
    #22 rst = 0;
    #10 enq1req = 1; din1 = 1;
    #20 enq1req = 0; 

    #20 enq1req = 1; enq2req = 1; din1 = 2; din2 = 3;
    #20 enq1req = 0; enq2req = 0; 

    #20 enq1req = 1; enq2req = 1; din1 = 4; din2 = 5;
    #20 enq1req = 0; enq2req = 0; 

    // #20 deq1req = 1; deq1idx = 2;
    // #20 deq1req = 0;

    // #20 deq1req = 1; deq1idx = 0; deq2req = 1; deq2idx = 2;
    // #20 deq1req = 0;deq2req = 0;

    #20 enq1req = 1; enq2req = 1; din1 = 2; din2 = 3;
    #20 enq1req = 0; enq2req = 0; 

    #20 enq1req = 1; enq2req = 1; din1 = 4; din2 = 5;
    #20 enq1req = 0; enq2req = 0; 

    #20 enq1req = 1; enq2req = 1; din1 = 2; din2 = 3;
    #20 enq1req = 0; enq2req = 0; 

    #20 enq1req = 1; enq2req = 1; din1 = 4; din2 = 5;
    #20 enq1req = 0; enq2req = 0; 

    #20 enq1req = 1; enq2req = 1; din1 = 2; din2 = 3;
    #20 enq1req = 0; enq2req = 0; 

    #20 enq1req = 1; enq2req = 1; din1 = 4; din2 = 5;
    #20 enq1req = 0; enq2req = 0; 
end

integer i;
always @(posedge clk)   begin
    $strobe("Tail:",u_compress_queue_prototype.tail);
    for(i=0;i<u_compress_queue_prototype.tail;i++) begin
        $display("Slot:",i, "; Data:", u_compress_queue_prototype.dout[i]);
    end
end

always begin
    #10 clk = ~clk;
end

endmodule
