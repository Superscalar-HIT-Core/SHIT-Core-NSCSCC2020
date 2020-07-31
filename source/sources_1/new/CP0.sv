`timescale 1ns / 1ps
`include "defines/defines.svh"

module CP0(
    input wire          clk,
    input wire          rst,
    CP0WRInterface.cp0  alu0_cp0,
    CP0_TLB.cp0         cp0_tlb,
    CP0Exception.cp0    exceInfo,
    CP0StatusRegs.cp0   cp0StatusRegs
);


    logic           divClk;

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
    
    wire            CounterInterrupt;
    assign exceInfo.Status_IE = Status[0];
    assign exceInfo.Status_EXL = Status[1];
    assign exceInfo.Status_IM = Status[15:10];
    // assign exceInfo.Status_BEV = Status[22];
    // 软件中断生成
    assign exceInfo.Status_IM_SW = Status[9:8];
    assign exceInfo.Cause_IP_SW = Cause[9:8];  // should be cause?
    assign CounterInterrupt = (Count == Compare);
    assign exceInfo.Counter_Int = CounterInterrupt;
    assign exceInfo.EPc = EPc;

    assign cp0StatusRegs.count      = Count;
    assign cp0StatusRegs.status     = Status;
    assign cp0StatusRegs.cause      = Cause;
    assign cp0StatusRegs.ePc        = EPc;
    assign cp0StatusRegs.eBase      = EBase;
    assign cp0StatusRegs.random     = Random;
    assign cp0StatusRegs.counterInt = CounterInterrupt;

    always_ff @ (posedge clk) begin
        if(rst) begin
            divClk          <= `FALSE;
            Random  [31: 5] <= 27'h0;
            Random  [4 : 0] <= 5'b11111;
            EntryLo0[31:30] <= 2'b00;
            Context [31: 0] <= 32'h0;       // 0
            PageMask[31: 0] <= 32'h0;       // page mask
            Count   [31: 0] <= 32'h0;       // Count

            Status  [31:28] <= 4'b0000;     // Coprocesser useability
            Status  [27:23] <= 5'h0;        // 0
            Status  [   26] <= 1'b0;        // FR
            Status  [   23] <= 1'b0;        // PX
            Status  [   22] <= 1'b1;        // Boot env BEV = 1, TODO: Write enable
            Status  [   21] <= 1'b0;        // TS
            Status  [20:16] <= 5'b0;        // 0
            Status  [15: 8] <= 8'b0;        // IM7..0
            Status  [7 : 4] <= 4'b0;        // 0
            Status  [    3] <= 1'b0;        // R0
            Status  [    2] <= 1'b0;        // ERL
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

            Compare [31: 0] <= 32'h0;       // fuck state X
        end else begin
            Cause[15:10]    <= exceInfo.interrupt; // IP7~IP2中断位
			Random          <= Random + 1;
            divClk          <= ~divClk;
            Count           <= Count + divClk;
            // Count           <= 32'hABCD0000;
            Cause[30]       <= CounterInterrupt;            // Cause.TI 计时器中断
        end

        // CP0 Set From Exception
        if(exceInfo.causeExce)  begin
            if(exceInfo.exceType == ExcEret) begin
                Status[1] <= 1'b0;
            end else if (!Status[1]) begin
                Status[1] <= 1'b1;
                Cause[31] <= exceInfo.isDS;
                // EPc <= exceInfo.isDS ? ( exceInfo.excePC - 4 ) : exceInfo.excePC;
                if (exceInfo.isDS)  EPc <= exceInfo.excePC - 4;
                else                EPc <= exceInfo.excePC;
                priority case(exceInfo.exceType)
                    ExcInterrupt:   begin
                        Cause[6:2] 		<= `Exc_INT;
                    end
                    ExcAddressErrL, ExcAddressErrIF: begin
                        BadVAddr 		<= exceInfo.reserved;
                        Cause[6:2] 		<= `Exc_ADEL;
                    end
                    ExcReservedInst:    begin
                        Cause[6:2]      <= `Exc_RI;
                    end
                    ExcSysCall:         begin
                        Cause[6:2]      <= `Exc_SYS;
                    end 
                    ExcBreak:           begin
                        Cause[6:2]      <= `Exc_BP;
                    end
                    ExcIntOverflow:     begin
                        Cause[6:2]      <= `Exc_OV;
                    end
                    ExcAddressErrS:     begin
                        Cause[6:2]      <= `Exc_ADES;
                        BadVAddr 		<= exceInfo.reserved;
                    end
                    default:            begin
                        Cause[6:2]      <= 0;
                    end
                endcase
            end
        end else if(alu0_cp0.writeEn) begin         // CP0写使能
            case(alu0_cp0.addr)
                `CP0INDEX    : Index    <= (Index      & ~`CP0INDEXMASK     ) | (alu0_cp0.writeData & `CP0INDEXMASK    );
                `CP0ENTRYLO0 : EntryLo0 <= (EntryLo0   & ~`CP0ENTRYLO0MASK  ) | (alu0_cp0.writeData & `CP0ENTRYLO0MASK );
                `CP0ENTRYLO1 : EntryLo1 <= (EntryLo1   & ~`CP0ENTRYLO1MASK  ) | (alu0_cp0.writeData & `CP0ENTRYLO1MASK );
                `CP0CONTEXT  : Context  <= (Context    & ~`CP0CONTEXTMASK   ) | (alu0_cp0.writeData & `CP0CONTEXTMASK  );
                `CP0PAGEMASK : PageMask <= (PageMask   & ~`CP0PAGEMASKMASK  ) | (alu0_cp0.writeData & `CP0PAGEMASKMASK );
                `CP0WIRED    : Wired    <= (Wired      & ~`CP0WIREDMASK     ) | (alu0_cp0.writeData & `CP0WIREDMASK    );
                `CP0ENTRYHI  : EntryHi  <= (EntryHi    & ~`CP0ENTRYHIMASK   ) | (alu0_cp0.writeData & `CP0ENTRYHIMASK  );
                `CP0COMPARE  : Compare  <= (Compare    & ~`CP0COMPAREMASK   ) | (alu0_cp0.writeData & `CP0COMPAREMASK  );
                `CP0STATUS   : Status   <= (Status     & ~`CP0STATUSMASK    ) | (alu0_cp0.writeData & `CP0STATUSMASK   );
                `CP0CAUSE    : begin    // 因为Cause上面会写
                    Cause[9:8] <= alu0_cp0.writeData[9:8];
                    Cause[22]  <= alu0_cp0.writeData[22];
                    Cause[23]  <= alu0_cp0.writeData[23];
                end
                `CP0EPC      : EPc      <= (EPc        & ~`CP0EPCMASK       ) | (alu0_cp0.writeData & `CP0EPCMASK      );
                `CP0EBASE    : EBase    <= (EBase      & ~`CP0EBASEMASK     ) | (alu0_cp0.writeData & `CP0EBASEMASK    );
                `CP0CONFIG   : Config   <= (Config     & ~`CP0CONFIGMASK    ) | (alu0_cp0.writeData & `CP0CONFIGMASK   );
                `CP0ERROREPC : ErrorEPC <= (ErrorEPC   & ~`CP0ERROREPCMASK  ) | (alu0_cp0.writeData & `CP0ERROREPCMASK );
            endcase
        end
        if(cp0_tlb.writeEn) begin
                EntryLo0 <= (EntryLo0 & ~`CP0ENTRYLO0MASK) | (cp0_tlb.wEntryHi  & `CP0ENTRYLO0MASK);
                EntryLo1 <= (EntryLo1 & ~`CP0ENTRYLO1MASK) | (cp0_tlb.wPageMask & `CP0ENTRYLO1MASK);
                PageMask <= (PageMask & ~`CP0PAGEMASKMASK) | (cp0_tlb.wEntryLo0 & `CP0PAGEMASKMASK);
                EntryHi  <= (EntryHi  & ~`CP0ENTRYHIMASK ) | (cp0_tlb.wEntryLo1 & `CP0ENTRYHIMASK );
        end
    end

    always_comb begin
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
    end

endmodule