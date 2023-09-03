`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/10 09:44:45
// Design Name: 
// Module Name: fft_stage_n1
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


module fft_stage_n1_opt#(
parameter DATA_WIDTH = 16,
parameter STATE_N = 16,
parameter RAM_RD_LATENCY = 2,
parameter ANGEL_STEP = 402,
parameter ANGEL_PI_4 = 205887,
parameter ADDR_WIDTH = 3//log2(STATE_N)-1
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

output                              wr_en_o,
output       [ADDR_WIDTH-1:0]       wr_addr_o,
output       [DATA_WIDTH*2-1:0]     wr_data_o,
           
output                              rd_en_o,
output       [ADDR_WIDTH-1:0]       rd_addr_o,
input        [DATA_WIDTH*2-1:0]     rd_data_i 
   );
localparam OUT_REGISTER_EN = 1; 
localparam CORDIC_DELAY = 15;
localparam C_DATA_DELAY = CORDIC_DELAY - (STATE_N/2);
localparam C_DATA_DELAY_N = (STATE_N/2) - CORDIC_DELAY;


reg  [ADDR_WIDTH:0]         data_in_cnt;
wire [DATA_WIDTH-1:0]       sig_real_d;
wire [DATA_WIDTH-1:0]       sig_imag_d;
wire [ADDR_WIDTH-1:0]       rd_addr_d;
wire                        rd_en_d;
wire                        c_vld;
wire                        d_vld;
wire [DATA_WIDTH-1:0]       c_real;
wire [DATA_WIDTH-1:0]       c_imag;
wire [DATA_WIDTH-1:0]       d_real;
wire [DATA_WIDTH-1:0]       d_imag;


//wire [DATA_WIDTH-1:0]       c_real_d;
//wire [DATA_WIDTH-1:0]       c_imag_d;
//wire                        c_vld_d;
//wire                        c_vld_dd;


//data in cnt
always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        data_in_cnt <= 'h0;
    end else if(sig_start_i == 1'b1) begin
        data_in_cnt <= 'h1;
    end else if(sig_vld_i == 1'b1) begin
        data_in_cnt <= data_in_cnt +  1'b1;
    end
end

//wait pro
assign wr_en_o = sig_vld_i & (~data_in_cnt[ADDR_WIDTH]);
assign wr_data_o = {sig_real_i,sig_imag_i};
assign wr_addr_o = data_in_cnt[ADDR_WIDTH-1:0];

//cal pro
assign rd_en_o = data_in_cnt[ADDR_WIDTH];
assign rd_addr_o = data_in_cnt[ADDR_WIDTH-1:0];

fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(RAM_RD_LATENCY)) 
sig_real_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_real_i),.data_o(sig_real_d));

fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(RAM_RD_LATENCY)) 
sig_imag_d_inst(.clk(clk),.rst_n(rst_n),.data_i(sig_imag_i),.data_o(sig_imag_d));

fft_delay#(.DATA_WIDTH(1),.DELAY(RAM_RD_LATENCY)) 
rd_en_d_inst(.clk(clk),.rst_n(rst_n),.data_i(data_in_cnt[ADDR_WIDTH]),.data_o(rd_en_d));

fft_delay#(.DATA_WIDTH(ADDR_WIDTH),.DELAY(RAM_RD_LATENCY)) 
rd_addr_d_inst(.clk(clk),.rst_n(rst_n),.data_i(data_in_cnt[ADDR_WIDTH-1:0]),.data_o(rd_addr_d));


butterfly_stepn_opt#(
.DATA_WIDTH         ( DATA_WIDTH                             ),
.ADDR_WIDTH         ( ADDR_WIDTH                             ),
.ANGEL_STEP         ( ANGEL_STEP                             ),
.ANGEL_PI_4         ( ANGEL_PI_4                             ),
.CORDIC_DELAY       ( CORDIC_DELAY                           )
)butterfly_stepn_inst(                                      
.clk                ( clk                                    ),
.rst_n              ( rst_n                                  ),
.addr               ( rd_addr_d                              ),
.ab_vld_i           ( rd_en_d                                ),
.a_real_i           ( rd_data_i[DATA_WIDTH*2-1:DATA_WIDTH]   ),
.a_imag_i           ( rd_data_i[DATA_WIDTH-1:0]              ),
.b_real_i           ( sig_real_d                             ),
.b_imag_i           ( sig_imag_d                             ),
.c_vld_o            ( c_vld                                  ),
.d_vld_o            ( d_vld                                  ),
.c_real_o           ( c_real                                 ),
.c_imag_o           ( c_imag                                 ),
.d_real_o           ( d_real                                 ),
.d_imag_o           ( d_imag                                 )
);

generate
    if (C_DATA_DELAY_N > 0) begin: delay_d
        wire [DATA_WIDTH-1:0]       d_real_d;
        wire [DATA_WIDTH-1:0]       d_imag_d;
        wire                        d_vld_d;
        wire                        d_vld_dd;
        wire                        c_vld_d;
        fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(C_DATA_DELAY_N))                   
        d_real_d_inst(.clk(clk),.rst_n(rst_n),.data_i(d_real),.data_o(d_real_d));  
                                                                                   
        fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(C_DATA_DELAY_N))                   
        d_imag_d_inst(.clk(clk),.rst_n(rst_n),.data_i(d_imag),.data_o(d_imag_d));  
                                                                                   
        fft_delay#(.DATA_WIDTH(1),.DELAY(C_DATA_DELAY_N))                            
        d_vld_d_inst(.clk(clk),.rst_n(rst_n),.data_i(d_vld),.data_o(d_vld_d));     
                                                                                   
        fft_delay#(.DATA_WIDTH(1),.DELAY(1))                                       
        c_vld_d_inst(.clk(clk),.rst_n(rst_n),.data_i(c_vld),.data_o(c_vld_d)); 
        
        //data out 
        assign sig_start_o = c_vld & (~c_vld_d);
        
        always@(*)begin
            case({d_vld_d,c_vld})
                2'b01:begin 
                    sig_vld_o  <= 1'b1;
                    sig_real_o <= c_real;
                    sig_imag_o <= c_imag;
                end
                2'b10:begin 
                    sig_vld_o  <= 1'b1;
                    sig_real_o <= d_real_d;
                    sig_imag_o <= d_imag_d;
                end
                default:begin 
                    sig_vld_o  <= 1'b0;
                    sig_real_o <=  'h0;
                    sig_imag_o <=  'h0;
                end
            endcase
        end
        
    end else begin: delay_c
    
        wire [DATA_WIDTH-1:0]       c_real_d;
        wire [DATA_WIDTH-1:0]       c_imag_d;
        wire                        c_vld_d;
        wire                        c_vld_dd;
        
        fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(C_DATA_DELAY)) 
        c_real_d_inst(.clk(clk),.rst_n(rst_n),.data_i(c_real),.data_o(c_real_d));
        
        fft_delay#(.DATA_WIDTH(DATA_WIDTH),.DELAY(C_DATA_DELAY)) 
        c_imag_d_inst(.clk(clk),.rst_n(rst_n),.data_i(c_imag),.data_o(c_imag_d));
        
        fft_delay#(.DATA_WIDTH(1),.DELAY(C_DATA_DELAY)) 
        c_vld_d_inst(.clk(clk),.rst_n(rst_n),.data_i(c_vld),.data_o(c_vld_d));
        
        fft_delay#(.DATA_WIDTH(1),.DELAY(1)) 
        c_vld_dd_inst(.clk(clk),.rst_n(rst_n),.data_i(c_vld_d),.data_o(c_vld_dd));
        
        //data out 
        assign sig_start_o = c_vld_d & (~c_vld_dd);
        
        always@(*)begin
            case({d_vld,c_vld_d})
                2'b01:begin 
                    sig_vld_o  <= 1'b1;
                    sig_real_o <= c_real_d;
                    sig_imag_o <= c_imag_d;
                end
                2'b10:begin 
                    sig_vld_o  <= 1'b1;
                    sig_real_o <= d_real;
                    sig_imag_o <= d_imag;
                end
                default:begin 
                    sig_vld_o  <= 1'b0;
                    sig_real_o <=  'h0;
                    sig_imag_o <=  'h0;
                end
            endcase
        end
    end
endgenerate


endmodule
