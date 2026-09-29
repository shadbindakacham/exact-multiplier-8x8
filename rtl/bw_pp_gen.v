`timescale 1ns/1ps

// Baugh-Wooley signed partial-product generator for an 8x8 -> 16-bit
// two's-complement multiplier.
//
// For n=8, two's-complement multiplication a*b expands to:
//
//   P =  sum_{i=0..6} sum_{j=0..6} a[i]b[j] * 2^(i+j)
//      + sum_{i=0..6} ~(a[i]&b[7]) * 2^(i+7)      (row 0..6, sign column j=7 inverted)
//      + sum_{j=0..6} ~(a[7]&b[j]) * 2^(7+j)      (row 7, sign row, inverted)
//      +  (a[7]&b[7]) * 2^14                      (row 7 corner: double negation cancels)
//      +  2^8  +  2^15                            (Baugh-Wooley correction constants)
//
// This module lays out that sum as 8 partial-product rows plus one constant
// row, each zero-padded to a 20-bit vector (16 product bits + 4 guard bits
// for carry growth through the compressor tree). Rows are combined
// downstream by the 4:2/3:2 compressor tree in mult8x8_bw.v.
module bw_pp_gen (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [19:0] row0,
    output wire [19:0] row1,
    output wire [19:0] row2,
    output wire [19:0] row3,
    output wire [19:0] row4,
    output wire [19:0] row5,
    output wire [19:0] row6,
    output wire [19:0] row7,
    output wire [19:0] row_const
);

    wire [7:0] and0 = {8{a[0]}} & b;
    wire [7:0] and1 = {8{a[1]}} & b;
    wire [7:0] and2 = {8{a[2]}} & b;
    wire [7:0] and3 = {8{a[3]}} & b;
    wire [7:0] and4 = {8{a[4]}} & b;
    wire [7:0] and5 = {8{a[5]}} & b;
    wire [7:0] and6 = {8{a[6]}} & b;
    wire [7:0] and7 = {8{a[7]}} & b;

    // Rows 0-6: sign column (bit 7, weight j=7) inverted, rest untouched.
    wire [7:0] sgn0 = {~and0[7], and0[6:0]};
    wire [7:0] sgn1 = {~and1[7], and1[6:0]};
    wire [7:0] sgn2 = {~and2[7], and2[6:0]};
    wire [7:0] sgn3 = {~and3[7], and3[6:0]};
    wire [7:0] sgn4 = {~and4[7], and4[6:0]};
    wire [7:0] sgn5 = {~and5[7], and5[6:0]};
    wire [7:0] sgn6 = {~and6[7], and6[6:0]};

    // Row 7: sign row - all bits inverted EXCEPT the corner (j=7), where the
    // two sign inversions cancel.
    wire [7:0] sgn7 = {and7[7], ~and7[6:0]};

    assign row0 = { {12{1'b0}}, sgn0 };
    assign row1 = { {11{1'b0}}, sgn1, 1'b0 };
    assign row2 = { {10{1'b0}}, sgn2, 2'b0 };
    assign row3 = { {9{1'b0}},  sgn3, 3'b0 };
    assign row4 = { {8{1'b0}},  sgn4, 4'b0 };
    assign row5 = { {7{1'b0}},  sgn5, 5'b0 };
    assign row6 = { {6{1'b0}},  sgn6, 6'b0 };
    assign row7 = { {5{1'b0}},  sgn7, 7'b0 };

    // Correction constants: +2^8 (bit 8) and +2^15 (bit 15).
    assign row_const = {4'b0, 1'b1, 6'b0, 1'b1, 8'b0};

endmodule
