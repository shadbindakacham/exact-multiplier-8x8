`timescale 1ns/1ps

// 20-bit block carry-lookahead adder: five cla_4bit blocks, lookahead within
// each 4-bit block, carry rippling only between the five blocks. This is the
// final fast carry-propagate adder that merges the compressor tree's last
// sum/carry pair into the final product.
module cla_adder_20 (
    input  wire [19:0] a,
    input  wire [19:0] b,
    input  wire        cin,
    output wire [19:0] sum,
    output wire        cout
);
    wire c1, c2, c3, c4;

    cla_4bit blk0 (.a(a[3:0]),   .b(b[3:0]),   .cin(cin), .sum(sum[3:0]),   .cout(c1));
    cla_4bit blk1 (.a(a[7:4]),   .b(b[7:4]),   .cin(c1),  .sum(sum[7:4]),   .cout(c2));
    cla_4bit blk2 (.a(a[11:8]),  .b(b[11:8]),  .cin(c2),  .sum(sum[11:8]),  .cout(c3));
    cla_4bit blk3 (.a(a[15:12]), .b(b[15:12]), .cin(c3),  .sum(sum[15:12]), .cout(c4));
    cla_4bit blk4 (.a(a[19:16]), .b(b[19:16]), .cin(c4),  .sum(sum[19:16]), .cout(cout));
endmodule
