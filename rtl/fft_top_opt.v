`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/10 11:49:57
// Design Name: 
// Module Name: fft_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fft_top_opt#(
parameter DATA_WIDTH = 16,
parameter RAM_RD_LATENCY = 2,
parameter FFT_IFFT = 0,
parameter MAX_STAGE = 12,// MAX_STAGE>=2
parameter OVERFLOW_PRO = 1
)(
input                               clk,
input                               rst_n,

input                               cfg_vld,
input                               cfg_fft_ifft,
input        [3:0]                  cfg_N,

output                              sig_start_receive_ready_o,
input                               sig_start_i,
input                               sig_vld_i,
input        [DATA_WIDTH-1:0]       sig_real_i,
input        [DATA_WIDTH-1:0]       sig_imag_i,

output                              sig_start_o,
output                              sig_vld_o,
output       [DATA_WIDTH-1:0]       sig_real_o,
output       [DATA_WIDTH-1:0]       sig_imag_o,
output       [MAX_STAGE-1:0]        N_index_o
    );
localparam             ANGEL_PI_4 = 13176794;    
localparam [24*13-1:0] ANGEL_STEP =  {24'd13176794,24'd13176794,24'd6588397,24'd3294198,
                                      24'd1647099, 24'd823549,  24'd411774, 24'd205887,
                                      24'd102943,  24'd51471,   24'd25735,  24'd12867,
                                      24'd6433};
                   
reg                                     stage_sig_start_i  [0:MAX_STAGE-1];
reg                                     stage_sig_vld_i    [0:MAX_STAGE-1];
reg   [DATA_WIDTH-1:0]                  stage_sig_real_i   [0:MAX_STAGE-1];
reg   [DATA_WIDTH-1:0]                  stage_sig_imag_i   [0:MAX_STAGE-1];
wire                                    stage_sig_start_o  [0:MAX_STAGE-1];
wire                                    stage_sig_vld_o    [0:MAX_STAGE-1];
wire  [DATA_WIDTH-1:0]                  stage_sig_real_o   [0:MAX_STAGE-1];
wire  [DATA_WIDTH-1:0]                  stage_sig_imag_o   [0:MAX_STAGE-1];

wire                                    stage_wr_en_o      [0:MAX_STAGE-2];
wire  [MAX_STAGE*(MAX_STAGE-1)/2-1:0]   stage_wr_addr_o                   ;
wire  [DATA_WIDTH*2-1:0]                stage_wr_data_o    [0:MAX_STAGE-2];
wire                                    stage_rd_en_o      [0:MAX_STAGE-2];
wire  [MAX_STAGE*(MAX_STAGE-1)/2-1:0]   stage_rd_addr_o                   ;
wire  [DATA_WIDTH*2-1:0]                stage_rd_data_i    [0:MAX_STAGE-2];

wire  [3:0]                             N_select;
wire                                    state_n_start_o;
wire                                    state_n_vld_o;
wire  [DATA_WIDTH-1:0]                  state_n_real_o;
wire  [DATA_WIDTH-1:0]                  state_n_imag_o;

wire                                    stage_0_sig_start_i;
wire                                    stage_0_sig_vld_i;
wire  [DATA_WIDTH-1:0]                  stage_0_sig_real_i;
wire  [DATA_WIDTH-1:0]                  stage_0_sig_imag_i;

//fft ctrl 
fft_ctrl#(
.DATA_WIDTH             ( DATA_WIDTH                ),
.MAX_STAGE              ( MAX_STAGE                 ),
.FFT_IFFT               ( FFT_IFFT                  ),
.OVERFLOW_PRO           ( OVERFLOW_PRO              )
)fft_ctrl_inst(
.clk                    ( clk                       ),
.rst_n                  ( rst_n                     ),
.cfg_vld                ( cfg_vld                   ),
.cfg_fft_ifft           ( cfg_fft_ifft              ),
.cfg_N                  ( cfg_N                     ),
.sig_start_en_o         ( sig_start_receive_ready_o ),
.sig_start_i            ( sig_start_i               ),
.sig_vld_i              ( sig_vld_i                 ),
.sig_real_i             ( sig_real_i                ),
.sig_imag_i             ( sig_imag_i                ),
.N_select               ( N_select                  ),
.state_n_start_o        ( state_n_start_o           ),
.state_n_vld_o          ( state_n_vld_o             ),
.state_n_real_o         ( state_n_real_o            ),
.state_n_imag_o         ( state_n_imag_o            ),
.stage_0_sig_start_i    ( stage_0_sig_start_i       ),
.stage_0_sig_vld_i      ( stage_0_sig_vld_i         ),
.stage_0_sig_real_i     ( stage_0_sig_real_i        ),
.stage_0_sig_imag_i     ( stage_0_sig_imag_i        ),
.sig_start_o            ( sig_start_o               ),
.sig_vld_o              ( sig_vld_o                 ),
.sig_real_o             ( sig_real_o                ),
.sig_imag_o             ( sig_imag_o                ),
.N_index_o              ( N_index_o                 )
);


//generate stage
fft_stage_n0#(
.DATA_WIDTH             ( DATA_WIDTH                )
)fft_stage_n0_inst(
.clk                    ( clk                       ),
.rst_n                  ( rst_n                     ),
.sig_start_i            ( stage_sig_start_i[0]      ),
.sig_vld_i              ( stage_sig_vld_i[0]        ),
.sig_real_i             ( stage_sig_real_i[0]       ),
.sig_imag_i             ( stage_sig_imag_i[0]       ),
.sig_start_o            ( stage_sig_start_o[0]      ),
.sig_vld_o              ( stage_sig_vld_o[0]        ),
.sig_real_o             ( stage_sig_real_o[0]       ),
.sig_imag_o             ( stage_sig_imag_o[0]       )
   );
   
genvar i;
generate
    for (i=1; i<MAX_STAGE; i=i+1)begin: state_n_low
        if(i<5)begin
            fft_stage_n1_opt#(
            .DATA_WIDTH     ( DATA_WIDTH                        ),
            .STATE_N        ( 1<<(i+1)                          ),
            .RAM_RD_LATENCY ( RAM_RD_LATENCY                    ),
            .ANGEL_STEP     ( ANGEL_STEP[(24*(13+1-i)-1)-:24]   ),
            .ANGEL_PI_4     ( ANGEL_PI_4                        ),
            .ADDR_WIDTH     ( i                                 )
            )fft_stage_low_inst(
            .clk            ( clk                               ),
            .rst_n          ( rst_n                             ),
            .sig_start_i    ( stage_sig_start_i[i]              ),
            .sig_vld_i      ( stage_sig_vld_i[i]                ),
            .sig_real_i     ( stage_sig_real_i[i]               ),
            .sig_imag_i     ( stage_sig_imag_i[i]               ),
            .sig_start_o    ( stage_sig_start_o[i]              ),
            .sig_vld_o      ( stage_sig_vld_o[i]                ),
            .sig_real_o     ( stage_sig_real_o[i]               ),
            .sig_imag_o     ( stage_sig_imag_o[i]               ),
            .wr_en_o        ( stage_wr_en_o[i-1]                ),
            .wr_addr_o      ( stage_wr_addr_o[((i+1)*i/2-1)-:i] ),
            .wr_data_o      ( stage_wr_data_o[i-1]              ),
            .rd_en_o        ( stage_rd_en_o[i-1]                ),
            .rd_addr_o      ( stage_rd_addr_o[((i+1)*i/2-1)-:i] ),
            .rd_data_i      ( stage_rd_data_i[i-1]              ) 
            ); 
        end else begin
            fft_stage_n2_opt#(
            .DATA_WIDTH     ( DATA_WIDTH                        ),
            .STATE_N        ( 1<<(i+1)                          ),
            .ANGEL_STEP     ( ANGEL_STEP[(24*(13+1-i)-1)-:24]   ),
            .ANGEL_PI_4     ( ANGEL_PI_4                        ),
            .RAM_RD_LATENCY ( RAM_RD_LATENCY                    ),
            .ADDR_WIDTH     ( i                                 )
            )fft_stage_n2_inst(
            .clk            ( clk                               ),
            .rst_n          ( rst_n                             ),
            .sig_start_i    ( stage_sig_start_i[i]              ),
            .sig_vld_i      ( stage_sig_vld_i[i]                ),
            .sig_real_i     ( stage_sig_real_i[i]               ),
            .sig_imag_i     ( stage_sig_imag_i[i]               ),
            .sig_start_o    ( stage_sig_start_o[i]              ),
            .sig_vld_o      ( stage_sig_vld_o[i]                ),
            .sig_real_o     ( stage_sig_real_o[i]               ),
            .sig_imag_o     ( stage_sig_imag_o[i]               ),
            .wr_en_o        ( stage_wr_en_o[i-1]                ),
            .wr_addr_o      ( stage_wr_addr_o[((i+1)*i/2-1)-:i] ),
            .wr_data_o      ( stage_wr_data_o[i-1]              ),
            .rd_en_o        ( stage_rd_en_o[i-1]                ),
            .rd_addr_o      ( stage_rd_addr_o[((i+1)*i/2-1)-:i] ),
            .rd_data_i      ( stage_rd_data_i[i-1]              ) 
            );
        end                             
    end
endgenerate     

//stage connection
assign stage_0_sig_start_i = stage_sig_start_o[0];
assign stage_0_sig_vld_i = stage_sig_vld_o[0];
assign stage_0_sig_real_i = stage_sig_real_o[0];
assign stage_0_sig_imag_i = stage_sig_imag_o[0];


genvar k;
generate
    for (k=0; k<=(MAX_STAGE-1); k=k+1)begin: state_line
        if(k== (MAX_STAGE-1))begin
            always@(*) begin
                if(N_select == MAX_STAGE)begin
                    stage_sig_start_i[k] = state_n_start_o;
                    stage_sig_vld_i[k]   = state_n_vld_o;
                    stage_sig_real_i[k]  = state_n_real_o;
                    stage_sig_imag_i[k]  = state_n_imag_o;
                end else begin
                    stage_sig_start_i[k] = 1'b0;
                    stage_sig_vld_i[k]   = 1'b0;
                    stage_sig_real_i[k]  =  'h0;
                    stage_sig_imag_i[k]  =  'h0;
                end
            end
        end else begin
            always@(*) begin
                if(N_select == (k+1))begin
                    stage_sig_start_i[k] = state_n_start_o;
                    stage_sig_vld_i[k]   = state_n_vld_o;  
                    stage_sig_real_i[k]  = state_n_real_o; 
                    stage_sig_imag_i[k]  = state_n_imag_o; 
                end else begin
                    stage_sig_start_i[k] = stage_sig_start_o[k+1];
                    stage_sig_vld_i[k]   = stage_sig_vld_o[k+1];
                    stage_sig_real_i[k]  = stage_sig_real_o[k+1];
                    stage_sig_imag_i[k]  = stage_sig_imag_o[k+1];
                end
            end
        end       
    end
endgenerate  



//generate ram 
generate
if (MAX_STAGE>=14) begin : ram_8192_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 13                                ),
    .DP         ( 1<<13                             ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_8192_inst(
    .addra      ( stage_wr_addr_o[(14*13/2-1)-:13]  ),
    .addrb      ( stage_rd_addr_o[(14*13/2-1)-:13]  ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[12]               ),
    .doutb      ( stage_rd_data_i[12]               ),
    .ena        ( stage_wr_en_o[12]                 ),
    .enb        ( stage_rd_en_o[12]                 ),
    .wea        ( stage_wr_en_o[12]                 )
    );
end

if (MAX_STAGE>=13) begin : ram_4096_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 12                                ),
    .DP         ( 1<<12                             ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_4096_inst(
    .addra      ( stage_wr_addr_o[(13*12/2-1)-:12]  ),
    .addrb      ( stage_rd_addr_o[(13*12/2-1)-:12]  ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[11]               ),
    .doutb      ( stage_rd_data_i[11]               ),
    .ena        ( stage_wr_en_o[11]                 ),
    .enb        ( stage_rd_en_o[11]                 ),
    .wea        ( stage_wr_en_o[11]                 )
    );
end

if (MAX_STAGE>=12) begin : ram_2048_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 11                                ),
    .DP         ( 1<<11                             ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_2048_inst(
    .addra      ( stage_wr_addr_o[(12*11/2-1)-:11]  ),
    .addrb      ( stage_rd_addr_o[(12*11/2-1)-:11]  ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[10]               ),
    .doutb      ( stage_rd_data_i[10]               ),
    .ena        ( stage_wr_en_o[10]                 ),
    .enb        ( stage_rd_en_o[10]                 ),
    .wea        ( stage_wr_en_o[10]                 )
    );
end

if (MAX_STAGE>=11) begin : ram_1024_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 10                                ),
    .DP         ( 1<<10                             ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_1024_inst(
    .addra      ( stage_wr_addr_o[(11*10/2-1)-:10]  ),
    .addrb      ( stage_rd_addr_o[(11*10/2-1)-:10]  ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[9]                ),
    .doutb      ( stage_rd_data_i[9]                ),
    .ena        ( stage_wr_en_o[9]                  ),
    .enb        ( stage_rd_en_o[9]                  ),
    .wea        ( stage_wr_en_o[9]                  )
    );
end

if (MAX_STAGE>=10) begin : ram_512_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 9                                 ),
    .DP         ( 1<<9                              ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_512_inst(
    .addra      ( stage_wr_addr_o[(10*9/2-1)-:9]    ),
    .addrb      ( stage_rd_addr_o[(10*9/2-1)-:9]    ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[8]                ),
    .doutb      ( stage_rd_data_i[8]                ),
    .ena        ( stage_wr_en_o[8]                  ),
    .enb        ( stage_rd_en_o[8]                  ),
    .wea        ( stage_wr_en_o[8]                  )
    );
end

if (MAX_STAGE>=9) begin : ram_256_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 8                                 ),
    .DP         ( 1<<8                              ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_256_inst(
    .addra      ( stage_wr_addr_o[(9*8/2-1)-:8]     ),
    .addrb      ( stage_rd_addr_o[(9*8/2-1)-:8]     ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[7]                ),
    .doutb      ( stage_rd_data_i[7]                ),
    .ena        ( stage_wr_en_o[7]                  ),
    .enb        ( stage_rd_en_o[7]                  ),
    .wea        ( stage_wr_en_o[7]                  )
    );
end

if (MAX_STAGE>=8) begin : ram_128_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 7                                 ),
    .DP         ( 1<<7                              ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_128_inst(
    .addra      ( stage_wr_addr_o[(8*7/2-1)-:7]     ),
    .addrb      ( stage_rd_addr_o[(8*7/2-1)-:7]     ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[6]                ),
    .doutb      ( stage_rd_data_i[6]                ),
    .ena        ( stage_wr_en_o[6]                  ),
    .enb        ( stage_rd_en_o[6]                  ),
    .wea        ( stage_wr_en_o[6]                  )
    );
end

if (MAX_STAGE>=7) begin : ram_64_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 6                                 ),
    .DP         ( 1<<6                              ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_64_inst(
    .addra      ( stage_wr_addr_o[(7*6/2-1)-:6]     ),
    .addrb      ( stage_rd_addr_o[(7*6/2-1)-:6]     ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[5]                ),
    .doutb      ( stage_rd_data_i[5]                ),
    .ena        ( stage_wr_en_o[5]                  ),
    .enb        ( stage_rd_en_o[5]                  ),
    .wea        ( stage_wr_en_o[5]                  )
    );
end

if (MAX_STAGE>=6) begin : ram_32_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 5                                 ),
    .DP         ( 1<<5                              ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_32_inst(
    .addra      ( stage_wr_addr_o[(6*5/2-1)-:5]     ),
    .addrb      ( stage_rd_addr_o[(6*5/2-1)-:5]     ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[4]                ),
    .doutb      ( stage_rd_data_i[4]                ),
    .ena        ( stage_wr_en_o[4]                  ),
    .enb        ( stage_rd_en_o[4]                  ),
    .wea        ( stage_wr_en_o[4]                  )
    );
end

if (MAX_STAGE>=5) begin : ram_16_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 4                                 ),
    .DP         ( 1<<4                              ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_16_inst(
    .addra      ( stage_wr_addr_o[(5*4/2-1)-:4]     ),
    .addrb      ( stage_rd_addr_o[(5*4/2-1)-:4]     ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[3]                ),
    .doutb      ( stage_rd_data_i[3]                ),
    .ena        ( stage_wr_en_o[3]                  ),
    .enb        ( stage_rd_en_o[3]                  ),
    .wea        ( stage_wr_en_o[3]                  )
    );
end

if (MAX_STAGE>=4) begin : ram_8_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 3                                 ),
    .DP         ( 1<<3                              ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_8_inst(
    .addra      ( stage_wr_addr_o[(4*3/2-1)-:3]     ),
    .addrb      ( stage_rd_addr_o[(4*3/2-1)-:3]     ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[2]                ),
    .doutb      ( stage_rd_data_i[2]                ),
    .ena        ( stage_wr_en_o[2]                  ),
    .enb        ( stage_rd_en_o[2]                  ),
    .wea        ( stage_wr_en_o[2]                  )
    );
end

if (MAX_STAGE>=3) begin : ram_4_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 2                                 ),
    .DP         ( 1<<2                              ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_4_inst(
    .addra      ( stage_wr_addr_o[(3*2/2-1)-:2]     ),
    .addrb      ( stage_rd_addr_o[(3*2/2-1)-:2]     ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[1]                ),
    .doutb      ( stage_rd_data_i[1]                ),
    .ena        ( stage_wr_en_o[1]                  ),
    .enb        ( stage_rd_en_o[1]                  ),
    .wea        ( stage_wr_en_o[1]                  )
    );
end

if (MAX_STAGE>=2) begin : ram_2_datawidth2
    ram2p#(
    .WD         ( DATA_WIDTH*2                      ),
    .PW         ( 1                                 ),
    .DP         ( 1<<1                              ),
    .RD_LATENCY ( RAM_RD_LATENCY                    )
    ) ram2p_2_inst(
    .addra      ( stage_wr_addr_o[(2*1/2-1)-:1]     ),
    .addrb      ( stage_rd_addr_o[(2*1/2-1)-:1]     ),
    .clka       ( clk                               ),
    .clkb       ( clk                               ),
    .dina       ( stage_wr_data_o[0]                ),
    .doutb      ( stage_rd_data_i[0]                ),
    .ena        ( stage_wr_en_o[0]                  ),
    .enb        ( stage_rd_en_o[0]                  ),
    .wea        ( stage_wr_en_o[0]                  )
    );
end

endgenerate

endmodule
