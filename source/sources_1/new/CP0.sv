`timescale 1ns / 1ps
`include "defines/defines.svh"

module CP0(
    input wire          clk,
    input wire          rst,

    CP0WRInterface.cp0  alu0_cp0,
    CP0WRInterface.cp0  exception_cp0,
    CP0_TLB.cp0         cp0_tlb,

    CP0StatusRegs.cp0   cp0Status
);

    logic [31:0]    Index;
    logic [31:0]    Random;
    logic [31:0]    EntryLo0;
    logic [31:0]    EntryLo1;
    logic [31:0]    Context;
    logic [31:0]    PageMask;
    logic [31:0]    Wired;
    logic [31:0]    BadVAddr;
    logic [31:0]    Count;
    logic [31:0]    EntryHi;
    logic [31:0]    Compare;
    logic [31:0]    Status;
    logic [31:0]    Cause;
    logic [31:0]    EPc;
    logic [31:0]    PRId;
    logic [31:0]    EBase;
    logic [31:0]    Config;
    logic [31:0]    Config1;
    logic [31:0]    Config2;
    logic [31:0]    Config3;
    logic [31:0]    LLAddr;
    logic [31:0]    WatchLo;
    logic [31:0]    WatchHi;
    logic [31:0]    Debug;
    logic [31:0]    ErrCtl;
    logic [31:0]    TagLo;
    logic [31:0]    DataLo;
    logic [31:0]    ErrorEPC;
    logic [31:0]    DESave;

    always_ff @ (posedge clk) begin
        if(rst) begin
            Random  [31: 5] <= 27'h0;
            Random  [ 4: 0] <= 5'b11111;
            EntryLo0[31:30] <= 2'b00;
            Context [31: 0] <= 32'h0;       // 0
            PageMask[31: 0] <= 32'h0;       // page mask
            Count   [31: 0] <= 32'h0;       // Count
            Status  [31:28] <= 4'b0001;     // Coprocesser useability
            Status  [   26] <= 1'b0;        // FR
            Status  [   23] <= 1'b0;        // PX
            Status  [   22] <= 1'b1;        // Boot env
            Status  [   21] <= 1'b0;        // TS
            Status  [    3] <= 1'b0;        // R0
            Status  [    2] <= 1'b1;        // ERL
            Status  [    1] <= 1'b0;        // EXL
            Status  [    0] <= 1'b0;        // IE
            Cause   [31: 0] <= 32'h0;       // CAUSE
            PRId    [23:16] <= 8'hff;       // Company ID
            PRId    [15: 8] <= 8'h00;       // Processer ID
            PRId    [ 7: 0] <= 8'h00;       // Revision
            EBase   [   31] <= 1'b1;        // 1
            EBase   [   30] <= 1'b0;        // 0
            EBase   [29:12] <= 18'h0;       // Exception Base
            Config  [   31] <= 1'b1;        // M
            Config  [   15] <= 1'b0;        // little endian
            Config  [14:13] <= 2'b0;        // mips32
            Config  [12:10] <= 2'b0;        // Revision 1
            Config  [ 9: 7] <= 2'b1;        // Standard TLB
            Config1 [   31] <= 1'b0;        // M
            Config1 [30:25] <= 31;          // MMU Size - 1
            Config1 [24:22] <= 3'd1;        // ICache sets per way (64 sets)
            Config1 [21:19] <= 3'd3;        // ICache line size (16 bytes)
            Config1 [18:16] <= 3'd3;        // ICache associativity (4-way)
            Config1 [15:13] <= 3'hX;        // DCache sets per way
            Config1 [12:10] <= 3'h3;        // DCache line size (16 bytes)
            Config1 [ 9: 7] <= 3'hX;        // DCache associativity
            Config1 [    6] <= 1'b0;        // Copcessor 2
            Config1 [    5] <= 1'b0;        // 0
            Config1 [    4] <= 1'b0;        // performance counter impl
            Config1 [    3] <= 1'b0;        // watch reg impl
            Config1 [    2] <= 1'b0;        // Code compression impl
            Config1 [    1] <= 1'b0;        // EJTAG impl
            Config1 [    0] <= 1'b0;
        end else begin
            if(alu0_cp0.writeEn) begin
                case(alu_cp0.addr)
                    `CP0INDEX    : Index    <= (Index      & ~`CP0INDEXMASK     ) | (      alu_cp0.writeData & `CP0INDEXMASK    );
                    `CP0ENTRYLO0 : EntryLo0 <= (EntryLo0   & ~`CP0ENTRYLO0MASK  ) | (      alu_cp0.writeData & `CP0ENTRYLO0MASK );
                    `CP0ENTRYLO1 : EntryLo1 <= (EntryLo1   & ~`CP0ENTRYLO1MASK  ) | (      alu_cp0.writeData & `CP0ENTRYLO1MASK );
                    `CP0CONTEXT  : Context  <= (Context    & ~`CP0CONTEXTMASK   ) | (      alu_cp0.writeData & `CP0CONTEXTMASK  );
                    `CP0PAGEMASK : PageMask <= (PageMask   & ~`CP0PAGEMASKMASK  ) | (      alu_cp0.writeData & `CP0PAGEMASKMASK );
                    `CP0WIRED    : Wired    <= (Wired      & ~`CP0WIREDMASK     ) | (      alu_cp0.writeData & `CP0WIREDMASK    );
                    `CP0COUNT    : Count    <= (Count      & ~`CP0COUNTMASK     ) | (      alu_cp0.writeData & `CP0COUNTMASK    );
                    `CP0ENTRYHI  : EntryHi  <= (EntryHi    & ~`CP0ENTRYHIMASK   ) | (      alu_cp0.writeData & `CP0ENTRYHIMASK  );
                    `CP0COMPARE  : Compare  <= (Compare    & ~`CP0COMPAREMASK   ) | (      alu_cp0.writeData & `CP0COMPAREMASK  );
                    `CP0STATUS   : Status   <= (Status     & ~`CP0STATUSMASK    ) | (      alu_cp0.writeData & `CP0STATUSMASK   );
                    `CP0CAUSE    : Cause    <= (Cause      & ~`CP0CAUSEMASK     ) | (      alu_cp0.writeData & `CP0CAUSEMASK    );
                    `CP0EPC      : EPc      <= (EPc        & ~`CP0EPCMASK       ) | (      alu_cp0.writeData & `CP0EPCMASK      );
                    `CP0EBASE    : EBase    <= (EBase      & ~`CP0EBASEMASK     ) | (      alu_cp0.writeData & `CP0EBASEMASK    );
                    `CP0CONFIG   : Config   <= (Config     & ~`CP0CONFIGMASK    ) | (      alu_cp0.writeData & `CP0CONFIGMASK   );
                    `CP0ERROREPC : ErrorEPC <= (ErrorEPC   & ~`CP0ERROREPCMASK  ) | (      alu_cp0.writeData & `CP0ERROREPCMASK );
                endcase
            end
            if(exception_cp0.writeEn) begin
                case(exception_cp0.addr)
                    `CP0INDEX    : Index    <= (Index      & ~`CP0INDEXMASK     ) | (exception_cp0.writeData & `CP0INDEXMASK    );
                    `CP0ENTRYLO0 : EntryLo0 <= (EntryLo0   & ~`CP0ENTRYLO0MASK  ) | (exception_cp0.writeData & `CP0ENTRYLO0MASK );
                    `CP0ENTRYLO1 : EntryLo1 <= (EntryLo1   & ~`CP0ENTRYLO1MASK  ) | (exception_cp0.writeData & `CP0ENTRYLO1MASK );
                    `CP0CONTEXT  : Context  <= (Context    & ~`CP0CONTEXTMASK   ) | (exception_cp0.writeData & `CP0CONTEXTMASK  );
                    `CP0PAGEMASK : PageMask <= (PageMask   & ~`CP0PAGEMASKMASK  ) | (exception_cp0.writeData & `CP0PAGEMASKMASK );
                    `CP0WIRED    : Wired    <= (Wired      & ~`CP0WIREDMASK     ) | (exception_cp0.writeData & `CP0WIREDMASK    );
                    `CP0COUNT    : Count    <= (Count      & ~`CP0COUNTMASK     ) | (exception_cp0.writeData & `CP0COUNTMASK    );
                    `CP0ENTRYHI  : EntryHi  <= (EntryHi    & ~`CP0ENTRYHIMASK   ) | (exception_cp0.writeData & `CP0ENTRYHIMASK  );
                    `CP0COMPARE  : Compare  <= (Compare    & ~`CP0COMPAREMASK   ) | (exception_cp0.writeData & `CP0COMPAREMASK  );
                    `CP0STATUS   : Status   <= (Status     & ~`CP0STATUSMASK    ) | (exception_cp0.writeData & `CP0STATUSMASK   );
                    `CP0CAUSE    : Cause    <= (Cause      & ~`CP0CAUSEMASK     ) | (exception_cp0.writeData & `CP0CAUSEMASK    );
                    `CP0EPC      : EPc      <= (EPc        & ~`CP0EPCMASK       ) | (exception_cp0.writeData & `CP0EPCMASK      );
                    `CP0EBASE    : EBase    <= (EBase      & ~`CP0EBASEMASK     ) | (      alu_cp0.writeData & `CP0EBASEMASK    );
                    `CP0CONFIG   : Config   <= (Config     & ~`CP0CONFIGMASK    ) | (exception_cp0.writeData & `CP0CONFIGMASK   );
                    `CP0ERROREPC : ErrorEPC <= (ErrorEPC   & ~`CP0ERROREPCMASK  ) | (exception_cp0.writeData & `CP0ERROREPCMASK );
                endcase
            end
            if(cp0_tlb.writeEn) begin
                EntryLo0 <= (EntryLo0 & ~`CP0ENTRYLO0MASK) | (cp0_tlb.wEntryHi  & `CP0ENTRYLO0MASK);
                EntryLo1 <= (EntryLo1 & ~`CP0ENTRYLO1MASK) | (cp0_tlb.wPageMask & `CP0ENTRYLO1MASK);
                PageMask <= (PageMask & ~`CP0PAGEMASKMASK) | (cp0_tlb.wEntryLo0 & `CP0PAGEMASKMASK);
                EntryHi  <= (EntryHi  & ~`CP0ENTRYHIMASK ) | (cp0_tlb.wEntryLo1 & `CP0ENTRYHIMASK );
            end
        end
    end

    always_comb begin
        cp0Status.count     = Count;
        cp0Status.status    = Status;
        cp0Status.cause     = Cause;
        cp0Status.ePc       = EPc;
        cp0Status.eBase     = EBase;
        cp0Status.random    = Random;

        case (alu0_cp0.addr)
            `CP0INDEX       : alu0_cp0.readData = Index;
            `CP0RANDOM      : alu0_cp0.readData = Random;
            `CP0ENTRYLO0    : alu0_cp0.readData = EntryLo0;
            `CP0ENTRYLO1    : alu0_cp0.readData = EntryLo1;
            `CP0CONTEXT     : alu0_cp0.readData = Context;
            `CP0PAGEMASK    : alu0_cp0.readData = PageMask;
            `CP0WIRED       : alu0_cp0.readData = Wired;
            `CP0BADVADDR    : alu0_cp0.readData = BadVAddr;
            `CP0COUNT       : alu0_cp0.readData = Count;
            `CP0ENTRYHI     : alu0_cp0.readData = EntryHi;
            `CP0COMPARE     : alu0_cp0.readData = Compare;
            `CP0STATUS      : alu0_cp0.readData = Status;
            `CP0CAUSE       : alu0_cp0.readData = Cause;
            `CP0EPC         : alu0_cp0.readData = EPc;
            `CP0PRID        ,
            `CP0EBASE       : begin
                case(alu0_cp0.sel)
                    3'b000  : alu0_cp0.readData = PRId;
                    3'b001  : alu0_cp0.readData = EBase;
                    default : alu0_cp0.readData = 32'h0;
                endcase
            end
            `CP0CONFIG      ,
            `CP0CONFIG1     : begin
                case(alu0_cp0.sel)
                    3'b000  : alu0_cp0.readData = Config;
                    3'b001  : alu0_cp0.readData = Config1;
                    default : alu0_cp0.readData = 32'h0;
                endcase
            end
            `CP0ERROREPC    : alu0_cp0.readData = ErrorEPC;
            default         : alu0_cp0.readData = 32'h0000000;
        endcase

        case (exception_cp0.addr)
            `CP0INDEX       : exception_cp0.readData = Index;
            `CP0RANDOM      : exception_cp0.readData = Random;
            `CP0ENTRYLO0    : exception_cp0.readData = EntryLo0;
            `CP0ENTRYLO1    : exception_cp0.readData = EntryLo1;
            `CP0CONTEXT     : exception_cp0.readData = Context;
            `CP0PAGEMASK    : exception_cp0.readData = PageMask;
            `CP0WIRED       : exception_cp0.readData = Wired;
            `CP0BADVADDR    : exception_cp0.readData = BadVAddr;
            `CP0COUNT       : exception_cp0.readData = Count;
            `CP0ENTRYHI     : exception_cp0.readData = EntryHi;
            `CP0COMPARE     : exception_cp0.readData = Compare;
            `CP0STATUS      : exception_cp0.readData = Status;
            `CP0CAUSE       : exception_cp0.readData = Cause;
            `CP0EPC         : exception_cp0.readData = EPc;
            `CP0PRID        ,
            `CP0EBASE       : begin
                case(exception_cp0.sel)
                    3'b000  : exception_cp0.readData = PRId;
                    3'b001  : exception_cp0.readData = EBase;
                    default : exception_cp0.readData = 32'h0;
                endcase
            end
            `CP0CONFIG      ,
            `CP0CONFIG1     : begin
                case(exception_cp0.sel)
                    3'b000  : exception_cp0.readData = Config;
                    3'b001  : exception_cp0.readData = Config1;
                    default : exception_cp0.readData = 32'h0;
                endcase
            end
            `CP0ERROREPC    : exception_cp0.readData = ErrorEPC;
            default         : exception_cp0.readData = 32'h0000000;
        endcase
    end

endmodule