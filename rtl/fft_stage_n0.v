`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/10 09:44:45
// Design Name: 
// Module Name: fft_stage_n0
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


module fft_stage_n0#(
parameter DATA_WIDTH = 16
)(
input                               clk,
input                               rst_n,
input                               sig_start_i,
input                               sig_vld_i,
input        [DATA_WIDTH-1:0]       sig_real_i,
input        [DATA_WIDTH-1:0]       sig_imag_i,

output                              sig_start_o,
output                              sig_vld_o,
output  reg  [DATA_WIDTH-1:0]       sig_real_o,
output  reg  [DATA_WIDTH-1:0]       sig_imag_o
   );


wire [DATA_WIDTH-1:0]       sig_real_d;
wire [DATA_WIDTH-1:0]       sig_imag_d;
wire                        sig_start_d;
wire                        sig_start_dd;
wire                        ab_vld;

wire                        cd_vld;
wire [DATA_WIDTH-1:0]       c_real;
wire [DATA_WIDTH-1:0]       c_imag;
wire [DATA_WIDTH-1:0]       d_real;
wire [DATA_WIDTH-1:0]       d_imag;
wire [DATA_WIDTH-1:0]       d_real_d;
wire [DATA_WIDTH-1:0]       d_imag_d;
wire                        sig_vld_d;

fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(1)) 
sig_real_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_real_i),.data_o(sig_real_d));

fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(1)) 
sig_imag_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_imag_i),.data_o(sig_imag_d));

fft_delay#(.DATA_WIDTH(1),.DELAY(2)) 
sig_vld_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_vld_i),.data_o(sig_vld_d));

fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(1)) 
d_real_d_inst(.clk(clk),.rst_n(rst_n),.data_i(d_real),.data_o(d_real_d));

fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(1)) 
d_imag_d_inst(.clk(clk),.rst_n(rst_n),.data_i(d_imag),.data_o(d_imag_d));

fft_delay#(.DATA_WIDTH(1),.DELAY(1)) 
sig_start_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_start_i),.data_o(sig_start_d));

fft_delay#(.DATA_WIDTH(1),.DELAY(2)) 
sig_start_dd_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_start_d),.data_o(sig_start_dd));

assign ab_vld = sig_start_d | sig_start_dd;

butterfly_step1#(
.DATA_WIDTH         ( DATA_WIDTH  )
)butterfly_step1_inst(            
.clk                ( clk         ),
.rst_n              ( rst_n       ),
.ab_vld_i           ( ab_vld      ),
.a_real_i           ( sig_real_d  ),
.a_imag_i           ( sig_imag_d  ),
.b_real_i           ( sig_real_i  ),
.b_imag_i           ( sig_imag_i  ),
.cd_vld_o           ( cd_vld      ),
.c_real_o           ( c_real      ),
.c_imag_o           ( c_imag      ),
.d_real_o           ( d_real      ),
.d_imag_o           ( d_imag      )
);

assign sig_start_o = cd_vld;
assign sig_vld_o   = sig_vld_d;

always@(*)begin
    case({cd_vld,sig_vld_d})
        2'b11:begin 
            sig_real_o <= c_real;
            sig_imag_o <= c_imag;
        end
        2'b01:begin 
            sig_real_o <= d_real_d;
            sig_imag_o <= d_imag_d;
        end
        default:begin 
            sig_real_o <=  'h0;
            sig_imag_o <=  'h0;
        end
    endcase
end

endmodule
