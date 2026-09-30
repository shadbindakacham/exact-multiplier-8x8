# Batch-mode Vivado simulation of mult8x8_bw (optional; the GUI steps in the README do the same).
# Run from the repository root:   vivado -mode batch -source scripts/vivado_sim.tcl
set root [file normalize [file join [file dirname [info script]] ..]]
cd $root

create_project -force mult_vivado $root/vivado_proj -part xc7a35tcpg236-1
add_files [glob $root/rtl/*.v]
add_files -fileset sim_1 $root/sim/TB_mult8x8_bw.v
set_property top mult8x8_bw       [current_fileset]
set_property top TB_mult8x8_bw    [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation
run all

# Copy the CSV out of the xsim run folder into sim/
set csv [file join $root vivado_proj mult_vivado.sim sim_1 behav xsim results.csv]
file copy -force $csv $root/sim/results.csv
close_sim
puts "Done. Results: $root/sim/results.csv"
