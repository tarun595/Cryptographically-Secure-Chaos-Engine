// rotate_shift.v
// -----------------------------------------------------------------------
// Two simple 32-bit building block modules:
//   1) rotr32  -> Right ROTATE by 'amt' bits   (bits wrap around)
//   2) shr32   -> Right SHIFT  by 'amt' bits   (zeros shifted in)
// 'amt' is a 5-bit parameter -> supports shift/rotate amounts 0-31
// -----------------------------------------------------------------------

module rotr32 (
    input  wire [31:0] w_in,   // 32-bit input word
    input  wire [4:0]  amt,    // number of bits to rotate (0-31)
    output wire [31:0] w_out   // 32-bit rotated output
);
    // Right rotate: bits that fall off the right come back in on the left.
    // Guard amt==0 separately because shifting left by 32 is not well
    // defined for a 32-bit value in some simulators/synthesis tools.
    assign w_out = (amt == 5'd0) ? w_in
                                 : (w_in >> amt) | (w_in << (6'd32 - amt));

endmodule


module shr32 (
    input  wire [31:0] w_in,   // 32-bit input word
    input  wire [4:0]  amt,    // number of bits to shift (0-31)
    output wire [31:0] w_out   // 32-bit shifted output (zero filled)
);
    // Simple logical right shift, zeros come in from the left
    assign w_out = w_in >> amt;

endmodule
