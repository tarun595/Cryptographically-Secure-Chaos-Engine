// aes_round.v
// -----------------------------------------------------------------------
// One AES round = SubBytes -> ShiftRows -> MixColumns -> AddRoundKey
//
// State convention (matches FIPS-197):
//   128-bit state = 4 columns of 4 bytes each, column-major.
//   state_in[127:96] = column 0 (bytes row0,row1,row2,row3 top->bottom)
//   state_in[95:64]  = column 1
//   state_in[63:32]  = column 2
//   state_in[31:0]   = column 3
//
// skip_mixcolumns = 1 for the FINAL round (round 14), which does NOT
// perform MixColumns.
// -----------------------------------------------------------------------

module aes_round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    input  wire         skip_mixcolumns,
    output wire [127:0] state_out
);

    // -----------------------------------------------------------
    // Step 1: SubBytes -- apply S-box to all 16 bytes independently
    // -----------------------------------------------------------
    wire [127:0] after_subbytes;
    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : SUBBYTES
            sbox u_sbox (
                .in_byte (state_in[127 - gi*8 -: 8]),
                .out_byte(after_subbytes[127 - gi*8 -: 8])
            );
        end
    endgenerate

    // -----------------------------------------------------------
    // Step 2: ShiftRows -- regroup bytes into rows, shift, regroup back
    //   byte index i (0..15): column = i/4, row = i%4
    //   row r (across the 4 columns) = bytes {r, r+4, r+8, r+12}
    // -----------------------------------------------------------
    wire [7:0] sb [0:15];
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : SLICE_BYTES
            assign sb[gi] = after_subbytes[127 - gi*8 -: 8];
        end
    endgenerate

    wire [31:0] row0_in = {sb[0],  sb[4],  sb[8],  sb[12]};
    wire [31:0] row1_in = {sb[1],  sb[5],  sb[9],  sb[13]};
    wire [31:0] row2_in = {sb[2],  sb[6],  sb[10], sb[14]};
    wire [31:0] row3_in = {sb[3],  sb[7],  sb[11], sb[15]};

    wire [31:0] row0_out, row1_out, row2_out, row3_out;

    shift_rows u_row0 (.row_in(row0_in), .row_sel(2'd0), .row_out(row0_out));
    shift_rows u_row1 (.row_in(row1_in), .row_sel(2'd1), .row_out(row1_out));
    shift_rows u_row2 (.row_in(row2_in), .row_sel(2'd2), .row_out(row2_out));
    shift_rows u_row3 (.row_in(row3_in), .row_sel(2'd3), .row_out(row3_out));

    // Regroup rows back into 4 columns (32-bit each)
    wire [31:0] col0_pre_mix = {row0_out[31:24], row1_out[31:24], row2_out[31:24], row3_out[31:24]};
    wire [31:0] col1_pre_mix = {row0_out[23:16], row1_out[23:16], row2_out[23:16], row3_out[23:16]};
    wire [31:0] col2_pre_mix = {row0_out[15:8],  row1_out[15:8],  row2_out[15:8],  row3_out[15:8]};
    wire [31:0] col3_pre_mix = {row0_out[7:0],   row1_out[7:0],   row2_out[7:0],   row3_out[7:0]};

    // -----------------------------------------------------------
    // Step 3: MixColumns (skipped on final round)
    // -----------------------------------------------------------
    wire [31:0] col0_mixed, col1_mixed, col2_mixed, col3_mixed;

    mix_columns u_mc0 (.col_in(col0_pre_mix), .col_out(col0_mixed));
    mix_columns u_mc1 (.col_in(col1_pre_mix), .col_out(col1_mixed));
    mix_columns u_mc2 (.col_in(col2_pre_mix), .col_out(col2_mixed));
    mix_columns u_mc3 (.col_in(col3_pre_mix), .col_out(col3_mixed));

    wire [31:0] col0_final = skip_mixcolumns ? col0_pre_mix : col0_mixed;
    wire [31:0] col1_final = skip_mixcolumns ? col1_pre_mix : col1_mixed;
    wire [31:0] col2_final = skip_mixcolumns ? col2_pre_mix : col2_mixed;
    wire [31:0] col3_final = skip_mixcolumns ? col3_pre_mix : col3_mixed;

    wire [127:0] after_mixcolumns = {col0_final, col1_final, col2_final, col3_final};

    // -----------------------------------------------------------
    // Step 4: AddRoundKey
    // -----------------------------------------------------------
    add_round_key u_ark (
        .state_in (after_mixcolumns),
        .round_key(round_key),
        .state_out(state_out)
    );

endmodule
