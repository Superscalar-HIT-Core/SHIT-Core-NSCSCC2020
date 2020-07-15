create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
set_input_delay -clock clk 2.000 [get_ports *]
set_output_delay -clock clk 2.000 [get_ports *]

set_property BEL C6LUT [get_cells {u_map_table/rename_resp_0[prf_rd_stale][5]_INST_0_i_9}]
set_property LOC SLICE_X156Y111 [get_cells {u_map_table/rename_resp_0[prf_rd_stale][5]_INST_0_i_9}]
