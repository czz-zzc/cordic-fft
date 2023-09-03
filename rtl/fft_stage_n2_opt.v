`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/10 09:44:45
// Design Name: 
// Module Name: fft_stage_n2
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


module fft_stage_n2_opt#(
parameter DATA_WIDTH = 16,
parameter STATE_N = 4096,
parameter RAM_RD_LATENCY = 2,
parameter ANGEL_STEP = 402,
parameter ANGEL_PI_4 = 205887,
parameter ADDR_WIDTH = 11//log2(STATE_N)-1
)(
input                               clk,
input                               rst_n,
input                               sig_start_i,
input                               sig_vld_i,
input        [DATA_WIDTH-1:0]       sig_real_i,
input        [DATA_WIDTH-1:0]       sig_imag_i,

output                              sig_start_o,
output  reg                         sig_vld_o,
output  reg  [DATA_WIDTH-1:0]       sig_real_o,
output  reg  [DATA_WIDTH-1:0]       sig_imag_o,

output  reg                         wr_en_o,
output  reg  [ADDR_WIDTH-1:0]       wr_addr_o,
output  reg  [DATA_WIDTH*2-1:0]     wr_data_o,

output  reg                         rd_en_o,
output  reg  [ADDR_WIDTH-1:0]       rd_addr_o,
input        [DATA_WIDTH*2-1:0]     rd_data_i 
   );
localparam OUT_REGISTER_EN = 1; 
localparam CORDIC_DELAY = 15;

//localparam BUTTER_D_DELAY = CORDIC_DELAY + 1;
localparam EXTERNAL_WR_MAX = STATE_N/2 - CORDIC_DELAY;

localparam LOCAL_RAM_WD = DATA_WIDTH*2;
localparam LOCAL_RAM_PW = 5;
localparam LOCAL_RAM_DP = CORDIC_DELAY;
localparam LOCAL_RAM_RD_LATENCY = RAM_RD_LATENCY;

localparam READ_DATA_START = {ADDR_WIDTH{1'b1}}-RAM_RD_LATENCY;
localparam READ_DATA_END1 = {(ADDR_WIDTH+1){1'b1}}-RAM_RD_LATENCY;
localparam READ_DATA_END2 = READ_DATA_START + EXTERNAL_WR_MAX;
localparam READ_DATA_END3 = {(ADDR_WIDTH+1){1'b1}}-RAM_RD_LATENCY;


wire                        sig_start_d;
wire                        sig_vld_d;
wire [DATA_WIDTH-1:0]       sig_real_d;
wire [DATA_WIDTH-1:0]       sig_imag_d;
wire                        wait_wr_en;
wire [ADDR_WIDTH-1:0]       wait_wr_addr;
wire [DATA_WIDTH*2-1:0]     wait_wr_data;

wire                        cal_rd_en;
reg  [ADDR_WIDTH-1:0]       cal_rd_addr;
wire [ADDR_WIDTH-1:0]       cal_rd_addr_d;
wire [DATA_WIDTH*2-1:0]     cal_rd_data;

reg  [ADDR_WIDTH:0]         data_in_cnt;
wire                        cal_rd_en_d;
wire                        c_vld;
wire                        d_vld;
wire [DATA_WIDTH-1:0]       c_real;
wire [DATA_WIDTH-1:0]       c_imag;
wire [DATA_WIDTH-1:0]       d_real;
wire [DATA_WIDTH-1:0]       d_imag;

reg  [ADDR_WIDTH-1:0]       d_cnt;
wire                        external_wr_en;
wire [ADDR_WIDTH-1:0]       external_wr_addr;
wire [DATA_WIDTH*2-1:0]     external_wr_data;

wire                        local_wr_en;
reg  [LOCAL_RAM_PW-1:0]     local_wr_addr;
wire [DATA_WIDTH*2-1:0]     local_wr_data;

wire                        external_wr_sel;
reg  [ADDR_WIDTH:0]         data_out_cnt;

wire                        external_rd_en;
reg  [ADDR_WIDTH-1:0]       external_rd_addr;
wire [DATA_WIDTH*2-1:0]     external_rd_data;

wire                        local_rd_en;
reg  [LOCAL_RAM_PW-1:0]     local_rd_addr;
wire [DATA_WIDTH*2-1:0]     local_rd_data;

wire                        local_rd_en_d;
wire                        external_rd_en_d;


fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(1)) 
sig_real_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_real_i),.data_o(sig_real_d));

fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(1)) 
sig_imag_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_imag_i),.data_o(sig_imag_d));

fft_delay#(.DATA_WIDTH(1),.DELAY(1)) 
sig_start_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_start_i),.data_o(sig_start_d));

fft_delay#(.DATA_WIDTH(1),.DELAY(1)) 
sig_vld_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_vld_i),.data_o(sig_vld_d));

//data in cnt
always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        data_in_cnt <= 'h0;
    end else if(sig_start_d == 1'b1) begin
        data_in_cnt <= 'h1;
    end else if(sig_vld_d == 1'b1) begin
        data_in_cnt <= data_in_cnt +  1'b1;
    end
end

//wait pro
assign wait_wr_en = sig_vld_d & (~data_in_cnt[ADDR_WIDTH]);
assign wait_wr_data = {sig_real_d,sig_imag_d};
assign wait_wr_addr = data_in_cnt[ADDR_WIDTH-1:0];

//cal pro
assign cal_rd_en = (data_in_cnt >= READ_DATA_START && data_in_cnt < READ_DATA_END1)?1'b1:1'b0;

always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        cal_rd_addr <= 'h0;
    end else if(cal_rd_en == 1'b1) begin
        cal_rd_addr <= cal_rd_addr + 1'b1;
    end 
end

assign cal_rd_data = rd_data_i;

fft_delay#(.DATA_WIDTH(1),.DELAY(RAM_RD_LATENCY)) 
cal_rd_en_d_inst(.clk(clk),.rst_n(rst_n),.data_i(cal_rd_en),.data_o(cal_rd_en_d));

fft_delay#(.DATA_WIDTH(ADDR_WIDTH),.DELAY(RAM_RD_LATENCY)) 
cal_rd_addr_d_inst(.clk(clk),.rst_n(rst_n),.data_i(cal_rd_addr),.data_o(cal_rd_addr_d));

butterfly_stepn_opt#(
.DATA_WIDTH         ( DATA_WIDTH                             ),
.ADDR_WIDTH         ( ADDR_WIDTH                             ),
.ANGEL_STEP         ( ANGEL_STEP                             ),
.ANGEL_PI_4         ( ANGEL_PI_4                             ),
.CORDIC_DELAY       ( CORDIC_DELAY                           )
)butterfly_stepn_inst(                                       
.clk                ( clk                                    ),
.rst_n              ( rst_n                                  ),
.addr               ( cal_rd_addr_d                          ),
.ab_vld_i           ( cal_rd_en_d                            ),
.a_real_i           ( cal_rd_data[DATA_WIDTH*2-1:DATA_WIDTH] ),
.a_imag_i           ( cal_rd_data[DATA_WIDTH-1:0]            ),
.b_real_i           ( sig_real_i                             ),
.b_imag_i           ( sig_imag_i                             ),
.c_vld_o            ( c_vld                                  ),
.d_vld_o            ( d_vld                                  ),
.c_real_o           ( c_real                                 ),
.c_imag_o           ( c_imag                                 ),
.d_real_o           ( d_real                                 ),
.d_imag_o           ( d_imag                                 )
);

//d out cnt
always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        d_cnt <= 'h0;
    end else if(d_vld == 1'b1) begin
        d_cnt <= d_cnt + 1'b1;
    end
end

//temporary storage external ram
assign external_wr_sel = (d_cnt < EXTERNAL_WR_MAX)?1'b1:1'b0;
assign external_wr_en   = d_vld & external_wr_sel;
assign external_wr_addr = d_cnt;
assign external_wr_data = {d_real,d_imag};

//temporary storage local ram
always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        local_wr_addr <= 'h0;
    end else if(local_wr_en == 1'b1) begin
        local_wr_addr <= local_wr_addr + 1'b1;
    end else begin
        local_wr_addr <= 'h0;
    end
end
assign local_wr_en = d_vld & (~external_wr_sel);
assign local_wr_data = {d_real,d_imag};

//data out cnt
always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        data_out_cnt <= 'h0;
    end else if(c_vld == 1'b1 || (|data_out_cnt)==1'b1) begin
        data_out_cnt <= data_out_cnt + 1'b1;
    end
end

//read external ram
assign external_rd_en = (data_out_cnt > READ_DATA_START && data_out_cnt <= READ_DATA_END2)?1'b1:1'b0;

always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        external_rd_addr <= 'h0;
    end else if(external_rd_en == 1'b1) begin
        external_rd_addr <= external_rd_addr + 1'b1;
    end else begin
        external_rd_addr <= 'h0;
    end
end

assign external_rd_data = rd_data_i;

//read local ram
assign local_rd_en = (data_out_cnt > READ_DATA_END2 && data_out_cnt <= READ_DATA_END3)?1'b1:1'b0;

always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        local_rd_addr <= 'h0;
    end else if(local_rd_en == 1'b1) begin
        local_rd_addr <= local_rd_addr + 1'b1;
    end else begin
        local_rd_addr <= 'h0;
    end
end

ram2p#(
.WD         (LOCAL_RAM_WD         ),
.PW         (LOCAL_RAM_PW         ),
.DP         (LOCAL_RAM_DP         ),
.RD_LATENCY (LOCAL_RAM_RD_LATENCY )
) ram2p_local_inst(
.addra      ( local_wr_addr       ),
.addrb      ( local_rd_addr       ),
.clka       ( clk                 ),
.clkb       ( clk                 ),
.dina       ( local_wr_data       ),
.doutb      ( local_rd_data       ),
.ena        ( local_wr_en         ),
.enb        ( local_rd_en         ),
.wea        ( local_wr_en         )
);

fft_delay#(.DATA_WIDTH(1),.DELAY(RAM_RD_LATENCY)) 
local_rd_en_d_inst(.clk(clk),.rst_n(rst_n),.data_i(local_rd_en),.data_o(local_rd_en_d));

fft_delay#(.DATA_WIDTH(1),.DELAY(RAM_RD_LATENCY)) 
external_rd_en_d_inst(.clk(clk),.rst_n(rst_n),.data_i(external_rd_en),.data_o(external_rd_en_d));

//data out 
assign sig_start_o = (~(|data_out_cnt[ADDR_WIDTH-1:0])) & (c_vld | d_vld);
//assign sig_start_o = (data_out_cnt == RAM_RD_LATENCY)?1'b1:1'b0;

always@(*)begin
    case({local_rd_en_d,external_rd_en_d,c_vld})
        3'b001:begin 
            sig_vld_o  <= 1'b1;
            sig_real_o <= c_real;
            sig_imag_o <= c_imag;
        end
        3'b010:begin 
            sig_vld_o  <= 1'b1;
            sig_real_o <= external_rd_data[DATA_WIDTH*2-1:DATA_WIDTH];
            sig_imag_o <= external_rd_data[DATA_WIDTH-1:0];
        end
        3'b100:begin 
            sig_vld_o  <= 1'b1;
            sig_real_o <= local_rd_data[DATA_WIDTH*2-1:DATA_WIDTH];
            sig_imag_o <= local_rd_data[DATA_WIDTH-1:0];
        end
        default:begin 
            sig_vld_o  <= 1'b0;
            sig_real_o <=  'h0;
            sig_imag_o <=  'h0;
        end
    endcase
end

always@(*)begin
    case({external_wr_en,wait_wr_en})
        2'b01:begin 
            wr_en_o   <= 1'b1;
            wr_addr_o <= wait_wr_addr;
            wr_data_o <= wait_wr_data;
        end
        2'b10:begin 
            wr_en_o   <= 1'b1;
            wr_addr_o <= external_wr_addr;
            wr_data_o <= external_wr_data;
        end
        default:begin 
            wr_en_o   <= 1'b0;
            wr_addr_o <=  'h0;
            wr_data_o <=  'h0;
        end
    endcase
end

always@(*)begin
    case({external_rd_en,cal_rd_en})
        2'b01:begin 
            rd_en_o   <= 1'b1;
            rd_addr_o <= cal_rd_addr;
        end
        2'b10:begin 
            rd_en_o   <= 1'b1;
            rd_addr_o <= external_rd_addr;
        end
        default:begin 
            rd_en_o   <= 1'b0;
            rd_addr_o <=  'h0;
        end
    endcase
end

endmodule