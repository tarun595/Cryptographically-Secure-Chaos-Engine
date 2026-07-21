// key_expansion.v
// -----------------------------------------------------------------------
// AES-256 Key Expansion.
//   Nk = 8  (256-bit key = 8 x 32-bit words)
//   Nr = 14 (number of rounds)
//   Total words needed = 4 * (Nr + 1) = 60
//   Total round keys   = Nr + 1 = 15  (round key 0 used before round 1)
//
// Output is a single flat bus containing all 15 round keys, 128 bits each:
//   round_keys_flat[1919:1792] = round key 0
//   round_keys_flat[1791:1664] = round key 1
//   ...
//   round_keys_flat[127:0]     = round key 14
// -----------------------------------------------------------------------

module key_expansion (
    input  wire [255:0]  cipher_key,       // 256-bit AES key
    output wire [1919:0] round_keys_flat   // 15 round keys x 128 bits
);

    localparam NK = 8;
    localparam NR = 14;
    localparam TOTAL_WORDS = 4 * (NR + 1); // 60 words

    reg [31:0] w [0:TOTAL_WORDS-1];
    reg [7:0]  sbox_tbl [0:255];
    reg [7:0]  rcon [1:14];

    integer i;
    reg [31:0] temp;
    reg [31:0] rotated;
    reg [31:0] subbed;

    // ---------------------------------------------------------------
    // Flat AES S-box table (same standard 256-entry AES S-box)
    // ---------------------------------------------------------------
    initial begin
        sbox_tbl[8'h00]=8'h63; sbox_tbl[8'h01]=8'h7c; sbox_tbl[8'h02]=8'h77; sbox_tbl[8'h03]=8'h7b;
        sbox_tbl[8'h04]=8'hf2; sbox_tbl[8'h05]=8'h6b; sbox_tbl[8'h06]=8'h6f; sbox_tbl[8'h07]=8'hc5;
        sbox_tbl[8'h08]=8'h30; sbox_tbl[8'h09]=8'h01; sbox_tbl[8'h0a]=8'h67; sbox_tbl[8'h0b]=8'h2b;
        sbox_tbl[8'h0c]=8'hfe; sbox_tbl[8'h0d]=8'hd7; sbox_tbl[8'h0e]=8'hab; sbox_tbl[8'h0f]=8'h76;
        sbox_tbl[8'h10]=8'hca; sbox_tbl[8'h11]=8'h82; sbox_tbl[8'h12]=8'hc9; sbox_tbl[8'h13]=8'h7d;
        sbox_tbl[8'h14]=8'hfa; sbox_tbl[8'h15]=8'h59; sbox_tbl[8'h16]=8'h47; sbox_tbl[8'h17]=8'hf0;
        sbox_tbl[8'h18]=8'had; sbox_tbl[8'h19]=8'hd4; sbox_tbl[8'h1a]=8'ha2; sbox_tbl[8'h1b]=8'haf;
        sbox_tbl[8'h1c]=8'h9c; sbox_tbl[8'h1d]=8'ha4; sbox_tbl[8'h1e]=8'h72; sbox_tbl[8'h1f]=8'hc0;
        sbox_tbl[8'h20]=8'hb7; sbox_tbl[8'h21]=8'hfd; sbox_tbl[8'h22]=8'h93; sbox_tbl[8'h23]=8'h26;
        sbox_tbl[8'h24]=8'h36; sbox_tbl[8'h25]=8'h3f; sbox_tbl[8'h26]=8'hf7; sbox_tbl[8'h27]=8'hcc;
        sbox_tbl[8'h28]=8'h34; sbox_tbl[8'h29]=8'ha5; sbox_tbl[8'h2a]=8'he5; sbox_tbl[8'h2b]=8'hf1;
        sbox_tbl[8'h2c]=8'h71; sbox_tbl[8'h2d]=8'hd8; sbox_tbl[8'h2e]=8'h31; sbox_tbl[8'h2f]=8'h15;
        sbox_tbl[8'h30]=8'h04; sbox_tbl[8'h31]=8'hc7; sbox_tbl[8'h32]=8'h23; sbox_tbl[8'h33]=8'hc3;
        sbox_tbl[8'h34]=8'h18; sbox_tbl[8'h35]=8'h96; sbox_tbl[8'h36]=8'h05; sbox_tbl[8'h37]=8'h9a;
        sbox_tbl[8'h38]=8'h07; sbox_tbl[8'h39]=8'h12; sbox_tbl[8'h3a]=8'h80; sbox_tbl[8'h3b]=8'he2;
        sbox_tbl[8'h3c]=8'heb; sbox_tbl[8'h3d]=8'h27; sbox_tbl[8'h3e]=8'hb2; sbox_tbl[8'h3f]=8'h75;
        sbox_tbl[8'h40]=8'h09; sbox_tbl[8'h41]=8'h83; sbox_tbl[8'h42]=8'h2c; sbox_tbl[8'h43]=8'h1a;
        sbox_tbl[8'h44]=8'h1b; sbox_tbl[8'h45]=8'h6e; sbox_tbl[8'h46]=8'h5a; sbox_tbl[8'h47]=8'ha0;
        sbox_tbl[8'h48]=8'h52; sbox_tbl[8'h49]=8'h3b; sbox_tbl[8'h4a]=8'hd6; sbox_tbl[8'h4b]=8'hb3;
        sbox_tbl[8'h4c]=8'h29; sbox_tbl[8'h4d]=8'he3; sbox_tbl[8'h4e]=8'h2f; sbox_tbl[8'h4f]=8'h84;
        sbox_tbl[8'h50]=8'h53; sbox_tbl[8'h51]=8'hd1; sbox_tbl[8'h52]=8'h00; sbox_tbl[8'h53]=8'hed;
        sbox_tbl[8'h54]=8'h20; sbox_tbl[8'h55]=8'hfc; sbox_tbl[8'h56]=8'hb1; sbox_tbl[8'h57]=8'h5b;
        sbox_tbl[8'h58]=8'h6a; sbox_tbl[8'h59]=8'hcb; sbox_tbl[8'h5a]=8'hbe; sbox_tbl[8'h5b]=8'h39;
        sbox_tbl[8'h5c]=8'h4a; sbox_tbl[8'h5d]=8'h4c; sbox_tbl[8'h5e]=8'h58; sbox_tbl[8'h5f]=8'hcf;
        sbox_tbl[8'h60]=8'hd0; sbox_tbl[8'h61]=8'hef; sbox_tbl[8'h62]=8'haa; sbox_tbl[8'h63]=8'hfb;
        sbox_tbl[8'h64]=8'h43; sbox_tbl[8'h65]=8'h4d; sbox_tbl[8'h66]=8'h33; sbox_tbl[8'h67]=8'h85;
        sbox_tbl[8'h68]=8'h45; sbox_tbl[8'h69]=8'hf9; sbox_tbl[8'h6a]=8'h02; sbox_tbl[8'h6b]=8'h7f;
        sbox_tbl[8'h6c]=8'h50; sbox_tbl[8'h6d]=8'h3c; sbox_tbl[8'h6e]=8'h9f; sbox_tbl[8'h6f]=8'ha8;
        sbox_tbl[8'h70]=8'h51; sbox_tbl[8'h71]=8'ha3; sbox_tbl[8'h72]=8'h40; sbox_tbl[8'h73]=8'h8f;
        sbox_tbl[8'h74]=8'h92; sbox_tbl[8'h75]=8'h9d; sbox_tbl[8'h76]=8'h38; sbox_tbl[8'h77]=8'hf5;
        sbox_tbl[8'h78]=8'hbc; sbox_tbl[8'h79]=8'hb6; sbox_tbl[8'h7a]=8'hda; sbox_tbl[8'h7b]=8'h21;
        sbox_tbl[8'h7c]=8'h10; sbox_tbl[8'h7d]=8'hff; sbox_tbl[8'h7e]=8'hf3; sbox_tbl[8'h7f]=8'hd2;
        sbox_tbl[8'h80]=8'hcd; sbox_tbl[8'h81]=8'h0c; sbox_tbl[8'h82]=8'h13; sbox_tbl[8'h83]=8'hec;
        sbox_tbl[8'h84]=8'h5f; sbox_tbl[8'h85]=8'h97; sbox_tbl[8'h86]=8'h44; sbox_tbl[8'h87]=8'h17;
        sbox_tbl[8'h88]=8'hc4; sbox_tbl[8'h89]=8'ha7; sbox_tbl[8'h8a]=8'h7e; sbox_tbl[8'h8b]=8'h3d;
        sbox_tbl[8'h8c]=8'h64; sbox_tbl[8'h8d]=8'h5d; sbox_tbl[8'h8e]=8'h19; sbox_tbl[8'h8f]=8'h73;
        sbox_tbl[8'h90]=8'h60; sbox_tbl[8'h91]=8'h81; sbox_tbl[8'h92]=8'h4f; sbox_tbl[8'h93]=8'hdc;
        sbox_tbl[8'h94]=8'h22; sbox_tbl[8'h95]=8'h2a; sbox_tbl[8'h96]=8'h90; sbox_tbl[8'h97]=8'h88;
        sbox_tbl[8'h98]=8'h46; sbox_tbl[8'h99]=8'hee; sbox_tbl[8'h9a]=8'hb8; sbox_tbl[8'h9b]=8'h14;
        sbox_tbl[8'h9c]=8'hde; sbox_tbl[8'h9d]=8'h5e; sbox_tbl[8'h9e]=8'h0b; sbox_tbl[8'h9f]=8'hdb;
        sbox_tbl[8'ha0]=8'he0; sbox_tbl[8'ha1]=8'h32; sbox_tbl[8'ha2]=8'h3a; sbox_tbl[8'ha3]=8'h0a;
        sbox_tbl[8'ha4]=8'h49; sbox_tbl[8'ha5]=8'h06; sbox_tbl[8'ha6]=8'h24; sbox_tbl[8'ha7]=8'h5c;
        sbox_tbl[8'ha8]=8'hc2; sbox_tbl[8'ha9]=8'hd3; sbox_tbl[8'haa]=8'hac; sbox_tbl[8'hab]=8'h62;
        sbox_tbl[8'hac]=8'h91; sbox_tbl[8'had]=8'h95; sbox_tbl[8'hae]=8'he4; sbox_tbl[8'haf]=8'h79;
        sbox_tbl[8'hb0]=8'he7; sbox_tbl[8'hb1]=8'hc8; sbox_tbl[8'hb2]=8'h37; sbox_tbl[8'hb3]=8'h6d;
        sbox_tbl[8'hb4]=8'h8d; sbox_tbl[8'hb5]=8'hd5; sbox_tbl[8'hb6]=8'h4e; sbox_tbl[8'hb7]=8'ha9;
        sbox_tbl[8'hb8]=8'h6c; sbox_tbl[8'hb9]=8'h56; sbox_tbl[8'hba]=8'hf4; sbox_tbl[8'hbb]=8'hea;
        sbox_tbl[8'hbc]=8'h65; sbox_tbl[8'hbd]=8'h7a; sbox_tbl[8'hbe]=8'hae; sbox_tbl[8'hbf]=8'h08;
        sbox_tbl[8'hc0]=8'hba; sbox_tbl[8'hc1]=8'h78; sbox_tbl[8'hc2]=8'h25; sbox_tbl[8'hc3]=8'h2e;
        sbox_tbl[8'hc4]=8'h1c; sbox_tbl[8'hc5]=8'ha6; sbox_tbl[8'hc6]=8'hb4; sbox_tbl[8'hc7]=8'hc6;
        sbox_tbl[8'hc8]=8'he8; sbox_tbl[8'hc9]=8'hdd; sbox_tbl[8'hca]=8'h74; sbox_tbl[8'hcb]=8'h1f;
        sbox_tbl[8'hcc]=8'h4b; sbox_tbl[8'hcd]=8'hbd; sbox_tbl[8'hce]=8'h8b; sbox_tbl[8'hcf]=8'h8a;
        sbox_tbl[8'hd0]=8'h70; sbox_tbl[8'hd1]=8'h3e; sbox_tbl[8'hd2]=8'hb5; sbox_tbl[8'hd3]=8'h66;
        sbox_tbl[8'hd4]=8'h48; sbox_tbl[8'hd5]=8'h03; sbox_tbl[8'hd6]=8'hf6; sbox_tbl[8'hd7]=8'h0e;
        sbox_tbl[8'hd8]=8'h61; sbox_tbl[8'hd9]=8'h35; sbox_tbl[8'hda]=8'h57; sbox_tbl[8'hdb]=8'hb9;
        sbox_tbl[8'hdc]=8'h86; sbox_tbl[8'hdd]=8'hc1; sbox_tbl[8'hde]=8'h1d; sbox_tbl[8'hdf]=8'h9e;
        sbox_tbl[8'he0]=8'he1; sbox_tbl[8'he1]=8'hf8; sbox_tbl[8'he2]=8'h98; sbox_tbl[8'he3]=8'h11;
        sbox_tbl[8'he4]=8'h69; sbox_tbl[8'he5]=8'hd9; sbox_tbl[8'he6]=8'h8e; sbox_tbl[8'he7]=8'h94;
        sbox_tbl[8'he8]=8'h9b; sbox_tbl[8'he9]=8'h1e; sbox_tbl[8'hea]=8'h87; sbox_tbl[8'heb]=8'he9;
        sbox_tbl[8'hec]=8'hce; sbox_tbl[8'hed]=8'h55; sbox_tbl[8'hee]=8'h28; sbox_tbl[8'hef]=8'hdf;
        sbox_tbl[8'hf0]=8'h8c; sbox_tbl[8'hf1]=8'ha1; sbox_tbl[8'hf2]=8'h89; sbox_tbl[8'hf3]=8'h0d;
        sbox_tbl[8'hf4]=8'hbf; sbox_tbl[8'hf5]=8'he6; sbox_tbl[8'hf6]=8'h42; sbox_tbl[8'hf7]=8'h68;
        sbox_tbl[8'hf8]=8'h41; sbox_tbl[8'hf9]=8'h99; sbox_tbl[8'hfa]=8'h2d; sbox_tbl[8'hfb]=8'h0f;
        sbox_tbl[8'hfc]=8'hb0; sbox_tbl[8'hfd]=8'h54; sbox_tbl[8'hfe]=8'hbb; sbox_tbl[8'hff]=8'h16;

        // Standard AES Rcon values (only first byte of each Rcon word; rest = 0)
        rcon[1]=8'h01; rcon[2]=8'h02; rcon[3]=8'h04; rcon[4]=8'h08;
        rcon[5]=8'h10; rcon[6]=8'h20; rcon[7]=8'h40; rcon[8]=8'h80;
        rcon[9]=8'h1b; rcon[10]=8'h36; rcon[11]=8'h6c; rcon[12]=8'hd8;
        rcon[13]=8'hab; rcon[14]=8'h4d;
    end

    // ---------------------------------------------------------------
    // Key expansion algorithm (combinational, recomputed whenever
    // cipher_key changes)
    // ---------------------------------------------------------------
    always @(*) begin
        // First Nk words = the cipher key itself
        w[0] = cipher_key[255:224];
        w[1] = cipher_key[223:192];
        w[2] = cipher_key[191:160];
        w[3] = cipher_key[159:128];
        w[4] = cipher_key[127:96];
        w[5] = cipher_key[95:64];
        w[6] = cipher_key[63:32];
        w[7] = cipher_key[31:0];

        for (i = NK; i < TOTAL_WORDS; i = i + 1) begin
            temp = w[i-1];

            if (i % NK == 0) begin
                // RotWord: rotate left by one byte
                rotated = {temp[23:0], temp[31:24]};
                // SubWord: apply S-box to every byte
                subbed  = { sbox_tbl[rotated[31:24]], sbox_tbl[rotated[23:16]],
                            sbox_tbl[rotated[15:8]],  sbox_tbl[rotated[7:0]] };
                temp = subbed ^ {rcon[i/NK], 24'h000000};
            end
            else if (i % NK == 4) begin
                // AES-256 extra SubWord step
                temp = { sbox_tbl[temp[31:24]], sbox_tbl[temp[23:16]],
                         sbox_tbl[temp[15:8]],  sbox_tbl[temp[7:0]] };
            end

            w[i] = w[i-NK] ^ temp;
        end
    end

    // ---------------------------------------------------------------
    // Pack the 60 words into 15 round keys (128 bits each)
    // ---------------------------------------------------------------
    genvar r;
    generate
        for (r = 0; r <= NR; r = r + 1) begin : PACK_ROUND_KEYS
            assign round_keys_flat[ (1919 - r*128) -: 128 ] =
                   { w[r*4], w[r*4+1], w[r*4+2], w[r*4+3] };
        end
    endgenerate

endmodule
