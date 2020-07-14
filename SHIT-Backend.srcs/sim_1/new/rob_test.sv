`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/14 20:03:24
// Design Name: 
// Module Name: rob_test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rob_test(

    );

    
    logic            clk;
    logic            rst;

    Ctrl            ctrl_rob();
    Dispatch_ROB    dispatch_rob();
    FU_ROB          alu0_rob();
    FU_ROB          alu1_rob();
    FU_ROB          mdu_rob();
    FU_ROB          lsu_rob();

    ROB_Commit      rob_commit();

    ROB rob(.*);
    
    integer i;
    logic sendNxt;

    always #10 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        #25
        rst = 1'b0;
    end

    initial begin
        i=0;
        #30
        forever begin
            for(integer delay = $random % 10; delay > 0; delay--) @(posedge clk);
            dispatch_rob.sendUOP(i, 1, i+1, 1, clk);
            i+=2;
        end
    end
    
    initial begin
        forever begin
            sendNxt = $random;
            rob_commit.commitUOP(clk);
            for(integer delay = $random % 10; delay > 0; delay--) @(posedge clk);
        end
    end

    initial begin
        forever alu0_rob.sendFinish($random, clk);
    end

    initial begin
        forever alu1_rob.sendFinish($random, clk);
    end

    initial begin
        forever  lsu_rob.sendFinish($random, clk);
    end

    initial begin
        forever  mdu_rob.sendFinish($random, clk);
    end

endmodule
