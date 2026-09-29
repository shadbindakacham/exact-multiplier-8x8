#!/usr/bin/env python3
"""
Golden reference model for the 8x8 signed Baugh-Wooley multiplier.

Exhaustively enumerates all 256 x 256 = 65536 signed 8-bit input pairs,
computes the trivial a*b product with NumPy, and writes a vector file
consumed by the Verilog testbench (sim/tb_mult8x8_bw.v):

    <a_bits_hex> <b_bits_hex> <expected_product_hex>

a_bits/b_bits are the raw 8-bit two's-complement bit patterns (0x00-0xff);
expected_product is the 16-bit two's-complement bit pattern of signed(a)*signed(b).
"""
import numpy as np
from pathlib import Path

OUT_PATH = Path(__file__).parent / "vectors.txt"


def main():
    # All 8-bit bit patterns, interpreted as signed int8.
    bits = np.arange(256, dtype=np.uint8)
    signed_vals = bits.astype(np.int8)  # -128..127

    a_bits, b_bits = np.meshgrid(bits, bits, indexing="ij")
    a_vals, b_vals = np.meshgrid(signed_vals, signed_vals, indexing="ij")

    # Widen before multiplying so int8*int8 doesn't overflow/wrap in NumPy.
    product = a_vals.astype(np.int32) * b_vals.astype(np.int32)

    # 16-bit two's-complement bit pattern of the (always in-range) product.
    product_bits = (product.astype(np.int64) & 0xFFFF).astype(np.uint16)

    a_flat = a_bits.reshape(-1)
    b_flat = b_bits.reshape(-1)
    p_flat = product_bits.reshape(-1)

    with open(OUT_PATH, "w") as f:
        for a, b, p in zip(a_flat, b_flat, p_flat):
            f.write(f"{a:02x} {b:02x} {p:04x}\n")

    print(f"Wrote {len(a_flat)} vectors to {OUT_PATH}")
    assert len(a_flat) == 65536


if __name__ == "__main__":
    main()
