`timescale 1ns/1ps

// 4-bit carry-lookahead block: all four sum/carry-generate/carry-propagate
// terms are computed directly from a, b and the block's carry-in, so cout
// resolves in one gate-delay-deep lookahead network rather than rippling
// through four full adders.
module cla_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    wire [3:0] g, p;
    wire [4:0] c;

    assign g = a & b;
    assign p = a ^ b;
    assign c[0] = cin;

    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0])
                       | (p[3] & p[2] & p[1] & p[0] & c[0]);

    assign sum  = p ^ c[3:0];
    assign cout = c[4];
endmodule
