# 8x8 Exact Signed Multiplier (Baugh-Wooley, 4:2 Compressor Tree)

Exact 8x8 signed (two's-complement) multiplier, used as the accuracy baseline
for an approximate-multiplier project (work in progress).

- RTL / simulation guide: this file
- RTL-to-GDS flow (Cadence Genus + Innovus): [rtl2gds/README.md](rtl2gds/README.md)

## Design overview

| Item        | Value                                        |
|-------------|----------------------------------------------|
| Top module  | `mult8x8_bw` (`rtl/mult8x8_bw.v`)            |
| Inputs      | `a[7:0]`, `b[7:0]` signed (two's complement) |
| Output      | `p[15:0]` signed product                     |
| Type        | Purely combinational (no clock, no reset)    |

Block structure:

1. **Partial products** - `rtl/bw_pp_gen.v`. Baugh-Wooley signed partial
   products; the two correction constants (`+2^8`, `+2^15`) are folded into a
   9th constant row (8 PP rows + 1 constant row).
2. **Compressor tree** - `rtl/compressor_4to2.v`, `rtl/compressor_3to2.v`,
   `rtl/full_adder.v`. Nine rows are reduced to two:
   ```
   4:2(row0..row3) -> (S1,C1)    4:2(row4..row7) -> (S2,C2)
   4:2(S1,C1,S2,C2) -> (S3,C3)
   3:2(S3,C3,row_const) -> (final_sum, final_carry)
   ```
3. **Final adder** - `rtl/cla_adder_20.v`, `rtl/cla_4bit.v`. A 20-bit
   carry-lookahead adder; the product is the lower 16 bits (the upper 4 bits
   are guard bits for carry growth).

## Repository layout

```
rtl/        synthesizable Verilog (top = mult8x8_bw)
sim/        testbench (tb_mult8x8_bw.v)
golden/     Python golden model (writes the exhaustive test vectors)
scripts/    run_sim.sh, error_metrics.py
rtl2gds/    Genus + Innovus flow (see rtl2gds/README.md)
```

## Using `mult8x8_bw` as the top module

### 1. Instantiating it in your own design

```verilog
wire signed [7:0]  x, y;
wire signed [15:0] prod;

mult8x8_bw u_mult (.a(x), .b(y), .p(prod));
```

### 2. Compile order

All files under `rtl/` are needed; the order below satisfies tools that are
order-sensitive:

```
rtl/full_adder.v
rtl/compressor_4to2.v
rtl/compressor_3to2.v
rtl/cla_4bit.v
rtl/cla_adder_20.v
rtl/bw_pp_gen.v
rtl/mult8x8_bw.v          <- top
```

### 3. Setting it as the top module in the tools

| Tool                    | How                                                       |
|-------------------------|-----------------------------------------------------------|
| Icarus Verilog          | `iverilog -g2012 -s mult8x8_bw ...`                       |
| Cadence Genus           | `elaborate mult8x8_bw` (see the RTL-to-GDS README)        |
| Cadence Xcelium         | `xrun -top mult8x8_bw <files>`                            |
| Vivado                  | *Set as Top* on `mult8x8_bw`, or `set_property top mult8x8_bw [current_fileset]` |

When simulating, the *testbench* (`tb_mult8x8_bw`) is the simulation top and
`mult8x8_bw` is the design under test. When synthesizing, `mult8x8_bw` itself
is the top.

## Simulation (exhaustive, all 65536 input pairs)

Requirements: `iverilog`, `python3` with `numpy`.

```bash
git clone <this-repo-url>
cd exact-multiplier-8x8
./scripts/run_sim.sh
```

The script:

1. runs `golden/golden_model.py` to write `golden/vectors.txt`
   (`<a_hex> <b_hex> <expected_hex>` for every signed 8-bit pair),
2. compiles the RTL and `sim/tb_mult8x8_bw.v` with Icarus Verilog,
3. runs the simulation; the testbench compares every output to the golden
   value and dumps raw DUT output to `sim/results.txt`,
4. runs `scripts/error_metrics.py` to compute ER / MED / NMED from the raw
   output. For this exact design all error metrics are 0.

Expected output ends with:

```
Total vectors tested : 65536
Mismatches           : 0
RESULT: PASS - 100% match across all 65536 vectors
```

Run the simulation from the repository root, since the testbench opens
`golden/vectors.txt` and `sim/results.txt` with relative paths. The generated
files are git-ignored.

## Next steps

This exact multiplier is the reference. The approximate variants will reuse
the same testbench and `error_metrics.py` flow, where `got != expected` is
expected and the interesting quantity is how large the error is.
