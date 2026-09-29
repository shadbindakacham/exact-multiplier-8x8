`timescale 1ns/1ps

// Exhaustive testbench: feeds all 65536 (a,b) 8-bit vectors from
// golden/vectors.txt through the RTL and diffs against the Python/NumPy
// golden model's expected product. Requires a 100% match to PASS.
//
// Also dumps every (a,b,got) triple to sim/results.txt, independently of
// the pass/fail check above, so a Python script can compute ER/MED/NMED
// from the raw DUT output rather than trusting logic embedded here. This
// is the same dump format the approximate-multiplier variant will use,
// where got != expected is normal and the interesting part is *how much*
// it differs.
module tb_mult8x8_bw;

    reg  [7:0]  a, b;
    reg  [15:0] expected;
    wire [15:0] p;

    integer fd, fd_out;
    integer errors;
    integer count;
    integer r;

    mult8x8_bw dut (
        .a(a),
        .b(b),
        .p(p)
    );

    initial begin
        errors = 0;
        count  = 0;

        fd = $fopen("golden/vectors.txt", "r");
        if (fd == 0) begin
            $display("ERROR: could not open golden/vectors.txt (run from the bw_mult8x8/ project root)");
            $finish;
        end

        fd_out = $fopen("sim/results.txt", "w");
        if (fd_out == 0) begin
            $display("ERROR: could not open sim/results.txt for writing");
            $finish;
        end

        while (!$feof(fd)) begin
            r = $fscanf(fd, "%h %h %h\n", a, b, expected);
            if (r == 3) begin
                count = count + 1;
                #1;
                $fdisplay(fd_out, "%02h %02h %04h", a, b, p);
                if (p !== expected) begin
                    errors = errors + 1;
                    if (errors <= 20)
                        $display("MISMATCH  a=%0d b=%0d (a=%02h b=%02h)  got=%04h  exp=%04h",
                                  $signed(a), $signed(b), a, b, p, expected);
                end
            end
        end
        $fclose(fd);
        $fclose(fd_out);

        $display("----------------------------------------------------");
        $display("Total vectors tested : %0d", count);
        $display("Mismatches           : %0d", errors);
        if (errors == 0 && count == 65536)
            $display("RESULT: PASS - 100%% match across all 65536 vectors");
        else
            $display("RESULT: FAIL");
        $display("----------------------------------------------------");

        $finish;
    end

endmodule
