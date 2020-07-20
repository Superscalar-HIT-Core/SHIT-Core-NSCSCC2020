`include "../defines/defines.svh"
`timescale 1ns / 1ps

module busy_table( 
    // Handle the bypass logic in busy table instead of in the iq
    input clk,
    input rst,
    input flush,
    // 4 read ports for dispatching, handles bypass logic 
    PRFNum rd_port0,
    PRFNum rd_port1,
    PRFNum rd_port2,
    PRFNum rd_port3,

    // At most 2 instructions dispatched at one time 
    input set_busy_0,
    input set_busy_1,


    PRFNum set_busy_num_0,
    PRFNum set_busy_num_1,

    // At most 4 instructions finish at one time 
    input clr_busy_0,
    input clr_busy_1,
    input clr_busy_2,
    input clr_busy_3,

    PRFNum clr_busy_num_0,
    PRFNum clr_busy_num_1,
    PRFNum clr_busy_num_2,
    PRFNum clr_busy_num_3,
    
    output busy0,
    output busy1,
    output busy2,
    output busy3
    );

reg [`PRF_NUM-1:0] busytable_bank0, busytable_bank1;

// Handle the bypass logic
// wire rd_port0_bypass_ena =  (rd_port0 == clr_busy_num_0 && clr_busy_0 ) ||
//                             (rd_port0 == clr_busy_num_1 && clr_busy_1 ) ||
//                             (rd_port0 == clr_busy_num_2 && clr_busy_2 ) ||
//                             (rd_port0 == clr_busy_num_3 && clr_busy_3 ) ;

// wire rd_port1_bypass_ena =  (rd_port1 == clr_busy_num_0 && clr_busy_0 ) ||
//                             (rd_port1 == clr_busy_num_1 && clr_busy_1 ) ||
//                             (rd_port1 == clr_busy_num_2 && clr_busy_2 ) ||
//                             (rd_port1 == clr_busy_num_3 && clr_busy_3 ) ;

// wire rd_port2_bypass_ena =  (rd_port2 == clr_busy_num_0 && clr_busy_0 ) ||
//                             (rd_port2 == clr_busy_num_1 && clr_busy_1 ) ||
//                             (rd_port2 == clr_busy_num_2 && clr_busy_2 ) ||
//                             (rd_port2 == clr_busy_num_3 && clr_busy_3 ) ;                            

// wire rd_port3_bypass_ena =  (rd_port3 == clr_busy_num_0 && clr_busy_0 ) ||
//                             (rd_port3 == clr_busy_num_1 && clr_busy_1 ) ||
//                             (rd_port3 == clr_busy_num_2 && clr_busy_2 ) ||
//                             (rd_port3 == clr_busy_num_3 && clr_busy_3 ) ;   

wire [`PRF_NUM-1:0] set_busy_vec =  (( set_busy_0 << set_busy_num_0  ) | 
                                    ( set_busy_1 << set_busy_num_1 )) & ~(`PRF_NUM'b1) ;     // 0号寄存器永远不能Busy

wire [`PRF_NUM-1:0] clr_busy_vec =  (~( clr_busy_0 << clr_busy_num_0 )) & 
                                    (~( clr_busy_1 << clr_busy_num_1 )) & 
                                    (~( clr_busy_2 << clr_busy_num_2 )) & 
                                    (~( clr_busy_3 << clr_busy_num_3 )) ; 

// if 1 of the 2 is zero, it can be inferred that the register will be not busy
// So, bypass logic is no longer needed, the circuit can be simplified
assign busy0 = clr_busy_vec[rd_port0] & busytable_bank0[rd_port0];
assign busy1 = clr_busy_vec[rd_port1] & busytable_bank0[rd_port1];
assign busy2 = clr_busy_vec[rd_port2] & busytable_bank1[rd_port2];
assign busy3 = clr_busy_vec[rd_port3] & busytable_bank1[rd_port3];


always @(posedge clk)   begin
    if(rst || flush)    begin
        busytable_bank0 <= `PRF_NUM'b0;
        busytable_bank1 <= `PRF_NUM'b0;
    end else begin
        busytable_bank0 <= busytable_bank0 | set_busy_vec & clr_busy_vec;
        busytable_bank1 <= busytable_bank1 | set_busy_vec & clr_busy_vec;
    end
