// aes_top.v
// -----------------------------------------------------------------------
// AES-256 top level encryption module.
//   - 128-bit plaintext block
//   - 256-bit cipher key
//   - 14 rounds (Nr = 14 for AES-256), implemented as an FSM that LOOPS
//     through one shared aes_round instance 14 times (not fully unrolled).
//
// Usage:
//   1. Apply plaintext & cipher_key while start = 1 for one clock cycle
//   2. Wait for 'done' to go high
//   3. Read ciphertext
// -----------------------------------------------------------------------

module aes_top (
    input  wire         clk,
    input  wire         rst,          // synchronous, active-high reset
    input  wire         start,        // pulse high for 1 cycle to begin
    input  wire [127:0] plaintext,
    input  wire [255:0] cipher_key,
    output reg  [127:0] ciphertext,
    output reg          done
);

    localparam NR = 14; // number of AES-256 rounds

    // FSM states
    localparam S_IDLE  = 2'd0;
    localparam S_ROUND = 2'd1;
    localparam S_DONE  = 2'd2;

    reg [1:0] state_fsm;
    reg [127:0] state_reg;
    reg [4:0]   round_cnt;   // counts 1 .. 14

    // ---------------------------------------------------------------
    // Key expansion (computes all 15 round keys from the cipher key)
    // ---------------------------------------------------------------
    wire [1919:0] round_keys_flat;
    key_expansion u_key_expansion (
        .cipher_key     (cipher_key),
        .round_keys_flat(round_keys_flat)
    );

    // Helper function-like access: round key r (0..14)
    function [127:0] get_round_key;
        input [4:0] r;
        begin
            get_round_key = round_keys_flat[(1919 - r*128) -: 128];
        end
    endfunction

    // ---------------------------------------------------------------
    // Single shared aes_round instance, reused every clock cycle
    // ---------------------------------------------------------------
    reg  [127:0] round_state_in;
    reg  [127:0] round_key_in;
    reg          skip_mix_in;
    wire [127:0] round_state_out;

    aes_round u_aes_round (
        .state_in       (round_state_in),
        .round_key      (round_key_in),
        .skip_mixcolumns(skip_mix_in),
        .state_out      (round_state_out)
    );

    // ---------------------------------------------------------------
    // Combinational drive of the shared round module based on FSM state
    // ---------------------------------------------------------------
    always @(*) begin
        round_state_in = state_reg;
        round_key_in   = get_round_key(round_cnt);
        skip_mix_in    = (round_cnt == NR) ? 1'b1 : 1'b0; // final round skips MixColumns
    end

    // ---------------------------------------------------------------
    // Main FSM: loops through rounds 1 .. 14 (14 "loops" through aes_round)
    // ---------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state_fsm  <= S_IDLE;
            state_reg  <= 128'd0;
            round_cnt  <= 5'd0;
            done       <= 1'b0;
            ciphertext <= 128'd0;
        end
        else begin
            case (state_fsm)

                S_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        // Initial AddRoundKey (round 0), before round loop begins
                        state_reg <= plaintext ^ get_round_key(5'd0);
                        round_cnt <= 5'd1;
                        state_fsm <= S_ROUND;
                    end
                end

                S_ROUND: begin
                    // Apply one round using the currently selected round key
                    state_reg <= round_state_out;

                    if (round_cnt == NR) begin
                        // Just completed the final (14th) round
                        state_fsm <= S_DONE;
                    end
                    else begin
                        round_cnt <= round_cnt + 1'b1;
                    end
                end

                S_DONE: begin
                    ciphertext <= state_reg;
                    done       <= 1'b1;
                    state_fsm  <= S_IDLE;
                end

                default: state_fsm <= S_IDLE;
            endcase
        end
    end

endmodule
