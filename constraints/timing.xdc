# Clock constraint: 50 MHz (20 ns period) targeting Artix-7 xc7a100tcsg324-1
# Critical path runs through EX stage: forwarding MUX -> ALU -> Zero flag
create_clock -period 20.000 -name clk [get_ports clk]

# Input/output delays (assuming synchronous external interfaces)
set_input_delay  -clock clk 2.0 [get_ports rst]
set_output_delay -clock clk 2.0 [all_outputs]
