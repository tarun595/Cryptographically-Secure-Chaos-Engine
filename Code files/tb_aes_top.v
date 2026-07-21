// tb_aes_top.v
// -----------------------------------------------------------------------
// Testbench for aes_top.
// Uses the official NIST FIPS-197 (Appendix C.3) AES-256 test vector:
//
//   Key       : 000102030405060708090a0b0c0d0e0f
//               101112131415161718191a1b1c1d1e1f
//   Plaintext : 00112233445566778899aabbccddeeff
//   Expected  : 8ea2b7ca516745bfeafc49904b496089
// -----------------------------------------------------------------------

`timescale 1ns/1ps

module tb_aes_top;

    reg         clk;
    reg         rst;
    reg         start;
    reg  [127:0] plaintext;
    reg  [255:0] cipher_key;
    wire [127:0] ciphertext;
    wire        done;

    localparam [127:0] EXPECTED_CIPHERTEXT = 128'h8ea2b7ca516745bfeafc49904b496089;

    aes_top DUT (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .plaintext (plaintext),
        .cipher_key(cipher_key),
        .ciphertext(ciphertext),
        .done      (done)
    );

    // 100 MHz clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        // Init
        rst        = 1'b1;
        start      = 1'b0;
        plaintext  = 128'h00112233445566778899aabbccddeeff;
        cipher_key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;

        repeat (2) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        // Pulse start for one cycle
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        // Wait for 'done'
        wait (done == 1'b1);
        @(posedge clk);

        if (ciphertext === EXPECTED_CIPHERTEXT) begin
            $display("TEST PASSED: ciphertext = %h", ciphertext);
        end
        else begin
            $display("TEST FAILED: got %h, expected %h", ciphertext, EXPECTED_CIPHERTEXT);
        end

        #20 $finish;
    end

endmodule
