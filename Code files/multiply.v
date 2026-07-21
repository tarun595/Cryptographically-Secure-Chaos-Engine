// multiply.v
// -----------------------------------------------------------------------
// Galois Field GF(2^8) multiplication, used by MixColumns.
// AES MixColumns only ever needs to multiply a byte by 1, 2, or 3.
//
//  - Multiply by 1 : output = input (no change)
//  - Multiply by 2 (xtime) : left shift by 1, and if the original MSB was 1,
//                             XOR the shifted result with 0x1b (irreducible
//                             polynomial reduction)
//  - Multiply by 3 : (multiply by 2) XOR (original input)
//
// mult_sel selects which operation to perform:
//    2'b00 -> multiply by 1
//    2'b01 -> multiply by 2
//    2'b10 -> multiply by 3
// -----------------------------------------------------------------------

module multiply (
    input  wire [7:0] in_byte,
    input  wire [1:0] mult_sel,
    output reg  [7:0] out_byte
);

    // xtime = multiply by 2 in GF(2^8)
    wire [7:0] xtime_result;
    assign xtime_result = in_byte[7] ? ((in_byte << 1) ^ 8'h1b)
                                      : (in_byte << 1);

    always @(*) begin
        case (mult_sel)
            2'b00:   out_byte = in_byte;                    // multiply by 1
            2'b01:   out_byte = xtime_result;                // multiply by 2
            2'b10:   out_byte = xtime_result ^ in_byte;       // multiply by 3
            default: out_byte = 8'h00;
        endcase
    end

endmodule
