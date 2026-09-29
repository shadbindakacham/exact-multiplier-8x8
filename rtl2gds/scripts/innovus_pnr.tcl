# Cadence Innovus place & route: gate-level netlist -> GDSII.
# Run from rtl2gds/work:   innovus -files ../scripts/innovus_pnr.tcl
# (Command names follow Innovus 19/20/21; older/newer versions may differ slightly.)

source [file join [file dirname [info script]] setup.tcl]

# ---- MMMC view definition (written from the settings in setup.tcl) ----
set mmmc [open $OUT_DIR/mmmc.tcl w]
puts $mmmc "create_library_set -name libset -timing \[list [lmap f $LIB_FILES {file join [lindex $LIB_DIRS 0] $f}]\]"
puts $mmmc "create_rc_corner -name rc_typ -qrc_tech $QRC_TECH"
puts $mmmc "create_delay_corner -name dc_typ -library_set libset -rc_corner rc_typ"
puts $mmmc "create_constraint_mode -name cm -sdc_files $SDC_FILE"
puts $mmmc "create_analysis_view -name av_typ -constraint_mode cm -delay_corner dc_typ"
puts $mmmc "set_analysis_view -setup av_typ -hold av_typ"
close $mmmc

set init_mmmc_file    $OUT_DIR/mmmc.tcl
set init_lef_file     $LEF_FILES
set init_verilog      $OUT_DIR/${DESIGN}_netlist.v
set init_top_cell     $DESIGN
set init_pwr_net      $POWER_NET
set init_gnd_net      $GROUND_NET
init_design

# ---- Floorplan: square core, 70% utilisation, 5um margins ----
floorPlan -site core -r 1.0 0.70 5 5 5 5
globalNetConnect $POWER_NET  -type pgpin -pin $POWER_NET  -all -verbose
globalNetConnect $GROUND_NET -type pgpin -pin $GROUND_NET -all -verbose

# ---- Power grid ----
addRing -nets [list $POWER_NET $GROUND_NET] -type core_rings \
        -layer [list top $CORE_MET_H bottom $CORE_MET_H left $CORE_MET_V right $CORE_MET_V] \
        -width 2 -spacing 1 -offset 1
addStripe -nets [list $POWER_NET $GROUND_NET] -layer $CORE_MET_V -direction vertical \
          -width 1 -spacing 1 -set_to_set_distance 20
sroute -nets [list $POWER_NET $GROUND_NET]

# ---- I/O pins: a/b on the left, p on the right ----
editPin -pin [list a\[*\] b\[*\]] -side LEFT  -spreadType SIDE -layer $CORE_MET_V -fixOverlap 1
editPin -pin [list p\[*\]]       -side RIGHT -spreadType SIDE -layer $CORE_MET_V -fixOverlap 1

# ---- Placement + pre-route optimisation ----
# (No CTS step: the multiplier is combinational and has no clock net.)
setPlaceMode -place_global_timing_effort high
place_opt_design

# ---- Routing + post-route optimisation ----
setNanoRouteMode -routeWithTimingDriven true -routeWithSiDriven true
routeDesign
setAnalysisMode -analysisType onChipVariation
optDesign -postRoute -setup -hold

# ---- Fillers ----
addFiller -cell $FILLER_CELLS -prefix FILLER

# ---- Sign-off style checks ----
verify_drc          -report $RPT_DIR/${DESIGN}_drc.rpt
verifyConnectivity -type all -report $RPT_DIR/${DESIGN}_conn.rpt
verifyGeometry      -report $RPT_DIR/${DESIGN}_geom.rpt

report_timing -max_paths 5 > $RPT_DIR/${DESIGN}_post_route_timing.rpt
report_area                > $RPT_DIR/${DESIGN}_post_route_area.rpt
report_power               > $RPT_DIR/${DESIGN}_post_route_power.rpt

# ---- Export ----
saveDesign $OUT_DIR/${DESIGN}.enc
saveNetlist $OUT_DIR/${DESIGN}_pnr.v
rcOut -spef $OUT_DIR/${DESIGN}.spef
write_sdf $OUT_DIR/${DESIGN}.sdf
streamOut $OUT_DIR/${DESIGN}.gds -mapFile $GDS_MAP -libName DesignLib \
          -merge [list $STDCELL_GDS] -units 1000 -mode ALL

puts "Innovus done. GDSII: $OUT_DIR/${DESIGN}.gds"
exit
