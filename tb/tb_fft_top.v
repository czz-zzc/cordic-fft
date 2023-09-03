`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/10 14:13:47
// Design Name: 
// Module Name: tb_fft_top
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


module tb_fft_top(

    );
parameter period=2;
reg clk=1'b1;
reg rst_n=1'b1;


always #(period/2)
clk=~clk;
initial
begin
   rst_n = 1'b0;
   #(100*period)
   rst_n = 1'b1;
end


parameter DATA_WIDTH = 16;
parameter MAX_STAGE = 12;
parameter RAM_RD_LATENCY = 2;
parameter FFT_IFFT = 0;
parameter OVERFLOW_PRO = 1;
parameter PIPE_CNT_ture = 2;
parameter NUM1 = 4096;
parameter NUM2 = 1024;
parameter SAMPLE_NUM = NUM1 + NUM2;
parameter PIPE_CNT = PIPE_CNT_ture-1;

reg                              sig_start_i;
reg                              sig_vld_i;
reg       [DATA_WIDTH-1:0]       sig_real_i;
reg       [DATA_WIDTH-1:0]       sig_imag_i;
wire                             sig_start_o;
wire                             sig_vld_o;
wire      [DATA_WIDTH-1:0]       sig_real_o;
wire      [DATA_WIDTH-1:0]       sig_imag_o;
wire                             sig_start_receive_ready_o;
reg                             sig_start_en_d;
wire      [MAX_STAGE-1:0]        N_index_o;
wire      [MAX_STAGE-1:0]        N_index_n_o;
reg                               cfg_vld;
reg                               cfg_fft_ifft;
reg        [3:0]                  cfg_N;
//wire                               cfg_vld;
//wire                               cfg_fft_ifft;
//wire        [3:0]                  cfg_N;

fft_top_opt#(
.DATA_WIDTH         ( DATA_WIDTH    ),
.MAX_STAGE          ( MAX_STAGE     ),
.RAM_RD_LATENCY     ( RAM_RD_LATENCY),
.FFT_IFFT           ( FFT_IFFT      ),
.OVERFLOW_PRO       ( OVERFLOW_PRO  )
)fft_top_inst(
.cfg_vld            (cfg_vld           ),
.cfg_fft_ifft       (cfg_fft_ifft           ),
.cfg_N              (cfg_N            ),
.clk                ( clk         ),
.rst_n              ( rst_n       ),
.sig_start_receive_ready_o     ( sig_start_receive_ready_o            ),
.sig_start_i        ( sig_start_i ),
.sig_vld_i          ( sig_vld_i   ),
.sig_real_i         ( sig_real_i  ),
.sig_imag_i         ( sig_imag_i  ),
.sig_start_o        ( sig_start_o ),
.sig_vld_o          ( sig_vld_o   ),
.sig_real_o         ( sig_real_o  ),
.sig_imag_o         ( sig_imag_o  ),
.N_index_o          ( N_index_o            )
    );

reg [DATA_WIDTH-1:0]data_in_real_4096[0:4096-1];
reg [DATA_WIDTH-1:0]data_in_imag_4096[0:4096-1];
reg [DATA_WIDTH-1:0]data_in_real_1024[0:1024-1];
reg [DATA_WIDTH-1:0]data_in_imag_1024[0:1024-1];
//read data
initial
begin
   $readmemh ("F:/workfile2023/soc/verif/fft/model/data_in_real_4096.txt",data_in_real_4096);
   $readmemh ("F:/workfile2023/soc/verif/fft/model/data_in_imag_4096.txt",data_in_imag_4096);
   $readmemh ("F:/workfile2023/soc/verif/fft/model/data_in_real_1024.txt",data_in_real_1024);
   $readmemh ("F:/workfile2023/soc/verif/fft/model/data_in_imag_1024.txt",data_in_imag_1024);
end

reg [31:0]read_cnt=1'b0;
reg [3:0]test_cnt;

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        test_cnt <= 0;
    end else if((read_cnt == NUM1 && test_cnt == 0) || (read_cnt == NUM1 && test_cnt == 1)) begin
        test_cnt <= test_cnt + 1;
    end
end

//assign cfg_vld = (read_cnt== 2048 && test_cnt == 0);
//assign cfg_N =10;
//assign cfg_fft_ifft =0;
always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        cfg_vld <= 0;
        cfg_fft_ifft<= 0;
        cfg_N <= 0;
    end else if((read_cnt == 32'd2048) && (test_cnt == 'h0) ) begin
        cfg_vld <= 1'b1;
        cfg_fft_ifft<= 0;
        cfg_N <= 4'd10;
    end else begin
        cfg_vld <= 0;
        cfg_fft_ifft<= 0;
        cfg_N <= 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    sig_start_en_d <= sig_start_receive_ready_o;
    if(rst_n == 1'b0)begin
        read_cnt <= 'h0;
    end else if( (sig_start_receive_ready_o==1'b1) && (sig_start_en_d ==1'b0))  begin
        read_cnt <= 1'b1;
    end else begin
        read_cnt <= read_cnt + 1'b1;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        sig_start_i <= 'h0;
    end else if(read_cnt == 1)begin
        sig_start_i <= 1'b1;
    end else begin
        sig_start_i <= 'h0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        sig_vld_i <= 'h0;
        sig_real_i <= 'h0; 
        sig_imag_i <= 'h0; 
    end else if((read_cnt >= 1 && read_cnt<= NUM1 && test_cnt == 0 ))begin
        sig_vld_i <= 1'b1;
        sig_real_i <= data_in_real_4096[read_cnt-1];
        sig_imag_i <= data_in_imag_4096[read_cnt-1];
    end else if((read_cnt >= 1 && read_cnt<= NUM2 && test_cnt == 1 ))begin
        sig_vld_i <= 1'b1;
        sig_real_i <= data_in_real_1024[read_cnt-1];
        sig_imag_i <= data_in_imag_1024[read_cnt-1];
    end else begin
        sig_vld_i <= 'h0;
    end
end



integer fp_datao_real_w;
integer fp_datao_imag_w;
//write data
initial
begin
   fp_datao_real_w = $fopen("data_out_real.txt","w"); 
   fp_datao_imag_w = $fopen("data_out_image.txt","w"); 
end
reg [31:0]  record1_cnt;


 always@(posedge clk)  
 begin
     if(sig_vld_o == 1'b1 )begin
        record1_cnt <= record1_cnt +1;
        $fwrite(fp_datao_real_w,"%d\n",sig_real_o);
        $fwrite(fp_datao_imag_w,"%d\n",sig_imag_o);
     end else begin
        record1_cnt <= 'h0;
     end
     if(record1_cnt == (SAMPLE_NUM-1))begin
        $fclose(fp_datao_real_w);
        $fclose(fp_datao_imag_w);
     end
 end
 
 genvar i;
for ( i =0; i < MAX_STAGE; i=i+1)
begin:swap
    assign N_index_n_o[i] = N_index_o[MAX_STAGE-1-i];
end
endmodule
