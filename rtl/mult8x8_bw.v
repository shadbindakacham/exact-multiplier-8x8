`timescale 1ns/1ps

// 8x8 signed (two's-complement) multiplier.
//   - Partial products: Baugh-Wooley construction (bw_pp_gen).
//   - Reduction: 4:2 compressor tree, 9 rows -> 2 rows
//       Level 1: 4:2(row0,row1,row2,row3) -> (c1_sum,c1_carry)
//                4:2(row4,row5,row6,row7) -> (c2_sum,c2_carry)
//       Level 2: 4:2(c1_sum,c1_carry,c2_sum,c2_carry) -> (c3_sum,c3_carry)
//       Level 3: 3:2(c3_sum,c3_carry,row_const) -> (final_sum,final_carry)
//   - Final add: 20-bit carry-lookahead adder, product = lower 16 bits.
module mult8x8_bw (
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output wire [15:0] p
);
    localparam WIDTH = 20;

    wire [WIDTH-1:0] row0, row1, row2, row3, row4, row5, row6, row7, row_const;

    bw_pp_gen pp_gen_inst (
        .a(a), .b(b),
        .row0(row0), .row1(row1), .row2(row2), .row3(row3),
        .row4(row4), .row5(row5), .row6(row6), .row7(row7),
        .row_const(row_const)
    );

    wire [WIDTH-1:0] c1_sum, c1_carry, c2_sum, c2_carry;

    compressor_4to2 #(.WIDTH(WIDTH)) L1_A (
        .in0(row0), .in1(row1), .in2(row2), .in3(row3),
        .sum(c1_sum), .carry(c1_carry)
    );

    compressor_4to2 #(.WIDTH(WIDTH)) L1_B (
        .in0(row4), .in1(row5), .in2(row6), .in3(row7),
        .sum(c2_sum), .carry(c2_carry)
    );

    wire [WIDTH-1:0] c3_sum, c3_carry;

    compressor_4to2 #(.WIDTH(WIDTH)) L2 (
        .in0(c1_sum), .in1(c1_carry), .in2(c2_sum), .in3(c2_carry),
        .sum(c3_sum), .carry(c3_carry)
    );

    wire [WIDTH-1:0] final_sum, final_carry;

    compressor_3to2 #(.WIDTH(WIDTH)) L3 (
        .in0(c3_sum), .in1(c3_carry), .in2(row_const),
        .sum(final_sum), .carry(final_carry)
    );

    wire [WIDTH-1:0] adder_sum;
    wire cout;

    cla_adder_20 final_adder (
        .a(final_sum), .b(final_carry), .cin(1'b0),
        .sum(adder_sum), .cout(cout)
    );

    assign p = adder_sum[15:0];

endmodule
