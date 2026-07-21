// sbox.v
// -----------------------------------------------------------------------
// AES S-Box (SubBytes lookup table)
// Splits the 8-bit input into two 4-bit nibbles:
//    row = upper nibble (bits 7:4)
//    col = lower nibble (bits 3:0)
// and returns the value stored in the standard 16x16 AES S-box grid.
// -----------------------------------------------------------------------

module sbox (
    input  wire [7:0] in_byte,
    output reg  [7:0] out_byte
);

    wire [3:0] row = in_byte[7:4];
    wire [3:0] col = in_byte[3:0];

    // 16 x 16 grid, exactly like the AES S-box table
    reg [7:0] sbox_grid [0:15][0:15];

    integer i, j;
    initial begin
        // Row 0x0
        sbox_grid[0][0]=8'h63; sbox_grid[0][1]=8'h7c; sbox_grid[0][2]=8'h77; sbox_grid[0][3]=8'h7b;
        sbox_grid[0][4]=8'hf2; sbox_grid[0][5]=8'h6b; sbox_grid[0][6]=8'h6f; sbox_grid[0][7]=8'hc5;
        sbox_grid[0][8]=8'h30; sbox_grid[0][9]=8'h01; sbox_grid[0][10]=8'h67; sbox_grid[0][11]=8'h2b;
        sbox_grid[0][12]=8'hfe; sbox_grid[0][13]=8'hd7; sbox_grid[0][14]=8'hab; sbox_grid[0][15]=8'h76;
        // Row 0x1
        sbox_grid[1][0]=8'hca; sbox_grid[1][1]=8'h82; sbox_grid[1][2]=8'hc9; sbox_grid[1][3]=8'h7d;
        sbox_grid[1][4]=8'hfa; sbox_grid[1][5]=8'h59; sbox_grid[1][6]=8'h47; sbox_grid[1][7]=8'hf0;
        sbox_grid[1][8]=8'had; sbox_grid[1][9]=8'hd4; sbox_grid[1][10]=8'ha2; sbox_grid[1][11]=8'haf;
        sbox_grid[1][12]=8'h9c; sbox_grid[1][13]=8'ha4; sbox_grid[1][14]=8'h72; sbox_grid[1][15]=8'hc0;
        // Row 0x2
        sbox_grid[2][0]=8'hb7; sbox_grid[2][1]=8'hfd; sbox_grid[2][2]=8'h93; sbox_grid[2][3]=8'h26;
        sbox_grid[2][4]=8'h36; sbox_grid[2][5]=8'h3f; sbox_grid[2][6]=8'hf7; sbox_grid[2][7]=8'hcc;
        sbox_grid[2][8]=8'h34; sbox_grid[2][9]=8'ha5; sbox_grid[2][10]=8'he5; sbox_grid[2][11]=8'hf1;
        sbox_grid[2][12]=8'h71; sbox_grid[2][13]=8'hd8; sbox_grid[2][14]=8'h31; sbox_grid[2][15]=8'h15;
        // Row 0x3
        sbox_grid[3][0]=8'h04; sbox_grid[3][1]=8'hc7; sbox_grid[3][2]=8'h23; sbox_grid[3][3]=8'hc3;
        sbox_grid[3][4]=8'h18; sbox_grid[3][5]=8'h96; sbox_grid[3][6]=8'h05; sbox_grid[3][7]=8'h9a;
        sbox_grid[3][8]=8'h07; sbox_grid[3][9]=8'h12; sbox_grid[3][10]=8'h80; sbox_grid[3][11]=8'he2;
        sbox_grid[3][12]=8'heb; sbox_grid[3][13]=8'h27; sbox_grid[3][14]=8'hb2; sbox_grid[3][15]=8'h75;
        // Row 0x4
        sbox_grid[4][0]=8'h09; sbox_grid[4][1]=8'h83; sbox_grid[4][2]=8'h2c; sbox_grid[4][3]=8'h1a;
        sbox_grid[4][4]=8'h1b; sbox_grid[4][5]=8'h6e; sbox_grid[4][6]=8'h5a; sbox_grid[4][7]=8'ha0;
        sbox_grid[4][8]=8'h52; sbox_grid[4][9]=8'h3b; sbox_grid[4][10]=8'hd6; sbox_grid[4][11]=8'hb3;
        sbox_grid[4][12]=8'h29; sbox_grid[4][13]=8'he3; sbox_grid[4][14]=8'h2f; sbox_grid[4][15]=8'h84;
        // Row 0x5
        sbox_grid[5][0]=8'h53; sbox_grid[5][1]=8'hd1; sbox_grid[5][2]=8'h00; sbox_grid[5][3]=8'hed;
        sbox_grid[5][4]=8'h20; sbox_grid[5][5]=8'hfc; sbox_grid[5][6]=8'hb1; sbox_grid[5][7]=8'h5b;
        sbox_grid[5][8]=8'h6a; sbox_grid[5][9]=8'hcb; sbox_grid[5][10]=8'hbe; sbox_grid[5][11]=8'h39;
        sbox_grid[5][12]=8'h4a; sbox_grid[5][13]=8'h4c; sbox_grid[5][14]=8'h58; sbox_grid[5][15]=8'hcf;
        // Row 0x6
        sbox_grid[6][0]=8'hd0; sbox_grid[6][1]=8'hef; sbox_grid[6][2]=8'haa; sbox_grid[6][3]=8'hfb;
        sbox_grid[6][4]=8'h43; sbox_grid[6][5]=8'h4d; sbox_grid[6][6]=8'h33; sbox_grid[6][7]=8'h85;
        sbox_grid[6][8]=8'h45; sbox_grid[6][9]=8'hf9; sbox_grid[6][10]=8'h02; sbox_grid[6][11]=8'h7f;
        sbox_grid[6][12]=8'h50; sbox_grid[6][13]=8'h3c; sbox_grid[6][14]=8'h9f; sbox_grid[6][15]=8'ha8;
        // Row 0x7
        sbox_grid[7][0]=8'h51; sbox_grid[7][1]=8'ha3; sbox_grid[7][2]=8'h40; sbox_grid[7][3]=8'h8f;
        sbox_grid[7][4]=8'h92; sbox_grid[7][5]=8'h9d; sbox_grid[7][6]=8'h38; sbox_grid[7][7]=8'hf5;
        sbox_grid[7][8]=8'hbc; sbox_grid[7][9]=8'hb6; sbox_grid[7][10]=8'hda; sbox_grid[7][11]=8'h21;
        sbox_grid[7][12]=8'h10; sbox_grid[7][13]=8'hff; sbox_grid[7][14]=8'hf3; sbox_grid[7][15]=8'hd2;
        // Row 0x8
        sbox_grid[8][0]=8'hcd; sbox_grid[8][1]=8'h0c; sbox_grid[8][2]=8'h13; sbox_grid[8][3]=8'hec;
        sbox_grid[8][4]=8'h5f; sbox_grid[8][5]=8'h97; sbox_grid[8][6]=8'h44; sbox_grid[8][7]=8'h17;
        sbox_grid[8][8]=8'hc4; sbox_grid[8][9]=8'ha7; sbox_grid[8][10]=8'h7e; sbox_grid[8][11]=8'h3d;
        sbox_grid[8][12]=8'h64; sbox_grid[8][13]=8'h5d; sbox_grid[8][14]=8'h19; sbox_grid[8][15]=8'h73;
        // Row 0x9
        sbox_grid[9][0]=8'h60; sbox_grid[9][1]=8'h81; sbox_grid[9][2]=8'h4f; sbox_grid[9][3]=8'hdc;
        sbox_grid[9][4]=8'h22; sbox_grid[9][5]=8'h2a; sbox_grid[9][6]=8'h90; sbox_grid[9][7]=8'h88;
        sbox_grid[9][8]=8'h46; sbox_grid[9][9]=8'hee; sbox_grid[9][10]=8'hb8; sbox_grid[9][11]=8'h14;
        sbox_grid[9][12]=8'hde; sbox_grid[9][13]=8'h5e; sbox_grid[9][14]=8'h0b; sbox_grid[9][15]=8'hdb;
        // Row 0xA
        sbox_grid[10][0]=8'he0; sbox_grid[10][1]=8'h32; sbox_grid[10][2]=8'h3a; sbox_grid[10][3]=8'h0a;
        sbox_grid[10][4]=8'h49; sbox_grid[10][5]=8'h06; sbox_grid[10][6]=8'h24; sbox_grid[10][7]=8'h5c;
        sbox_grid[10][8]=8'hc2; sbox_grid[10][9]=8'hd3; sbox_grid[10][10]=8'hac; sbox_grid[10][11]=8'h62;
        sbox_grid[10][12]=8'h91; sbox_grid[10][13]=8'h95; sbox_grid[10][14]=8'he4; sbox_grid[10][15]=8'h79;
        // Row 0xB
        sbox_grid[11][0]=8'he7; sbox_grid[11][1]=8'hc8; sbox_grid[11][2]=8'h37; sbox_grid[11][3]=8'h6d;
        sbox_grid[11][4]=8'h8d; sbox_grid[11][5]=8'hd5; sbox_grid[11][6]=8'h4e; sbox_grid[11][7]=8'ha9;
        sbox_grid[11][8]=8'h6c; sbox_grid[11][9]=8'h56; sbox_grid[11][10]=8'hf4; sbox_grid[11][11]=8'hea;
        sbox_grid[11][12]=8'h65; sbox_grid[11][13]=8'h7a; sbox_grid[11][14]=8'hae; sbox_grid[11][15]=8'h08;
        // Row 0xC
        sbox_grid[12][0]=8'hba; sbox_grid[12][1]=8'h78; sbox_grid[12][2]=8'h25; sbox_grid[12][3]=8'h2e;
        sbox_grid[12][4]=8'h1c; sbox_grid[12][5]=8'ha6; sbox_grid[12][6]=8'hb4; sbox_grid[12][7]=8'hc6;
        sbox_grid[12][8]=8'he8; sbox_grid[12][9]=8'hdd; sbox_grid[12][10]=8'h74; sbox_grid[12][11]=8'h1f;
        sbox_grid[12][12]=8'h4b; sbox_grid[12][13]=8'hbd; sbox_grid[12][14]=8'h8b; sbox_grid[12][15]=8'h8a;
        // Row 0xD
        sbox_grid[13][0]=8'h70; sbox_grid[13][1]=8'h3e; sbox_grid[13][2]=8'hb5; sbox_grid[13][3]=8'h66;
        sbox_grid[13][4]=8'h48; sbox_grid[13][5]=8'h03; sbox_grid[13][6]=8'hf6; sbox_grid[13][7]=8'h0e;
        sbox_grid[13][8]=8'h61; sbox_grid[13][9]=8'h35; sbox_grid[13][10]=8'h57; sbox_grid[13][11]=8'hb9;
        sbox_grid[13][12]=8'h86; sbox_grid[13][13]=8'hc1; sbox_grid[13][14]=8'h1d; sbox_grid[13][15]=8'h9e;
        // Row 0xE
        sbox_grid[14][0]=8'he1; sbox_grid[14][1]=8'hf8; sbox_grid[14][2]=8'h98; sbox_grid[14][3]=8'h11;
        sbox_grid[14][4]=8'h69; sbox_grid[14][5]=8'hd9; sbox_grid[14][6]=8'h8e; sbox_grid[14][7]=8'h94;
        sbox_grid[14][8]=8'h9b; sbox_grid[14][9]=8'h1e; sbox_grid[14][10]=8'h87; sbox_grid[14][11]=8'he9;
        sbox_grid[14][12]=8'hce; sbox_grid[14][13]=8'h55; sbox_grid[14][14]=8'h28; sbox_grid[14][15]=8'hdf;
        // Row 0xF
        sbox_grid[15][0]=8'h8c; sbox_grid[15][1]=8'ha1; sbox_grid[15][2]=8'h89; sbox_grid[15][3]=8'h0d;
        sbox_grid[15][4]=8'hbf; sbox_grid[15][5]=8'he6; sbox_grid[15][6]=8'h42; sbox_grid[15][7]=8'h68;
        sbox_grid[15][8]=8'h41; sbox_grid[15][9]=8'h99; sbox_grid[15][10]=8'h2d; sbox_grid[15][11]=8'h0f;
        sbox_grid[15][12]=8'hb0; sbox_grid[15][13]=8'h54; sbox_grid[15][14]=8'hbb; sbox_grid[15][15]=8'h16;
    end

    always @(*) begin
        out_byte = sbox_grid[row][col];
    end

endmodule
