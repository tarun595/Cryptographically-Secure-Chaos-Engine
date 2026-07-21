// shift_rows.v
// -----------------------------------------------------------------------
// AES ShiftRows step.
// The AES state is a 4x4 byte matrix. Each ROW of that matrix is cyclically
// shifted left by an amount equal to the row's index (row0 -> no shift,
// row1 -> shift 1, row2 -> shift 2, row3 -> shift 3).
//
// Here a "row" is represented as one 32-bit wire made up of 4 bytes:
//   row_in = {byte0, byte1, byte2, byte3}   (byte0 = most significant byte)
//
// row_sel (2-bit parameter) tells the module how many bytes to cyclically
// shift left.
// -----------------------------------------------------------------------

module shift_rows (
    input  wire [31:0] row_in,
    input  wire [1:0]  row_sel,   // 0,1,2,3 -> number of bytes to shift left
    output reg  [31:0] row_out
);

    always @(*) begin
        case (row_sel)
            2'd0: row_out = row_in;                                   // no shift
            2'd1: row_out = {row_in[23:0], row_in[31:24]};            // shift left 1 byte
            2'd2: row_out = {row_in[15:0], row_in[31:16]};            // shift left 2 bytes
            2'd3: row_out = {row_in[7:0],  row_in[31:8]};             // shift left 3 bytes
            default: row_out = row_in;
        endcase
    end

endmodule
