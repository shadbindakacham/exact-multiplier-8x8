`timescale 1ns/1ps

// Exhaustive self-checking testbench for mult8x8_bw (8x8 signed exact multiplier).
//
// Sweeps every one of the 256 x 256 = 65536 signed (a,b) combinations, compares
// the RTL product against the reference $signed(a) * $signed(b), and writes one
// CSV row per combination to sim/results.csv.
//
// Run from the repository root (paths are relative):  ./scripts/run_sim.sh
//
// CSV columns:
//   a_dec, b_dec          signed decimal inputs (-128..127)
//   a_hex, b_hex          raw 8-bit two's-complement patterns
//   rtl_dec, rtl_hex      RTL output p as signed decimal / 16-bit hex
//   expected_dec          reference product
//   error                 rtl_dec - expected_dec
//   status                PASS or FAIL
module TB_mult8x8_bw;

    localparam CSV_PATH = "sim/results.csv";

    reg  [7:0]  a, b;
    wire [15:0] p;

    reg signed [15:0] expected;

    integer i, j;
    integer fd;
    integer total;
    integer errors;

    mult8x8_bw dut (
        .a(a),
        .b(b),
        .p(p)
    );

    initial begin
        total  = 0;
        errors = 0;

        fd = $fopen(CSV_PATH, "w");
        if (fd == 0) begin
            $display("ERROR: could not open %s for writing (run from the repository root)", CSV_PATH);
            $finish;
        end

        $fdisplay(fd, "a_dec,b_dec,a_hex,b_hex,rtl_dec,rtl_hex,expected_dec,error,status");

        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i[7:0];
                b = j[7:0];
                #1;  // let the combinational logic settle

                expected = $signed(a) * $signed(b);
                total = total + 1;

                if (p !== expected[15:0]) begin
                    errors = errors + 1;
                    if (errors <= 20)
                        $display("MISMATCH a=%0d b=%0d  got=%0d  expected=%0d",
                                 $signed(a), $signed(b), $signed(p), expected);
                end

                $fdisplay(fd, "%0d,%0d,%02h,%02h,%0d,%04h,%0d,%0d,%0s",
                          $signed(a), $signed(b), a, b,
                          $signed(p), p, expected,
                          $signed(p) - expected,
                          (p === expected[15:0]) ? "PASS" : "FAIL");
            end
        end

        $fclose(fd);

        $display("----------------------------------------------------");
        $display("Total vectors tested : %0d", total);
        $display("Mismatches           : %0d", errors);
        $display("CSV written to       : %s", CSV_PATH);
        if (errors == 0 && total == 65536)
            $display("RESULT: PASS - 100%% match across all 65536 vectors");
        else
            $display("RESULT: FAIL");
        $display("----------------------------------------------------");

        $finish;
    end

endmodule
