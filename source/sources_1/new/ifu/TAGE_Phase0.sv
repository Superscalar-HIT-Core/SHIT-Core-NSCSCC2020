`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Tage分支预测器，历史长度10，20，40，80
//////////////////////////////////////////////////////////////////////////////////


module TAGE_Phase0(
    input clk,
    input rst,
    input pause,
    input recover,
    input committed_branch_taken,
    input new_branch_taken,
    // For branch prediction
    input [31:0] br_pc,
    output TAGEIndex [3:0] index,
    output TAGETag PCTag,
    output flush_ubits_hi, flush_ubits_lo
    );

    reg [9:0]  hist_10;
    reg [19:0] hist_20;
    reg [39:0] hist_40;
    reg [79:0] hist_80;

    reg [9:0]  committed_hist_10;
    reg [19:0] committed_hist_20;
    reg [39:0] committed_hist_40;
    reg [79:0] committed_hist_80;

    wire [9:0] folded_hist_10;
    wire [9:0] folded_hist_20;
    wire [9:0] folded_hist_30;
    wire [9:0] folded_hist_40;

    // Predict Phase 0: Index generation logic
    
    // TODO: Design the function to generate pc tag

    // TAGE Indexing Logic
    assign folded_hist_10 = hist_10;
    assign folded_hist_20 = hist_20[19:10] ^ hist_20[9:0];
    assign folded_hist_40 = ( hist_40[19:10] ^ hist_40[9:0] ) ^ 
                            ( hist_40[39:30] ^ hist_40[29:20] );
    assign folded_hist_80 = ( (hist_80[19:10] ^ hist_80[9:0] ) ^ 
                            ( hist_80[39:30] ^ hist_80[29:20] ) ) ^ 
                            ( (hist_80[49:40] ^ hist_80[59:50] ) ^ 
                            ( hist_80[69:60] ^ hist_80[79:70] ) );

    assign index[0] = folded_hist_10 ^ pc[13:4];
    assign index[1] = folded_hist_20 ^ pc[13:4];
    assign index[2] = folded_hist_40 ^ pc[13:4];
    assign index[3] = folded_hist_80 ^ pc[13:4];

    // History update
    always @(posedge clk)   begin
        if(rst) begin
            hist_10 <= 0;
            hist_20 <= 0;
            hist_40 <= 0;
            hist_80 <= 0;
        end else if (recover) begin
            hist_10 <= committed_hist_10;
            hist_20 <= committed_hist_20;
            hist_40 <= committed_hist_40;
            hist_80 <= committed_hist_80;
        end else if (pause) begin
            hist_10 <= hist_10;
            hist_20 <= hist_20;
            hist_40 <= hist_40;
            hist_80 <= hist_80;
        end else begin
            hist_10 <= { hist_10[8:0], new_branch_taken};
            hist_20 <= { hist_20[18:0],new_branch_taken};
            hist_40 <= { hist_40[38:0],new_branch_taken};
            hist_80 <= { hist_80[78:0],new_branch_taken};
        end
    end

    // History update
    always @(posedge clk)   begin
        if(rst) begin
            committed_hist_10 <= 0;
            committed_hist_20 <= 0;
            committed_hist_40 <= 0;
            committed_hist_80 <= 0;
        end else begin
            committed_hist_10 <= { committed_hist_10[8:0],  committed_branch_taken};
            committed_hist_20 <= { committed_hist_20[18:0], committed_branch_taken};
            committed_hist_40 <= { committed_hist_40[38:0], committed_branch_taken};
            committed_hist_80 <= { committed_hist_80[78:0], committed_branch_taken};
        end
    end

    reg wait_flush_hi, wait_flush_lo;
    wire flush_ubit;
    // 128K = 2^18;
    reg [17:0] branch_cnt;
    reg [17:0] committed_branch_cnt;
    always @(posedge clk)   begin
        if(rst) begin
            branch_cnt <= 0;
        end else if(recover)    begin
            branch_cnt <= committed_branch_cnt;
        end else begin
            branch_cnt <= branch_cnt + new_branch_taken;
        end
    end

    always @(posedge clk)   begin
        if(rst) begin
            committed_branch_cnt <= 0;
        end else begin
            committed_branch_cnt <= committed_branch_cnt + committed_branch_taken;
        end
    end

    // Perodically Flush the Useful bits (interval 128K Branches)
    assign flush_ubit = ( branch_cnt == 17'b1_1111_1111_1111_1111 );

    always @(posedge clk)   begin
        if(rst) begin
            wait_flush_hi <= 1'b1;
            wait_flush_lo <= 1'b0;
        end else if (flush_ubit)    begin
            wait_flush_hi <= ~wait_flush_hi;
            wait_flush_lo <= ~wait_flush_lo;
        end
    end

    assign flush_ubits_hi = flush_ubit && wait_flush_hi;
    assign flush_ubits_lo = flush_ubit && wait_flush_lo;


endmodule
