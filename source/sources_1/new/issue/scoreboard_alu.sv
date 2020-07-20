`timescale 1ns / 1ps

module scoreboard_16r6w(
    input clk,
    input rst,
    input flush,
    // dispatched instructions
    input set_busy_0,
    input set_busy_1,
    PRFNum set_busy_num_0,
    PRFNum set_busy_num_1,
    // issued instructions(at most 4 instructions issue at a time)
    input clr_busy_ALU0,
    input clr_busy_ALU1,
    input clr_busy_LSU,
    input clr_busy_MDU,
    PRFNum clr_busy_num_ALU0,
    PRFNum clr_busy_num_ALU1,
    PRFNum clr_busy_num_LSU,
    PRFNum clr_busy_num_MDU,
    PRFNum [7:0] rd_num_l ,
    PRFNum [7:0] rd_num_r ,
    output [7:0] busyvec_l,
    output [7:0] busyvec_r
    );

busy_table_6w4r bank0( 
    .clk                    (clk),
    .rst                    (rst),
    .flush                  (flush),
    .rd_port0               (rd_num_l[0]),
    .rd_port1               (rd_num_l[1]),
    .rd_port2               (rd_num_l[2]),
    .rd_port3               (rd_num_l[3]),
    .set_busy_0             (set_busy_0),
    .set_busy_1             (set_busy_1),
    .set_busy_num_0         (set_busy_num_0),
    .set_busy_num_1         (set_busy_num_1),
    .clr_busy_0             (clr_busy_ALU0),
    .clr_busy_1             (clr_busy_ALU1),
    .clr_busy_2             (clr_busy_LSU),
    .clr_busy_3             (clr_busy_MDU),
    .clr_busy_num_0         (clr_busy_num_ALU0),
    .clr_busy_num_1         (clr_busy_num_ALU1),
    .clr_busy_num_2         (clr_busy_num_LSU),
    .clr_busy_num_3         (clr_busy_num_MDU),
    .busy0                  (busyvec_l[0]),
    .busy1                  (busyvec_l[1]),
    .busy2                  (busyvec_l[2]),
    .busy3                  (busyvec_l[3])
    );


busy_table_6w4r bank1( 
    .clk                    (clk),
    .rst                    (rst),
    .flush                  (flush),
    .rd_port0               (rd_num_l[4]),
    .rd_port1               (rd_num_l[5]),
    .rd_port2               (rd_num_l[6]),
    .rd_port3               (rd_num_l[7]),
    .set_busy_0             (set_busy_0),
    .set_busy_1             (set_busy_1),
    .set_busy_num_0         (set_busy_num_0),
    .set_busy_num_1         (set_busy_num_1),
    .clr_busy_0             (clr_busy_ALU0),
    .clr_busy_1             (clr_busy_ALU1),
    .clr_busy_2             (clr_busy_LSU),
    .clr_busy_3             (clr_busy_MDU),
    .clr_busy_num_0         (clr_busy_num_ALU0),
    .clr_busy_num_1         (clr_busy_num_ALU1),
    .clr_busy_num_2         (clr_busy_num_LSU),
    .clr_busy_num_3         (clr_busy_num_MDU),
    .busy0                  (busyvec_l[4]),
    .busy1                  (busyvec_l[5]),
    .busy2                  (busyvec_l[6]),
    .busy3                  (busyvec_l[7])
    );

busy_table_6w4r bank2( 
    .clk                    (clk),
    .rst                    (rst),
    .flush                  (flush),
    .rd_port0               (rd_num_r[0]),
    .rd_port1               (rd_num_r[1]),
    .rd_port2               (rd_num_r[2]),
    .rd_port3               (rd_num_r[3]),
    .set_busy_0             (set_busy_0),
    .set_busy_1             (set_busy_1),
    .set_busy_num_0         (set_busy_num_0),
    .set_busy_num_1         (set_busy_num_1),
    .clr_busy_0             (clr_busy_ALU0),
    .clr_busy_1             (clr_busy_ALU1),
    .clr_busy_2             (clr_busy_LSU),
    .clr_busy_3             (clr_busy_MDU),
    .clr_busy_num_0         (clr_busy_num_ALU0),
    .clr_busy_num_1         (clr_busy_num_ALU1),
    .clr_busy_num_2         (clr_busy_num_LSU),
    .clr_busy_num_3         (clr_busy_num_MDU),
    .busy0                  (busyvec_r[0]),
    .busy1                  (busyvec_r[1]),
    .busy2                  (busyvec_r[2]),
    .busy3                  (busyvec_r[3])
    );

busy_table_6w4r bank3( 
    .clk                    (clk),
    .rst                    (rst),
    .flush                  (flush),
    .rd_port0               (rd_num_r[4]),
    .rd_port1               (rd_num_r[5]),
    .rd_port2               (rd_num_r[6]),
    .rd_port3               (rd_num_r[7]),
    .set_busy_0             (set_busy_0),
    .set_busy_1             (set_busy_1),
    .set_busy_num_0         (set_busy_num_0),
    .set_busy_num_1         (set_busy_num_1),
    .clr_busy_0             (clr_busy_ALU0),
    .clr_busy_1             (clr_busy_ALU1),
    .clr_busy_2             (clr_busy_LSU),
    .clr_busy_3             (clr_busy_MDU),
    .clr_busy_num_0         (clr_busy_num_ALU0),
    .clr_busy_num_1         (clr_busy_num_ALU1),
    .clr_busy_num_2         (clr_busy_num_LSU),
    .clr_busy_num_3         (clr_busy_num_MDU),
    .busy0                  (busyvec_r[4]),
    .busy1                  (busyvec_r[5]),
    .busy2                  (busyvec_r[6]),
    .busy3                  (busyvec_r[7])
    );

endmodule
