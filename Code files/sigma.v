// sigma.v
// -----------------------------------------------------------------------
// Sigma module (as used in SHA-2 style compression functions)
//
// Output = (w1 rightrotate p1) XOR (w2 rightrotate p2) XOR (w3 rightshift p3)
//
// Built purely by wiring together the smaller blocks:
//   rotr32  x2   -> right rotate w1 by p1, right rotate w2 by p2
//   shr32   x1   -> right shift  w3 by p3
//   xor3_32 x1   -> xor the three results together
// -----------------------------------------------------------------------

module sigma (
    input  wire [31:0] w1,
    input  wire [31:0] w2,
    input  wire [31:0] w3,
    input  wire [4:0]  p1,   // rotate amount for w1
    input  wire [4:0]  p2,   // rotate amount for w2
    input  wire [4:0]  p3,   // shift amount for w3
    output wire [31:0] result
);

    wire [31:0] rot1_out;
    wire [31:0] rot2_out;
    wire [31:0] shr_out;

    // (w1 rightrotate p1)
    rotr32 u_rotr1 (
        .w_in (w1),
        .amt  (p1),
        .w_out(rot1_out)
    );

    // (w2 rightrotate p2)
    rotr32 u_rotr2 (
        .w_in (w2),
        .amt  (p2),
        .w_out(rot2_out)
    );

    // (w3 rightshift p3)
    shr32 u_shr3 (
        .w_in (w3),
        .amt  (p3),
        .w_out(shr_out)
    );

    // XOR all three together
    xor3_32 u_xor3 (
        .a(rot1_out),
        .b(rot2_out),
        .c(shr_out),
        .y(result)
    );

endmodule
