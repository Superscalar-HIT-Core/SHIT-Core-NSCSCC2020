`include "../defines/defines.svh"
`timescale 1ns / 1ps

module ROB(
    input wire          clk,
    input wire          rst,
    
    Ctrl.slave          ctrl_rob,
    Dispatch_ROB.rob    dispatch_rob,
    FU_ROB.rob          alu0_rob,
    FU_ROB.rob          alu1_rob,
    FU_ROB.rob          mdu_rob,
    FU_ROB.rob          lsu_rob,

    ROB_Commit.rob      rob_commit
);

    // 0             ROB_SIZE  ROB_SIZE+1       2*ROB_SIZE
    // v                     \/                     v
    // ______XXXXXXXXXXXXXX_________XXXXXXXXXXXXXX___
    //       ^             ^        ^
    //      tail          head    vtail
    //                   vhead

    // 0             ROB_SIZE  ROB_SIZE+1       2*ROB_SIZE
    // v                     \/                     v
    // XXXXXXX____________XXXXXXXXXXXX___________XXXX
    //        ^           ^           ^
    //      head        tail         vhead
    //                 vtail

    // 0             ROB_SIZE  ROB_SIZE+1       2*ROB_SIZE
    // v                     \/                     v
    // XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    //       ^                      ^                
    //      head                   vhead
    //      tail
    //     vtail

    logic                   populatedCrossBoundry;
    logic                   unpopulatedCrossBoundry;
    logic                   empty;
    logic                   full;
    logic   [`ROB_ADDR_W]   head;
    logic   [`ROB_ADDR_W]   tail;
    logic   [1+`ROB_ADDR_W] vHead;
    logic   [1+`ROB_ADDR_W] vTail;
    // logic                   out0Busy;
    // logic                   out1Busy;
    logic                   out0Good;
    logic                   out1Good;
    logic                   out0Done;
    logic                   out1Done;

    UOPBundle   data0[`ROB_SIZE-1 : 0];
    UOPBundle   data1[`ROB_SIZE-1 : 0];

    assign ctrl_rob.pauseReq = full;
    assign dispatch_rob.robID = tail;

    assign unpopulatedCrossBoundry  = tail >= head;
    assign populatedCrossBoundry    = tail <  head;
    
    assign empty    = head == tail;
    assign full     = vHead - tail <= 1'b1;

    assign dispatch_rob.ready   = !full;
    assign dispatch_rob.empty   = empty;

    assign vHead    = {unpopulatedCrossBoundry ? 1'b1 : 1'b0, head};
    assign vTail    = {  populatedCrossBoundry ? 1'b1 : 1'b0, tail};

    // assign out0Busy = data0[head].valid && !data0[head].committed && data0[head].busy;
    // assign out1Busy = data1[head].valid && !data1[head].committed && data1[head].busy;

    assign out0Good = data0[head].valid && !data0[head].committed && !data0[head].busy;
    assign out1Good = data1[head].valid && !data1[head].committed && !data1[head].busy && out0Done;

    assign out0Done = !data0[head].valid || data0[head].committed || (out0Good && rob_commit.ready && rob_commit.valid);
    assign out1Done = !data1[head].valid || data1[head].committed || (out1Good && rob_commit.ready && rob_commit.valid);

    assign rob_commit.valid = (out0Good || out1Good) && !empty;
    
    assign rob_commit.uOP0  = data0[head];
    //assign rob_commit.uOP0.committed = data0[head].committed || (rob_commit.ready && rob_commit.valid && out0Good);
    
    assign rob_commit.uOP1  = data1[head];
    //assign rob_commit.uOP1.committed = data1[head].committed || (rob_commit.ready && rob_commit.valid && out1Good);

    always_ff @(posedge clk) begin
        if(rst || ctrl_rob.flush) begin
            for(integer i=0;i<`ROB_SIZE;i++) begin
                data0[i]             <= 0;
                data1[i]             <= 0;
            end 
            tail                    <= 32'h0;
            for(integer i = 0; i < `ROB_SIZE; i++) begin
                data0[i] <= 0;
                data1[i] <= 0;
            end
        end else if(dispatch_rob.ready && dispatch_rob.valid && !full) begin
            tail                    <= tail + 1'h1;

            data0[tail]             <= dispatch_rob.uOP0;
            data0[tail].id          <= {tail, 1'b0};
            data0[tail].committed   <= `FALSE;

            data1[tail]             <= dispatch_rob.uOP1;
            data1[tail].id          <= {tail, 1'b1};
            data1[tail].committed   <= `FALSE;
        end else begin
            tail                    <= tail;
        end

        if(alu0_rob.setFinish && alu0_rob.id[0] == 1'b0) begin
            data0[alu0_rob.id >> 1'b1].busy <= `FALSE;
            if(alu0_rob.setBranchStatus) begin
                data0[alu0_rob.id >> 1'b1].branchTaken <= alu0_rob.branchTaken;
                data0[alu0_rob.id >> 1'b1].branchAddr  <= alu0_rob.branchAddr;
            end
            if(alu0_rob.setException) begin
                data0[alu0_rob.id >> 1'b1].causeExc    <= `TRUE;
                data0[alu0_rob.id >> 1'b1].exception   <= alu0_rob.exceptionType;
                data0[alu0_rob.id >> 1'b1].BadVAddr    <= alu0_rob.BadVAddr;
            end
        end else if(alu0_rob.setFinish && alu0_rob.id[0] == 1'b1) begin
            data1[alu0_rob.id >> 1'b1].busy <= `FALSE;
            if(alu0_rob.setBranchStatus) begin
                data1[alu0_rob.id >> 1'b1].branchTaken <= alu0_rob.branchTaken;
                data1[alu0_rob.id >> 1'b1].branchAddr  <= alu0_rob.branchAddr;
            end
            if(alu0_rob.setException) begin
                data1[alu0_rob.id >> 1'b1].causeExc    <= `TRUE;
                data1[alu0_rob.id >> 1'b1].exception   <= alu0_rob.exceptionType;
                data1[alu0_rob.id >> 1'b1].BadVAddr    <= alu0_rob.BadVAddr;
            end
        end
        
        if(alu1_rob.setFinish && alu1_rob.id[0] == 1'b0) begin
            data0[alu1_rob.id >> 1'b1].busy <= `FALSE;
            if(alu1_rob.setBranchStatus) begin
                data0[alu1_rob.id >> 1'b1].branchTaken <= alu1_rob.branchTaken;
                data0[alu1_rob.id >> 1'b1].branchAddr  <= alu1_rob.branchAddr;
            end
            if(alu1_rob.setException) begin
                data0[alu1_rob.id >> 1'b1].causeExc    <= `TRUE;
                data0[alu1_rob.id >> 1'b1].exception   <= alu1_rob.exceptionType;
                data0[alu1_rob.id >> 1'b1].BadVAddr    <= alu1_rob.BadVAddr;
            end
        end else if(alu1_rob.setFinish && alu1_rob.id[0] == 1'b1) begin
            data1[alu1_rob.id >> 1'b1].busy <= `FALSE;
            if(alu1_rob.setBranchStatus) begin
                data1[alu1_rob.id >> 1'b1].branchTaken <= alu1_rob.branchTaken;
                data1[alu1_rob.id >> 1'b1].branchAddr  <= alu1_rob.branchAddr;
            end
            if(alu1_rob.setException) begin
                data1[alu1_rob.id >> 1'b1].causeExc    <= `TRUE;
                data1[alu1_rob.id >> 1'b1].exception   <= alu1_rob.exceptionType;
                data1[alu1_rob.id >> 1'b1].BadVAddr    <= alu1_rob.BadVAddr;
            end
        end
        
        if(mdu_rob.setFinish && mdu_rob.id[0] == 1'b0) begin
            data0[mdu_rob.id >> 1'b1].busy <= `FALSE;
        end else if(mdu_rob.setFinish && mdu_rob.id[0] == 1'b1) begin
            data1[mdu_rob.id >> 1'b1].busy <= `FALSE;
        end
        
        if(lsu_rob.setFinish && lsu_rob.id[0] == 1'b0) begin
            data0[lsu_rob.id >> 1'b1].busy <= `FALSE;
            if(lsu_rob.setException) begin
                data0[lsu_rob.id >> 1'b1].causeExc     <= `TRUE;
                data0[lsu_rob.id >> 1'b1].exception    <= lsu_rob.exceptionType;
                data0[lsu_rob.id >> 1'b1].BadVAddr     <= lsu_rob.BadVAddr;
            end
        end else if(lsu_rob.setFinish && lsu_rob.id[0] == 1'b1) begin
            data1[lsu_rob.id >> 1'b1].busy <= `FALSE;
            if(lsu_rob.setException) begin
                data1[lsu_rob.id >> 1'b1].causeExc     <= `TRUE;
                data1[lsu_rob.id >> 1'b1].exception    <= lsu_rob.exceptionType;
                data1[lsu_rob.id >> 1'b1].BadVAddr     <= lsu_rob.BadVAddr;
            end
        end
        
        // commit
        if(rob_commit.ready && rob_commit.valid && out0Good) begin
            data0[head].committed   <= `TRUE;
        end
        if(rob_commit.ready && rob_commit.valid && out1Good) begin
            data1[head].committed   <= `TRUE;
        end
    end

    // >>>>>>>>>> COMMIT <<<<<<<<<<
    always_ff @(posedge clk) begin
        if(rst || ctrl_rob.flush) begin
            head    <= 32'd0;
        end else if(out0Done && out1Done && !empty) begin
            head    <= head + 1'b1;
        end
    end
    

endmodule