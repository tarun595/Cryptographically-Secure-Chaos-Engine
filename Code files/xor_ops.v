// xor_ops.v
// -----------------------------------------------------------------------
// Simple XOR modules for 32-bit wires.
// xor2_32 : XORs 2 x 32-bit inputs  -> 1 x 32-bit output
// xor3_32 : XORs 3 x 32-bit inputs  -> 1 x 32-bit output  (needed by Sigma)
// -----------------------------------------------------------------------

module xor2_32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] y
);
    assign y = a ^ b;
endmodule


module xor3_32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [31:0] c,
    output wire [31:0] y
);
    assign y = a ^ b ^ c;
endmodule
