# The multiplier is purely combinational, so there is no real clock port.
# A virtual clock is used to give the input->output path a timing budget.
# Edit the period (ns) to explore speed/area trade-offs.

set CLK_PERIOD 10.0

create_clock -name vclk -period $CLK_PERIOD

set_input_delay  -clock vclk [expr {$CLK_PERIOD * 0.2}] [get_ports {a[*] b[*]}]
set_output_delay -clock vclk [expr {$CLK_PERIOD * 0.2}] [get_ports {p[*]}]

# Adjust to match your library's units / a representative cell
# set_driving_cell -lib_cell BUFX2 [get_ports {a[*] b[*]}]
# set_load 0.02 [get_ports {p[*]}]
