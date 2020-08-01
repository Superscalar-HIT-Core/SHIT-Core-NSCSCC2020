`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Tage分支预测器，历史长度10，20，40，80
//////////////////////////////////////////////////////////////////////////////////


module TAGE_Phase0(
    input clk,
    input rst,
    input pause,
    input recover,
    input new_branch_happen,
    input new_branch_taken,
    // For branch prediction
    input [31:0] br_pc,
    // For updating bpd
    input commit_valid,
    input committed_branch_taken,
    output TAGEIndex [3:0] index,
    output TAGETag [3:0] PCTags,
    output flush_ubits_hi, flush_ubits_lo
    );

    reg [79:0] hist_80;
    reg [79:0] committed_hist_80;

    wire [9:0] folded_hist_10;
    wire [9:0] folded_hist_20;
    wire [9:0] folded_hist_30;
    wire [9:0] folded_hist_40;

    // Predict Phase 0: Index generation logic
    
    // TODO: Design the function to generate pc tag
    assign PCTags[0]     =    br_pc[11:4]  
                            ^ hist_80[7:0] 
                            ^ { hist_80[8:1], 1'b0 };
    assign PCTags[1]     =    br_pc[11:4]  
                            ^ hist_80[7:0] 
                            ^ { hist_80[8:1], 1'b0 }
                            ^ { 1'b0, hist_80[14:8] }
                            ^ { hist_80[6:0], 1'b0 } 
                            ^ { hist_80[13:7], 1'b0 };
    assign PCTags[2]     =    br_pc[11:4] 
							^ ( hist_80[8:0] 
							^   hist_80[17:9] 
							^   hist_80[26:18] 
							^   hist_80[35:27] )
							^ ( { 1'b0,hist_80[43:36] } 
							^   { hist_80[7:0],1'b0 } 
							^   { hist_80[15:8],1'b0 } 
							^   { hist_80[23:16],1'b0 } )
							^ ( { hist_80[31:24],1'b0 } 
							^   { hist_80[39:32],1'b0 } 
							^   { 4'h0,hist_80[43:40],1'b0 } );
    assign PCTags[3]     =    br_pc[8:0]
                            ^ ( hist_80[8:0]
                            ^   hist_80[17:9]
                            ^   hist_80[26:18]
                            ^   hist_80[35:27] )
                            ^ ( hist_80[44:36]
                            ^   hist_80[53:45]
                            ^   hist_80[62:54]
                            ^   hist_80[71:63] )
                            ^ ( {hist_80[7:0],1'b0}
                            ^   {hist_80[15:8],1'b0}
                            ^   {hist_80[23:16],1'b0}
                            ^   {hist_80[31:24],1'b0} )
                            ^ ( {hist_80[39:32],1'b0}
                            ^   {hist_80[47:40],1'b0}
                            ^   {hist_80[55:48],1'b0}
                            ^   {hist_80[63:56],1'b0} )
                            ^ {hist_80[71:64],1'b0}
                            ^ {hist_80[79:72],1'b0} ;
    // TAGE Indexing Logic
    assign folded_hist_10 = hist_80[9:0];
    assign folded_hist_20 = hist_80[19:10] ^ hist_80[9:0];
    assign folded_hist_40 = ( hist_80[19:10] ^ hist_80[9:0] ) ^ 
                            ( hist_80[39:30] ^ hist_80[29:20] );
    assign folded_hist_80 = ( (hist_80[19:10] ^ hist_80[9:0] ) ^ 
                            ( hist_80[39:30] ^ hist_80[29:20] ) ) ^ 
                            ( (hist_80[49:40] ^ hist_80[59:50] ) ^ 
                            ( hist_80[69:60] ^ hist_80[79:70] ) );

    assign index[0] = folded_hist_10 ^ br_pc[13:4];
    assign index[1] = folded_hist_20 ^ br_pc[13:4];
    assign index[2] = folded_hist_40 ^ br_pc[13:4];
    assign index[3] = folded_hist_80 ^ br_pc[13:4];

    // History update
    always @(posedge clk)   begin
        if(rst) begin
            hist_80 <= 0;
        end else if (recover) begin
            hist_80 <= committed_hist_80;
        end else if (pause) begin
            hist_80 <= hist_80;
        end else if(new_branch_happen) begin 
            hist_80 <= { hist_80[78:0],new_branch_taken};
        end
    end

    // History update
    always @(posedge clk)   begin
        if(rst) begin
            committed_hist_80 <= 0;
        end else if(commit_valid) begin
            committed_hist_80 <= { committed_hist_80[78:0], committed_branch_taken};
        end
    end
    // 8 bits tag and 3 bits ctr
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
        end else if(new_branch_happen) begin
            branch_cnt <= branch_cnt + new_branch_taken;
        end
    end

    always @(posedge clk)   begin
        if(rst) begin
            committed_branch_cnt <= 0;
        end else if(commit_valid) begin
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
