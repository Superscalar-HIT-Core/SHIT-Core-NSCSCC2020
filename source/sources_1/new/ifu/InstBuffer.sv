`timescale 1ns / 1ps
`include "../defs.sv"

module InstBuffer(
    input   wire                    clk,
    input   wire                    rst,

    Ctrl.slave                      ctrl_instBuffer,

    IFU_InstBuffer.instBuffer       ifu_instBuffer,
    InstBuffer_Backend.instBuffer   instBuffer_backend
);

    // 0              IB_SIZE  IB_SIZE+1         2*IB_SIZE
    // v                     \/                     v
    // ______XXXXXXXXXXXXXX_________XXXXXXXXXXXXXX___
    //       ^             ^        ^
    //      tail          head    vtail
    //                   vhead

    // 0              IB_SIZE  IB_SIZE+1         2*IB_SIZE
    // v                     \/                     v
    // XXXXXXX____________XXXXXXXXXXXX___________XXXX
    //        ^           ^           ^
    //      head        tail         vhead
    //                 vtail

    // 0              IB_SIZE  IB_SIZE+1         2*IB_SIZE
    // v                     \/                     v
    // XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    //       ^                      ^                
    //      head                   vhead
    //      tail
    //     vtail


    logic                   populatedCrossBoundry;
    logic                   unpopulatedCrossBoundry;
    logic                   empty;
    logic                   passThrough;
    logic   [`IB_ADDR]      head;
    logic   [`IB_ADDR]      tail;
    logic   [`IB_ADDR]      iSlot0;
    logic   [`IB_ADDR]      iSlot1;
    logic   [`IB_ADDR]      oSlot0;
    logic   [`IB_ADDR]      oSlot1;
    logic                   isFull;
    logic                   oSlot0Loaded;
    logic                   oSlot1Loaded;
    logic                   waitForDS;

    logic   [1+`IB_ADDR]    vHead;
    logic   [1+`IB_ADDR]    vTail;

    logic   [31:0]          debug_inst_count;

    assign debug_inst_count = vTail - head;
    assign waitForDS        = !oSlot1Loaded && (data[oSlot0].isJ || data[oSlot0].isBr);

    InstBundle  data [`IB_SIZE-1:0];

    assign   populatedCrossBoundry  = tail <  head;
    assign unpopulatedCrossBoundry  = tail >= head;
    assign empty = head == tail;

    assign vHead = {unpopulatedCrossBoundry ? 1'b1 : 1'b0, head};
    assign vTail = {  populatedCrossBoundry ? 1'b1 : 1'b0, tail};

    assign iSlot0 = tail;
    assign iSlot1 = tail + 1'b1;
    assign oSlot0 = head;
    assign oSlot1 = head + 1'b1;

    assign oSlot0Loaded = head < vTail;
    assign oSlot1Loaded = vTail - head > 1;     // avoid overflow

    assign isFull   = vHead - tail <= 2'h2;

    assign ctrl_instBuffer.pauseReq = isFull;

    assign passThrough =    empty && 
                            instBuffer_backend.ready &&
                            ifu_instBuffer.inst0.valid &&
                            ifu_instBuffer.inst1.valid &&
                            !ifu_instBuffer.inst1.isJ && 
                            !ifu_instBuffer.inst1.isBr &&
                            !(rst || instBuffer_backend.flushReq);

    // >>>>>>>>>> INPUT PORT <<<<<<<<<<
    always_ff @ (posedge clk) begin
        if(rst || instBuffer_backend.flushReq) begin
            tail    <= 32'h0;
        end else if(!isFull && !passThrough) begin
            case ({ifu_instBuffer.inst0.valid, ifu_instBuffer.inst1.valid})
                2'b01: begin
                    tail            <= tail + 1'b1;
                    data[iSlot0]    <= ifu_instBuffer.inst1;
                end
                2'b10: begin
                    tail            <= tail + 1'b1;
                    data[iSlot0]    <= ifu_instBuffer.inst0;
                end
                2'b11: begin
                    tail            <= tail + 2'h2;
                    data[iSlot0]    <= ifu_instBuffer.inst0;
                    data[iSlot1]    <= ifu_instBuffer.inst1;
                end
                default: begin
                    tail            <= tail;
                end 
            endcase
        end
    end

    // >>>>>>>>>> OUTPUT PORT <<<<<<<<<<
    always_ff @ (posedge clk) begin
        if(rst || instBuffer_backend.flushReq) begin
            head    <= 32'h0;
        end else if(empty && !passThrough) begin
            head    <= head;
        end else begin
            instBuffer_backend.valid <= `TRUE;
            if(passThrough || !instBuffer_backend.ready) begin
                head    <= head;
            end else if(data[oSlot1].isJ || data[oSlot1].isBr || !waitForDS) begin
                head    <= head + 1'b1;
            end else if(oSlot0Loaded && oSlot1Loaded) begin
                head    <= head + 2'h2;
            end
        end
    end

    always_comb begin
        if(rst || instBuffer_backend.flushReq) begin
            instBuffer_backend.valid    = `FALSE;
        end else if((empty && !passThrough) || waitForDS) begin
            instBuffer_backend.valid    = `FALSE;
        end else begin
            instBuffer_backend.valid    = `TRUE;
            if(passThrough) begin
                instBuffer_backend.inst0        = ifu_instBuffer.inst0;
                instBuffer_backend.inst1        = ifu_instBuffer.inst1;
                instBuffer_backend.inst0.isDs   = `FALSE;
                instBuffer_backend.inst1.isDs   = instBuffer_backend.inst0.isBr || instBuffer_backend.inst0.isJ;
            end else if((data[oSlot1].isJ || data[oSlot1].isBr || !oSlot1Loaded) && !waitForDS) begin
                instBuffer_backend.inst0        = data[oSlot0];
                instBuffer_backend.inst0.isDs   = `FALSE;
                instBuffer_backend.inst1.valid  = `FALSE;
            end else begin
                instBuffer_backend.inst0        = data[oSlot0];
                instBuffer_backend.inst1        = data[oSlot1];
                instBuffer_backend.inst0.isDs   = `FALSE;
                instBuffer_backend.inst1.isDs   = data[oSlot0].isBr || data[oSlot0].isJ;
            end
        end
    end

endmodule
