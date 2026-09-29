`timescale 1ns/1ps

// 3:2 compressor (a plain carry-save adder stage): reduces the final three
// rows coming out of the 4:2 tree down to the last sum/carry pair that feeds
// the final fast adder. Same pre-shifted-carry convention as compressor_4to2.
module compressor_3to2 #(
    parameter WIDTH = 20
) (
    input  wire [WIDTH-1:0] in0,
    input  wire [WIDTH-1:0] in1,
    input  wire [WIDTH-1:0] in2,
    output wire [WIDTH-1:0] sum,
    output wire [WIDTH-1:0] carry
);
    wire [WIDTH-1:0] vcarry;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : BIT_SLICE
            full_adder fa (
                .a    (in0[i]),
                .b    (in1[i]),
                .cin  (in2[i]),
                .sum  (sum[i]),
                .cout (vcarry[i])
            );
        end
    endgenerate

    assign carry = {vcarry[WIDTH-2:0], 1'b0};

endmodule
