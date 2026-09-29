`timescale 1ns/1ps

// Classic 4:2 compressor, built from two full adders per bit slice.
//
//   sum1, carry1 = FA(in0[i], in1[i], in2[i])
//   sum,  vcarry = FA(sum1,   in3[i], cin_chain[i])
//   cin_chain[i+1] = carry1          (horizontal chain, independent of cin_chain[i]
//                                      for the carry1 term -> this is what makes a
//                                      4:2 compressor faster than two cascaded FAs)
//
// "carry" (vertical, weight+1) is pre-shifted left by one bit inside this module so
// that downstream stages can add it directly, bit-for-bit, against another WIDTH-bit
// row/sum vector. The carry out of the top bit (weight WIDTH) is dropped; the design
// carries enough guard bits (see mult8x8_bw.v) that this is always zero in practice.
module compressor_4to2 #(
    parameter WIDTH = 20
) (
    input  wire [WIDTH-1:0] in0,
    input  wire [WIDTH-1:0] in1,
    input  wire [WIDTH-1:0] in2,
    input  wire [WIDTH-1:0] in3,
    output wire [WIDTH-1:0] sum,
    output wire [WIDTH-1:0] carry
);
    wire [WIDTH-1:0] sum1;
    wire [WIDTH-1:0] carry1;
    wire [WIDTH-1:0] vcarry;
    wire [WIDTH:0]   cin_chain;

    assign cin_chain[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : BIT_SLICE
            full_adder fa1 (
                .a    (in0[i]),
                .b    (in1[i]),
                .cin  (in2[i]),
                .sum  (sum1[i]),
                .cout (carry1[i])
            );
            full_adder fa2 (
                .a    (sum1[i]),
                .b    (in3[i]),
                .cin  (cin_chain[i]),
                .sum  (sum[i]),
                .cout (vcarry[i])
            );
            assign cin_chain[i+1] = carry1[i];
        end
    endgenerate

    assign carry = {vcarry[WIDTH-2:0], 1'b0};

endmodule
