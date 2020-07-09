`include "../defines/defines.svh"
module compress_queue_prototype(
    input clk,
    input rst,
    // 入队请求
    input enq1req,
    input enq2req,
    input [3:0] din1,
    input [3:0] din2,
    // 出队请求
    input deq1req,
    input deq2req,
    // 出队index
    input [3:0] deq1idx,
    input [3:0] deq2idx,
    // 出队数据
    output [3:0] deq1data,
    output [3:0] deq2data,

    output almost_full,
    output almost_empty,
    output full,
    output empty
    );

// 其他模块应该保证，队列满或者将满的时候，不再往里塞
// 队列只剩下一个空位的时候，保证只取最小的那个
// 此模块中就不处理队列将空的部分了
// 需要保证：deq1idx 小于 deq2idx
// 需要保证：如果只enqueue或者dequeue一个的话，必须只使用1这个端口
reg [3:0]tail; // 一共是16位
assign almost_full = (tail == 4'he);  // 差1位满，也不能写入
assign empty = (tail == 4'b0);  // 差1位满，也不能写入
assign full = (tail == 4'hf);
assign almost_empty = (tail == 4'b1);
wire [15:0] deq,enq;
reg [1:0] dsel[15:0];
wire [3:0] up2_data[15:0];
wire [3:0] up1_data[15:0];
wire [3:0] dout[17:0];
wire [15:0] cmp_en;
wire [15:0] enq_sel;

wire [3:0] new_tail_0 = tail - deq1req - deq2req;
wire [3:0] new_tail_1 = tail + enq1req - deq1req - deq2req;

wire [15:0] wr_vec_0 = enq1req ? ( 16'b1 << new_tail_0 ) : 16'b0;
wire [15:0] wr_vec_1 = enq2req ? ( 16'b1 << new_tail_1 ) | wr_vec_0 : wr_vec_0;


assign dout[16] = 4'b0;
assign dout[17] = 4'b0;
genvar i;
generate
    for(i=0;i<16;i++)   begin
        compress_queue_entry_prototype u_compress_queue_entry_prototype(
        	.clk      (clk      ),
            .rst      (rst      ),
            .cmp_en   (cmp_en[i]      ),
            .dsel     (dsel[i]     ),
            .enq_en   (wr_vec_1[i]),
            .enq_sel  (enq_sel[i]),
            .din1     (din1     ),
            .din2     (din2     ),
            .up2_data (up2_data[i] ),
            .up1_data (up1_data[i] ),
            .dout     (dout[i]     )
        );
        assign enq_sel[i] = (new_tail_0 != i);
        assign up1_data[i] = dout[i+1];
        assign up2_data[i] = dout[i+2];
        assign cmp_en[i] = (( deq1req && ~deq2req && i>=deq1idx ) || (deq1req && deq2req && i>= deq1idx ));
        assign dsel[i] = ( deq1req && ~deq2req && i >= deq1idx ) || (deq1req && deq2req && i >= deq1idx && i < deq2idx -1) ? `CMPQ_SEL_UP1 :
                            `CMPQ_SEL_UP2;
    end
endgenerate


assign deq1data = dout[deq1idx];
assign deq2data = dout[deq2idx];

always @(posedge clk)   begin
    if (rst) begin
        tail <= 4'b0;
    end else begin  // 仲裁器必须保证在队列将空的时候正确的请求
        tail <= tail + enq1req + enq2req - deq1req - deq2req;
    end
end

endmodule