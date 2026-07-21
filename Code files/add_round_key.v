// add_round_key.v
// -----------------------------------------------------------------------
// AES AddRoundKey step.
// Simple bitwise XOR of the 128-bit state with the 128-bit round key.
// -----------------------------------------------------------------------

module add_round_key (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);

    assign state_out = state_in ^ round_key;

endmodule
