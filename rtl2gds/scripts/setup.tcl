# Shared settings for Genus and Innovus.
# EDIT THE PATHS BELOW to point at your technology kit (PDK / std-cell library).

set DESIGN     mult8x8_bw
set ROOT       [file normalize [file join [file dirname [info script]] .. ..]]

# ---- Technology files (placeholders: replace with your PDK paths) ----
set LIB_DIRS   [list /path/to/pdk/lib]                       ;# directory holding .lib files
set LIB_FILES  [list slow.lib]                               ;# e.g. typical/slow timing libs
set LEF_FILES  [list /path/to/pdk/lef/tech.lef \
                     /path/to/pdk/lef/stdcells.lef]          ;# tech LEF first, then cell LEF
set QRC_TECH   /path/to/pdk/qrc/qrcTechFile                  ;# optional, for RC extraction
set GDS_MAP    /path/to/pdk/gds/streamOut.map                ;# Innovus -> GDS layer map
set STDCELL_GDS /path/to/pdk/gds/stdcells.gds                ;# std-cell GDS to merge in
set FILLER_CELLS [list FILL1 FILL2 FILL4 FILL8]              ;# filler cell names in your lib
set POWER_NET  VDD
set GROUND_NET VSS
set CORE_MET_H METAL5                                        ;# power ring/stripe layers
set CORE_MET_V METAL6

# ---- Project files ----
set RTL_FILES [list \
    $ROOT/rtl/full_adder.v \
    $ROOT/rtl/compressor_4to2.v \
    $ROOT/rtl/compressor_3to2.v \
    $ROOT/rtl/cla_4bit.v \
    $ROOT/rtl/cla_adder_20.v \
    $ROOT/rtl/bw_pp_gen.v \
    $ROOT/rtl/mult8x8_bw.v]
set SDC_FILE  $ROOT/rtl2gds/constraints/$DESIGN.sdc
set OUT_DIR   $ROOT/rtl2gds/outputs
set RPT_DIR   $ROOT/rtl2gds/reports
file mkdir $OUT_DIR $RPT_DIR
