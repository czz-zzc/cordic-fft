`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/11 11:47:34
// Design Name: 
// Module Name: fft_ctrl
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


module fft_ctrl#(
parameter DATA_WIDTH = 16,
parameter MAX_STAGE = 14,// MAX_STAGE>=2
parameter FFT_IFFT = 0,
parameter OVERFLOW_PRO = 1
)(
input                               clk,
input                               rst_n,

input                               cfg_vld,
input                               cfg_fft_ifft,
input        [3:0]                  cfg_N,
output                              sig_start_en_o,//

input                               sig_start_i,
input                               sig_vld_i,
input        [DATA_WIDTH-1:0]       sig_real_i,
input        [DATA_WIDTH-1:0]       sig_imag_i,

output  reg  [3:0]                  N_select,
output  reg                         state_n_start_o,
output  reg                         state_n_vld_o,
output  reg  [DATA_WIDTH-1:0]       state_n_real_o,
output  reg  [DATA_WIDTH-1:0]       state_n_imag_o,

input                               stage_0_sig_start_i,
input                               stage_0_sig_vld_i,
input         [DATA_WIDTH-1:0]      stage_0_sig_real_i,
input         [DATA_WIDTH-1:0]      stage_0_sig_imag_i,

output  reg                         sig_start_o,
output  reg                         sig_vld_o,
output  reg   [DATA_WIDTH-1:0]      sig_real_o,
output  reg   [DATA_WIDTH-1:0]      sig_imag_o,
output  reg   [MAX_STAGE-1:0]       N_index_o
);

reg                                 cfg_fft_ifft_lock;
reg     [3:0]                       cfg_N_lock;
reg     [3:0]                       pro_cnt;
wire                                sig_end;

reg                                 fft_ifft_select;
reg     [MAX_STAGE-1:0]             out_cnt;
reg     [MAX_STAGE-1:0]             out_cnt_max;
wire    [MAX_STAGE-1:0]             out_cnt_swap;
reg     [MAX_STAGE-1:0]             N_index;
reg                                 sig_start_en;


generate
    if (OVERFLOW_PRO == 1) begin: scale_2_N
    
        always@(posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)begin
            state_n_real_o <= 'h0;
            state_n_imag_o <= 'h0;
        end else begin
            if(fft_ifft_select==1'b0)begin
                state_n_real_o <= {sig_real_i[DATA_WIDTH-1],sig_real_i[DATA_WIDTH-1:1]};
                state_n_imag_o <= {sig_imag_i[DATA_WIDTH-1],sig_imag_i[DATA_WIDTH-1:1]};
            end else begin
                state_n_real_o <= {sig_imag_i[DATA_WIDTH-1],sig_imag_i[DATA_WIDTH-1:1]};
                state_n_imag_o <= {sig_real_i[DATA_WIDTH-1],sig_real_i[DATA_WIDTH-1:1]};
            end
        end
        end
        
    end else begin: scale_N
    
        always@(posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)begin
            state_n_real_o <= 'h0;
            state_n_imag_o <= 'h0;
        end else begin
            if(fft_ifft_select==1'b0)begin
                state_n_real_o <= sig_real_i;
                state_n_imag_o <= sig_imag_i;
            end else begin
                state_n_real_o <= sig_imag_i;
                state_n_imag_o <= sig_real_i; 
            end
        end
        end
        
    end
endgenerate


always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        state_n_start_o <= 1'b0;
        state_n_vld_o <= 1'b0;
    end else begin
        state_n_start_o <= sig_start_i;
        state_n_vld_o <= sig_vld_i;
    end
end


always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        cfg_N_lock <= MAX_STAGE;
        cfg_fft_ifft_lock <= FFT_IFFT;
    end else if(cfg_vld == 1'b1) begin
        cfg_N_lock <= cfg_N;
        cfg_fft_ifft_lock <= cfg_fft_ifft;
    end
end

assign sig_start_en_o = sig_start_en;

always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        sig_start_en <= 1'b1;
    end else if((|pro_cnt) == 1'b0) begin//
        sig_start_en <= 1'b1;
    end else if( cfg_vld == 1'b1)begin
        sig_start_en <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        fft_ifft_select <= FFT_IFFT;
        N_select <= MAX_STAGE;
    end else if((|pro_cnt) == 1'b0) begin
        fft_ifft_select <= cfg_fft_ifft_lock;
        N_select <= cfg_N_lock;
    end 
end

assign  sig_end = (out_cnt == out_cnt_max) ? 1'b1:1'b0;

always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        pro_cnt <= 'h0;
    end else begin
        case ({sig_end,sig_start_i})
            2'b01: pro_cnt <= pro_cnt + 1'b1;
            2'b10: pro_cnt <= pro_cnt - 1'b1;
            default: pro_cnt <= pro_cnt;
         endcase
    end 
end

always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        out_cnt <= 'h0;
    end else if(out_cnt == out_cnt_max)begin
        out_cnt <= 'h0;
    end else if(stage_0_sig_vld_i == 1'b1) begin
        out_cnt <= out_cnt + 1'b1;
    end 
end

genvar i;
for ( i =0; i < MAX_STAGE; i=i+1)
begin:swap
    assign out_cnt_swap[i] = out_cnt[MAX_STAGE-1-i];
end

generate
    if (MAX_STAGE==2) begin: N_point_4
    
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max = 4'd3;       N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max = 4'd3;       N_index = out_cnt_swap;                                             end
            endcase
        end
        
    end else if(MAX_STAGE==3) begin: N_point_8
    
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max = 4'd3;       N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max = 4'd7;       N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max = 4'd7;       N_index = out_cnt_swap;                                             end
            endcase
        end
        
    end else if(MAX_STAGE==4) begin: N_point_16  
        
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max = 4'd3;       N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max = 4'd7;       N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max = 4'd15;      N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max = 4'd15;      N_index = out_cnt_swap;                                             end
            endcase
        end
        
    end else if(MAX_STAGE==5) begin: N_point_32  
    
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max = 5'd3;       N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max = 5'd7;       N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max = 5'd15;      N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max = 5'd31;      N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max = 5'd31;      N_index = out_cnt_swap;                                             end
            endcase
        end
        
    end else if(MAX_STAGE==6) begin: N_point_64
    
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max =  6'd3;      N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max =  6'd7;      N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max =  6'd15;     N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max =  6'd31;     N_index = {{(MAX_STAGE-5){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:5]};   end
            4'd6   :begin out_cnt_max =  6'd63;     N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max =  6'd63;     N_index = out_cnt_swap;                                             end
            endcase
        end  
        
    end else if(MAX_STAGE==7) begin: N_point_128
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max =  7'd3;      N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max =  7'd7;      N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max =  7'd15;     N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max =  7'd31;     N_index = {{(MAX_STAGE-5){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:5]};   end
            4'd6   :begin out_cnt_max =  7'd63;     N_index = {{(MAX_STAGE-6){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:6]};   end
            4'd7   :begin out_cnt_max =  7'd127;    N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max =  7'd127;    N_index = out_cnt_swap;                                             end
            endcase
        end  
        
    end else if(MAX_STAGE==8) begin: N_point_256  
    
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max =  8'd3;      N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max =  8'd7;      N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max =  8'd15;     N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max =  8'd31;     N_index = {{(MAX_STAGE-5){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:5]};   end
            4'd6   :begin out_cnt_max =  8'd63;     N_index = {{(MAX_STAGE-6){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:6]};   end
            4'd7   :begin out_cnt_max =  8'd127;    N_index = {{(MAX_STAGE-7){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:7]};   end
            4'd8   :begin out_cnt_max =  8'd255;    N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max =  8'd255;    N_index = out_cnt_swap;                                             end
            endcase
        end
        
    end else if(MAX_STAGE==9) begin: N_point_512  
    
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max =  9'd3;      N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max =  9'd7;      N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max =  9'd15;     N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max =  9'd31;     N_index = {{(MAX_STAGE-5){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:5]};   end
            4'd6   :begin out_cnt_max =  9'd63;     N_index = {{(MAX_STAGE-6){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:6]};   end
            4'd7   :begin out_cnt_max =  9'd127;    N_index = {{(MAX_STAGE-7){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:7]};   end
            4'd8   :begin out_cnt_max =  9'd255;    N_index = {{(MAX_STAGE-8){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:8]};   end
            4'd9   :begin out_cnt_max =  9'd511;    N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max =  9'd511;    N_index = out_cnt_swap;                                             end
            endcase
        end
        
    end else if(MAX_STAGE==10) begin: N_point_1024  
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max = 10'd3;      N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max = 10'd7;      N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max = 10'd15;     N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max = 10'd31;     N_index = {{(MAX_STAGE-5){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:5]};   end
            4'd6   :begin out_cnt_max = 10'd63;     N_index = {{(MAX_STAGE-6){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:6]};   end
            4'd7   :begin out_cnt_max = 10'd127;    N_index = {{(MAX_STAGE-7){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:7]};   end
            4'd8   :begin out_cnt_max = 10'd255;    N_index = {{(MAX_STAGE-8){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:8]};   end
            4'd9   :begin out_cnt_max = 10'd511;    N_index = {{(MAX_STAGE-9){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:9]};   end
            4'd10  :begin out_cnt_max = 10'd1023;   N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max = 10'd1023;   N_index = out_cnt_swap;                                             end
            endcase
        end
    end else if(MAX_STAGE==11) begin: N_point_2048  
    
         always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max = 11'd3;      N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max = 11'd7;      N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max = 11'd15;     N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max = 11'd31;     N_index = {{(MAX_STAGE-5){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:5]};   end
            4'd6   :begin out_cnt_max = 11'd63;     N_index = {{(MAX_STAGE-6){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:6]};   end
            4'd7   :begin out_cnt_max = 11'd127;    N_index = {{(MAX_STAGE-7){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:7]};   end
            4'd8   :begin out_cnt_max = 11'd255;    N_index = {{(MAX_STAGE-8){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:8]};   end
            4'd9   :begin out_cnt_max = 11'd511;    N_index = {{(MAX_STAGE-9){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:9]};   end
            4'd10  :begin out_cnt_max = 11'd1023;   N_index = {{(MAX_STAGE-10){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:10]}; end
            4'd11  :begin out_cnt_max = 11'd2047;   N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max = 11'd2047;   N_index = out_cnt_swap;                                             end
            endcase
        end
        
    end else if(MAX_STAGE==12) begin: N_point_4096
    
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max = 12'd3;      N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max = 12'd7;      N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max = 12'd15;     N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max = 12'd31;     N_index = {{(MAX_STAGE-5){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:5]};   end
            4'd6   :begin out_cnt_max = 12'd63;     N_index = {{(MAX_STAGE-6){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:6]};   end
            4'd7   :begin out_cnt_max = 12'd127;    N_index = {{(MAX_STAGE-7){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:7]};   end
            4'd8   :begin out_cnt_max = 12'd255;    N_index = {{(MAX_STAGE-8){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:8]};   end
            4'd9   :begin out_cnt_max = 12'd511;    N_index = {{(MAX_STAGE-9){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:9]};   end
            4'd10  :begin out_cnt_max = 12'd1023;   N_index = {{(MAX_STAGE-10){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:10]}; end
            4'd11  :begin out_cnt_max = 12'd2047;   N_index = {{(MAX_STAGE-11){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:11]}; end
            4'd12  :begin out_cnt_max = 12'd4095;   N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max = 12'd4095;   N_index = out_cnt_swap;                                             end
            endcase
        end
    end else if(MAX_STAGE==13) begin: N_point_8192  
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max = 13'd3;      N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max = 13'd7;      N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max = 13'd15;     N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max = 13'd31;     N_index = {{(MAX_STAGE-5){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:5]};   end
            4'd6   :begin out_cnt_max = 13'd63;     N_index = {{(MAX_STAGE-6){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:6]};   end
            4'd7   :begin out_cnt_max = 13'd127;    N_index = {{(MAX_STAGE-7){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:7]};   end
            4'd8   :begin out_cnt_max = 13'd255;    N_index = {{(MAX_STAGE-8){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:8]};   end
            4'd9   :begin out_cnt_max = 13'd511;    N_index = {{(MAX_STAGE-9){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:9]};   end
            4'd10  :begin out_cnt_max = 13'd1023;   N_index = {{(MAX_STAGE-10){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:10]}; end
            4'd11  :begin out_cnt_max = 13'd2047;   N_index = {{(MAX_STAGE-11){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:11]}; end
            4'd12  :begin out_cnt_max = 13'd4095;   N_index = {{(MAX_STAGE-12){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:12]}; end
            4'd13  :begin out_cnt_max = 13'd8191;   N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max = 13'd8191;   N_index = out_cnt_swap;                                             end
            endcase
        end
        
    end else if(MAX_STAGE==14) begin: N_point_16384 
     
        always@(*)begin
            case (N_select)
            4'd2   :begin out_cnt_max = 14'd3;      N_index = {{(MAX_STAGE-2){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:2]};   end
            4'd3   :begin out_cnt_max = 14'd7;      N_index = {{(MAX_STAGE-3){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:3]};   end
            4'd4   :begin out_cnt_max = 14'd15;     N_index = {{(MAX_STAGE-4){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:4]};   end
            4'd5   :begin out_cnt_max = 14'd31;     N_index = {{(MAX_STAGE-5){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:5]};   end
            4'd6   :begin out_cnt_max = 14'd63;     N_index = {{(MAX_STAGE-6){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:6]};   end
            4'd7   :begin out_cnt_max = 14'd127;    N_index = {{(MAX_STAGE-7){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:7]};   end
            4'd8   :begin out_cnt_max = 14'd255;    N_index = {{(MAX_STAGE-8){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:8]};   end
            4'd9   :begin out_cnt_max = 14'd511;    N_index = {{(MAX_STAGE-9){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:9]};   end
            4'd10  :begin out_cnt_max = 14'd1023;   N_index = {{(MAX_STAGE-10){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:10]}; end
            4'd11  :begin out_cnt_max = 14'd2047;   N_index = {{(MAX_STAGE-11){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:11]}; end
            4'd12  :begin out_cnt_max = 14'd4095;   N_index = {{(MAX_STAGE-12){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:12]}; end
            4'd13  :begin out_cnt_max = 14'd8191;   N_index = {{(MAX_STAGE-13){1'b0}},out_cnt_swap[(MAX_STAGE-1)-:13]}; end
            4'd14  :begin out_cnt_max = 14'd16383;  N_index = out_cnt_swap;                                             end
            default:begin out_cnt_max = 14'd16383;  N_index = out_cnt_swap;                                             end
            endcase
        end
        
    end  
endgenerate


//out
always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        sig_start_o <= 1'b0;
        sig_vld_o   <= 1'b0;
        sig_real_o  <=  'h0;
        sig_imag_o  <=  'h0;
        N_index_o   <=  'h0;
    end else begin
        sig_vld_o <= stage_0_sig_vld_i;
        N_index_o <= N_index;
        if(stage_0_sig_start_i == 1'b1 && out_cnt == 'h0)begin
            sig_start_o <= 1'b1;
        end else begin
            sig_start_o <= 1'b0;
        end
        if(fft_ifft_select == 1'b0)begin
            sig_real_o  <=  stage_0_sig_real_i;
            sig_imag_o  <=  stage_0_sig_imag_i;
        end else begin
            sig_real_o  <=  stage_0_sig_imag_i;
            sig_imag_o  <=  stage_0_sig_real_i;
        end
    end
end

endmodule
