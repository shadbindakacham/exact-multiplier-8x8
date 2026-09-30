#!/usr/bin/env bash
# Regenerate golden vectors, run the exhaustive 65536-vector simulation (writes
# sim/results.csv) and cross-check the CSV against the Python golden model.
# Usage: ./scripts/run_sim.sh   (run from anywhere; cds into the project root)
set -euo pipefail
cd "$(dirname "$0")/.."

python3 golden/golden_model.py

iverilog -g2012 -Wall -o sim/mult8x8_bw.vvp \
  rtl/full_adder.v \
  rtl/compressor_4to2.v \
  rtl/compressor_3to2.v \
  rtl/cla_4bit.v \
  rtl/cla_adder_20.v \
  rtl/bw_pp_gen.v \
  rtl/mult8x8_bw.v \
  sim/TB_mult8x8_bw.v

vvp sim/mult8x8_bw.vvp

python3 scripts/error_metrics.py
