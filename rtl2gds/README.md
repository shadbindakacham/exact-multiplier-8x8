# RTL-to-GDS Flow: 8x8 Exact Multiplier (Cadence Genus + Innovus)

Complete flow for taking the multiplier (top module `mult8x8_bw`) from RTL to a
GDSII layout:

```
RTL (Verilog) --Genus--> gate-level netlist + SDC --Innovus--> placed & routed design --> GDSII
```

RTL and simulation details are in the [top-level README](../README.md).

## 0. Before you start

You need:

- Cadence **Genus** and **Innovus** available in your shell (`which genus innovus`).
- A technology kit for your node: `.lib` timing libraries, tech LEF + std-cell
  LEF, a QRC tech file (for RC extraction), a GDS layer map, and the std-cell
  GDS.
- The RTL verified first with `./scripts/run_sim.sh` (must report PASS).

The scripts in this folder are **templates**. The technology paths in
`scripts/setup.tcl` are placeholders - edit them for your PDK (see step 1).
Command names follow recent Innovus/Genus releases; if your version rejects a
command, check its documentation for the equivalent.

```
rtl2gds/
  constraints/mult8x8_bw.sdc     timing constraints (virtual clock)
  scripts/setup.tcl              shared settings: PDK paths, file list, top name
  scripts/genus_synth.tcl        Genus synthesis script
  scripts/innovus_pnr.tcl        Innovus place & route + GDS export
  work/                          run the tools from here (logs land here)
  outputs/  reports/             created by the scripts
```

## 1. Configure

Edit `scripts/setup.tcl` and set:

| Variable          | Meaning                                              |
|-------------------|------------------------------------------------------|
| `LIB_DIRS`, `LIB_FILES` | Liberty (`.lib`) directory and files           |
| `LEF_FILES`       | Tech LEF first, then standard-cell LEF               |
| `QRC_TECH`        | QRC tech file for parasitic extraction               |
| `GDS_MAP`         | Innovus stream-out layer map                         |
| `STDCELL_GDS`     | Std-cell GDS merged into the final layout            |
| `FILLER_CELLS`    | Filler cell names from your library                  |
| `POWER_NET` / `GROUND_NET` | Usually `VDD` / `VSS`                       |
| `CORE_MET_H` / `CORE_MET_V` | Metal layers for the power ring/stripes    |

The design is combinational, so `constraints/mult8x8_bw.sdc` uses a **virtual
clock** to bound the input-to-output path. Change `CLK_PERIOD` (ns) to try
different speed targets.

## 2. Synthesis in Genus (RTL -> netlist)

```bash
cd rtl2gds/work
genus -f ../scripts/genus_synth.tcl | tee genus.log
```

What the script does:

1. Sets library search paths and reads the `.lib` files.
2. `read_hdl` on all files in `rtl/`.
3. `elaborate mult8x8_bw` - **this makes `mult8x8_bw` the top module**.
4. `check_design -unresolved` - must show no unresolved references.
5. `read_sdc` for the constraints.
6. `syn_generic` -> `syn_map` -> `syn_opt`.
7. Writes reports (`timing`, `area`, `power`, `gates`) to `rtl2gds/reports/`.
8. Writes the mapped netlist and SDC to `rtl2gds/outputs/`:
   `mult8x8_bw_netlist.v`, `mult8x8_bw_netlist.sdc`.

Check before moving on: slack in `reports/mult8x8_bw_timing.rpt` is >= 0, and
the netlist exists. To run interactively instead, start `genus`, then
`source ../scripts/genus_synth.tcl` (remove the final `exit` first if you
want to stay in the shell).

## 3. Place and route in Innovus (netlist -> GDS)

```bash
cd rtl2gds/work
innovus -files ../scripts/innovus_pnr.tcl | tee innovus.log
```

To follow along in the GUI, launch `innovus` and run
`source ../scripts/innovus_pnr.tcl` (remove the final `exit` to stay open).

Steps performed:

| Step | Command(s)                                   | Purpose                                   |
|------|----------------------------------------------|-------------------------------------------|
| 1 | `init_design` (with MMMC file)                  | Load netlist, LEFs, libs, SDC             |
| 2 | `floorPlan -site core -r 1.0 0.70 5 5 5 5`      | Square core, 70% utilisation, 5 um margin |
| 3 | `globalNetConnect`                              | Connect VDD/VSS to cell power pins        |
| 4 | `addRing`, `addStripe`, `sroute`                | Power ring, stripes, standard-cell rails  |
| 5 | `editPin`                                       | Inputs `a`,`b` left; output `p` right     |
| 6 | `place_opt_design`                              | Placement + pre-route optimisation        |
| 7 | *(CTS skipped)*                                 | No clock net in a combinational block     |
| 8 | `routeDesign`, `optDesign -postRoute`           | Detailed routing + setup/hold fixing      |
| 9 | `addFiller`                                     | Fill empty row space                      |
| 10 | `verify_drc`, `verifyConnectivity`, `verifyGeometry` | Layout checks                       |
| 11 | `streamOut`                                    | Write GDSII (merging std-cell GDS)        |

Outputs in `rtl2gds/outputs/`:

- `mult8x8_bw.gds` - final layout
- `mult8x8_bw_pnr.v` - post-layout netlist
- `mult8x8_bw.spef`, `mult8x8_bw.sdf` - parasitics / delays for post-layout simulation
- `mult8x8_bw.enc` - saved Innovus database (reopen with `restoreDesign`)

Reports in `rtl2gds/reports/`: post-route timing, area, power, DRC,
connectivity, geometry.

## 4. Sign-off checklist

- [ ] Genus: no unresolved modules, timing slack >= 0
- [ ] Innovus: DRC and connectivity reports show 0 violations
- [ ] Post-route timing slack >= 0 (setup and hold)
- [ ] GDS opens in your layout viewer (Innovus `streamIn`, KLayout, or Virtuoso)
- [ ] (Optional) Post-layout simulation of `mult8x8_bw_pnr.v` with the SDF against
      the same testbench
- [ ] (Optional) Formal/physical sign-off (LVS/DRC in Calibre or Pegasus) if your
      course/tapeout flow requires it

## 5. Common issues

| Symptom                                    | Likely cause / fix                                       |
|--------------------------------------------|----------------------------------------------------------|
| `elaborate` cannot find `mult8x8_bw`       | A file is missing from `RTL_FILES` in `setup.tcl`        |
| Genus reports unresolved `full_adder` etc. | Same as above - all files in `rtl/` must be read         |
| Negative slack                             | Relax `CLK_PERIOD` in the SDC, or raise synthesis effort |
| Innovus cannot find cell/layer names       | `LEF_FILES` order (tech LEF first) or wrong metal names in `setup.tcl` |
| No/incorrect GDS layers                    | Wrong `GDS_MAP` for your PDK                             |
| Power-ring/stripe errors                   | `CORE_MET_H`/`CORE_MET_V` do not match your top metals   |

## 6. Re-running from scratch

```bash
rm -rf rtl2gds/outputs rtl2gds/reports rtl2gds/work/*
```

(Keep `rtl2gds/work/.gitkeep`.)
