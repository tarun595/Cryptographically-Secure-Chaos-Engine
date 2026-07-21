AES-256 Verilog Project (14-round core)
========================================

FILES (in the order they build on each other)
-----------------------------------------------
1. rotate_shift.v   - rotr32 (right rotate) and shr32 (right shift), 32-bit
                       generic building blocks (used for the Sigma module).
2. xor_ops.v        - xor2_32 and xor3_32, generic 2/3-input XOR modules.
3. sigma.v          - Sigma(w1,w2,w3,p1,p2,p3) =
                         (w1 rrot p1) xor (w2 rrot p2) xor (w3 rshift p3)
                       Built purely from rotate_shift.v + xor_ops.v.
                       (Not part of the AES datapath -- a separate general
                       building block, as requested.)

4. sbox.v           - AES S-box. Splits the 8-bit input into row/col
                       nibbles and looks the value up in a 16x16 grid.
5. multiply.v       - GF(2^8) multiply-by-1/2/3 (xtime based), used by
                       MixColumns.
6. shift_rows.v     - Cyclic left-shift of one 32-bit "row" (4 bytes taken
                       from across the 4 columns) by 0-3 bytes.
7. mix_columns.v    - Multiplies one 32-bit "column" (4 bytes) by the
                       standard AES MixColumns matrix, built from multiply.v.
8. add_round_key.v  - 128-bit XOR of state with the round key.
9. key_expansion.v  - AES-256 key schedule. Takes the 256-bit cipher key
                       and produces all 15 round keys (round 0 .. round 14)
                       as one flat 1920-bit bus.
10. aes_round.v     - One full round = SubBytes -> ShiftRows -> MixColumns
                       -> AddRoundKey. Has a "skip_mixcolumns" input used
                       for the final (14th) round, which has no MixColumns.
11. aes_top.v       - Top level. Contains the FSM that LOOPS through a
                       single shared aes_round instance 14 times (round
                       counter 1..14), plus the initial AddRoundKey (round 0)
                       before the loop starts.
12. tb_aes_top.v    - Testbench. Feeds in the official NIST FIPS-197
                       (Appendix C.3) AES-256 test vector and checks the
                       output ciphertext against the known correct answer.

TEST VECTOR USED (NIST FIPS-197, Appendix C.3)
-----------------------------------------------
Key        : 000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
Plaintext  : 00112233445566778899aabbccddeeff
Ciphertext : 8ea2b7ca516745bfeafc49904b496089

This has been verified in simulation (Icarus Verilog) -- the testbench
prints "TEST PASSED" when it matches.

HOW TO RUN IN VIVADO
-----------------------------------------------
1. Create a new RTL project in Vivado.
2. Add ALL the .v files above (1-11) as DESIGN SOURCES.
   (Do NOT add tb_aes_top.v as a design source.)
3. Add tb_aes_top.v as a SIMULATION SOURCE.
4. Set aes_top as the top module for synthesis/implementation.
5. Set tb_aes_top as the top module for simulation.
6. Run Behavioral Simulation. You should see in the Tcl console:
       TEST PASSED: ciphertext = 8ea2b7ca516745bfeafc49904b496089
7. To use the core standalone:
   - Drive plaintext (128-bit) and cipher_key (256-bit)
   - Pulse 'start' high for one clock cycle
   - Wait for 'done' to go high
   - Read 'ciphertext' (128-bit)

NOTES / HOW THE STATE IS LAID OUT
-----------------------------------------------
- The 128-bit AES state is stored column-major (as in the FIPS-197 spec):
    state[127:96] = column 0 (bytes = row0,row1,row2,row3 top to bottom)
    state[95:64]  = column 1
    state[63:32]  = column 2
    state[31:0]   = column 3
- Round keys are stored the same way (128 bits each), packed into one
  1920-bit bus by key_expansion.v (round key 0 = MSB side, round key 14 =
  LSB side).

WHAT'S STILL A "TODO" IF YOU WANT TO EXTEND THIS
-----------------------------------------------
- Decryption path (InvSubBytes, InvShiftRows, InvMixColumns, key schedule
  used in reverse) is NOT included -- only encryption.
- key_expansion.v is written as a big combinational block (easy to read,
  easy to verify) rather than pipelined; for a tighter FPGA implementation
  you may want to register it or compute it in stages.
- No AXI / memory-mapped wrapper is included -- aes_top is a plain
  start/done handshake core, connect it to whatever bus/interface you need.
