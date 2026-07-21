// mix_columns.v
// -----------------------------------------------------------------------
// AES MixColumns step.
// Takes one COLUMN of the AES state (4 bytes packed into a 32-bit wire)
// and multiplies it by the fixed AES matrix:
//
//      [02 03 01 01]   [b0]
//      [01 02 03 01] x [b1]
//      [01 01 02 03]   [b2]
//      [03 01 01 02]   [b3]
//
// col_in = {b0, b1, b2, b3}  (b0 = most significant byte)
//
// Built entirely by wiring together instances of the "multiply" module
// (multiply by 1/2/3) plus XORs.
// -----------------------------------------------------------------------

module mix_columns (
    input  wire [31:0] col_in,
    output wire [31:0] col_out
);

    wire [7:0] b0 = col_in[31:24];
    wire [7:0] b1 = col_in[23:16];
    wire [7:0] b2 = col_in[15:8];
    wire [7:0] b3 = col_in[7:0];

    // Products needed: 2*b0, 3*b0, 2*b1, 3*b1, 2*b2, 3*b2, 2*b3, 3*b3
    wire [7:0] b0_x2, b0_x3;
    wire [7:0] b1_x2, b1_x3;
    wire [7:0] b2_x2, b2_x3;
    wire [7:0] b3_x2, b3_x3;

    multiply u_b0_x2 (.in_byte(b0), .mult_sel(2'b01), .out_byte(b0_x2));
    multiply u_b0_x3 (.in_byte(b0), .mult_sel(2'b10), .out_byte(b0_x3));

    multiply u_b1_x2 (.in_byte(b1), .mult_sel(2'b01), .out_byte(b1_x2));
    multiply u_b1_x3 (.in_byte(b1), .mult_sel(2'b10), .out_byte(b1_x3));

    multiply u_b2_x2 (.in_byte(b2), .mult_sel(2'b01), .out_byte(b2_x2));
    multiply u_b2_x3 (.in_byte(b2), .mult_sel(2'b10), .out_byte(b2_x3));

    multiply u_b3_x2 (.in_byte(b3), .mult_sel(2'b01), .out_byte(b3_x2));
    multiply u_b3_x3 (.in_byte(b3), .mult_sel(2'b10), .out_byte(b3_x3));

    // o0 = 2*b0 ^ 3*b1 ^ 1*b2 ^ 1*b3
    // o1 = 1*b0 ^ 2*b1 ^ 3*b2 ^ 1*b3
    // o2 = 1*b0 ^ 1*b1 ^ 2*b2 ^ 3*b3
    // o3 = 3*b0 ^ 1*b1 ^ 1*b2 ^ 2*b3
    wire [7:0] o0 = b0_x2 ^ b1_x3 ^ b2    ^ b3;
    wire [7:0] o1 = b0    ^ b1_x2 ^ b2_x3 ^ b3;
    wire [7:0] o2 = b0    ^ b1    ^ b2_x2 ^ b3_x3;
    wire [7:0] o3 = b0_x3 ^ b1    ^ b2    ^ b3_x2;

    assign col_out = {o0, o1, o2, o3};

endmodule
