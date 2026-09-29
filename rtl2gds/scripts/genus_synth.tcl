# Cadence Genus synthesis: RTL -> gate-level netlist.
# Run from rtl2gds/work:   genus -legacy_ui -f ../scripts/genus_synth.tcl   (or plain `genus -f ...`)

source [file join [file dirname [info script]] setup.tcl]

set_db init_lib_search_path $LIB_DIRS
set_db init_hdl_search_path [list $ROOT/rtl]
set_db library $LIB_FILES

# Read and elaborate with the multiplier as the top module
read_hdl -v2001 $RTL_FILES
elaborate $DESIGN
check_design -unresolved

read_sdc $SDC_FILE

set_db syn_generic_effort medium
set_db syn_map_effort     medium
set_db syn_opt_effort     medium

syn_generic
syn_map
syn_opt

report_timing -max_paths 5 > $RPT_DIR/${DESIGN}_timing.rpt
report_area                > $RPT_DIR/${DESIGN}_area.rpt
report_power               > $RPT_DIR/${DESIGN}_power.rpt
report_gates               > $RPT_DIR/${DESIGN}_gates.rpt

write_hdl > $OUT_DIR/${DESIGN}_netlist.v
write_sdc > $OUT_DIR/${DESIGN}_netlist.sdc

puts "Genus synthesis done. Netlist: $OUT_DIR/${DESIGN}_netlist.v"
exit