end


endmodule


module busy_table_6w4r( 
    // Handle the bypass logic in busy table instead of in the iq
    input clk,
    input rst,
    input flush,
    // 4 read ports for dispatching, handles bypass logic 
    PRFNum rd_port0,
    PRFNum rd_port1,
    PRFNum rd_port2,
    PRFNum rd_port3,

    // At most 2 instructions dispatched at one time 
    input set_busy_0,
    input set_busy_1,
    PRFNum set_busy_num_0,
    PRFNum set_busy_num_1,

    // At most 4 instructions finish at one time 
    input clr_busy_0,
    input clr_busy_1,
    input clr_busy_2,
    input clr_busy_3,

    PRFNum clr_busy_num_0,
    PRFNum clr_busy_num_1,
    PRFNum clr_busy_num_2,
    PRFNum clr_busy_num_3,
    
    output busy0,
    output busy1,
    output busy2,
    output busy3
    );

reg [`PRF_NUM-1:0] busytable_bank0, busytable_bank1;

// Handle the bypass logic
// wire rd_port0_bypass_ena =  (rd_port0 == clr_busy_num_0 && clr_busy_0 ) ||
//                             (rd_port0 == clr_busy_num_1 && clr_busy_1 ) ||
//                             (rd_port0 == clr_busy_num_2 && clr_busy_2 ) ||
//                             (rd_port0 == clr_busy_num_3 && clr_busy_3 ) ;

// wire rd_port1_bypass_ena =  (rd_port1 == clr_busy_num_0 && clr_busy_0 ) ||
//                             (rd_port1 == clr_busy_num_1 && clr_busy_1 ) ||
//                             (rd_port1 == clr_busy_num_2 && clr_busy_2 ) ||
//                             (rd_port1 == clr_busy_num_3 && clr_busy_3 ) ;

// wire rd_port2_bypass_ena =  (rd_port2 == clr_busy_num_0 && clr_busy_0 ) ||
//                             (rd_port2 == clr_busy_num_1 && clr_busy_1 ) ||
//                             (rd_port2 == clr_busy_num_2 && clr_busy_2 ) ||
//                             (rd_port2 == clr_busy_num_3 && clr_busy_3 ) ;                            

// wire rd_port3_bypass_ena =  (rd_port3 == clr_busy_num_0 && clr_busy_0 ) ||
//                             (rd_port3 == clr_busy_num_1 && clr_busy_1 ) ||
//                             (rd_port3 == clr_busy_num_2 && clr_busy_2 ) ||
//                             (rd_port3 == clr_busy_num_3 && clr_busy_3 ) ;   

wire [`PRF_NUM-1:0] set_busy_vec =  (( set_busy_0 << set_busy_num_0  ) | 
                                    ( set_busy_1 << set_busy_num_1 )) & ~(`PRF_NUM'b1) ;     // 0号寄存器永远不能Busy

wire [`PRF_NUM-1:0] clr_busy_vec =  (~( clr_busy_0 << clr_busy_num_0 )) & 
                                    (~( clr_busy_1 << clr_busy_num_1 )) & 
                                    (~( clr_busy_2 << clr_busy_num_2 )) & 
                                    (~( clr_busy_3 << clr_busy_num_3 )) ; 

// if 1 of the 2 is zero, it can be inferred that the register will be not busy
// So, bypass logic is no longer needed, the circuit can be simplified
assign busy0 = clr_busy_vec[rd_port0] & busytable_bank0[rd_port0];
assign busy1 = clr_busy_vec[rd_port1] & busytable_bank0[rd_port1];
assign busy2 = clr_busy_vec[rd_port2] & busytable_bank1[rd_port2];
assign busy3 = clr_busy_vec[rd_port3] & busytable_bank1[rd_port3];


always @(posedge clk)   begin
    if(rst || flush)    begin
        busytable_bank0 <= `PRF_NUM'b0;
        busytable_bank1 <= `PRF_NUM'b0;
    end else begin
        busytable_bank0 <= busytable_bank0 | set_busy_vec & clr_busy_vec;
        busytable_bank1 <= busytable_bank1 | set_busy_vec & clr_busy_vec;
    end
end


endmodule
