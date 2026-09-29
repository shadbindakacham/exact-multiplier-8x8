#!/usr/bin/env python3
"""
Error-metric harness for the 8x8 signed multiplier.

Reads golden/vectors.txt (a, b, expected) and sim/results.txt (a, b, got —
dumped by tb_mult8x8_bw.v for every vector, independent of its own
pass/fail check) and computes, per Liang/Han/Lombardi, "New Metrics for
the Reliability of Approximate and Probabilistic Adders" (IEEE TC 2013,
multiplier_refrences/15_*.pdf):

  ED   (eq. 24)  |got - expected|, using signed values
  MED  (eq. 26)  mean(ED) over all vectors (uniform input probability)
  NMED (eq. 32)  MED / D, D = max exact output magnitude a multiplier
                 in this design can produce. For signed 8x8, that is
                 (-128)*(-128) = 16384 = 2^14.

ER (error rate) is not from this paper; it's the standard fraction of
mismatching vectors used across the approximate-multiplier papers
(e.g. multiplier_refrences/2_*, 3_*, 5_*, 8_*.pdf).

For the exact multiplier, ER/MED/NMED must all be exactly 0 - that's
the point of running this now: it validates the metric harness itself
before it's pointed at the approximate variant, where these numbers
will actually be nonzero and meaningful.
"""
from pathlib import Path

VECTORS_PATH = Path(__file__).parent.parent / "golden" / "vectors.txt"
RESULTS_PATH = Path(__file__).parent.parent / "sim" / "results.txt"

D = 128 * 128  # max |exact product| for signed 8x8 multiplication (2^14)


def to_signed16(hex_str: str) -> int:
    val = int(hex_str, 16)
    return val - 0x10000 if val & 0x8000 else val


def main():
    expected = {}
    with open(VECTORS_PATH) as f:
        for line in f:
            a, b, exp = line.split()
            expected[(a, b)] = to_signed16(exp)

    total = 0
    errors = 0
    sum_ed = 0

    with open(RESULTS_PATH) as f:
        for line in f:
            a, b, got = line.split()
            got_val = to_signed16(got)
            exp_val = expected[(a, b)]

            ed = abs(got_val - exp_val)
            sum_ed += ed
            if got_val != exp_val:
                errors += 1
            total += 1

    assert total == len(expected), (
        f"results.txt has {total} vectors, golden has {len(expected)} - "
        "did run_sim.sh finish cleanly?"
    )

    er = errors / total
    med = sum_ed / total
    nmed = med / D

    print(f"Vectors compared : {total}")
    print(f"Error rate  (ER) : {er:.6f}  ({errors} / {total} mismatches)")
    print(f"Mean error dist. (MED)  : {med:.6f}")
    print(f"Normalized MED   (NMED) : {nmed:.8f}  (D = {D})")


if __name__ == "__main__":
    main()
