create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
set_input_delay –clock clk 2 [get_ports *]
set_output_delay –clock clk 2 [get_ports *]