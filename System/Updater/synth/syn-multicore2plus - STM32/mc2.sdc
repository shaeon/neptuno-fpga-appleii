create_clock -name clk1_50 -period 20 [get_ports {clock_50_i}]

create_clock -name {speccy48_top:loader|ula:ula1|clk7}   -period 142.857
create_clock -name {speccy48_top:loader|ula:ula1|CPUClk} -period 285.714

derive_pll_clocks 

derive_clock_uncertainty

