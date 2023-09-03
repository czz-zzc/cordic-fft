`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/21 16:51:59
// Design Name: 
// Module Name: cordic_fft_opt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// delay = DATA_WIDTH_EXP + OUT_REGISTER_EN + 1 + 11
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cordic_fft_opt#(
 parameter DATA_WIDTH = 16,
 parameter PHASE_WIDTH = 18
)(
 input                                 clk,
 input                                 rst_n,
 input            [PHASE_WIDTH-1:0]    angle,
 input            [1:0]                quad,
 input    signed  [DATA_WIDTH-1:0]     data_real_i,
 input    signed  [DATA_WIDTH-1:0]     data_imag_i,
 output   signed  [DATA_WIDTH-1:0]     data_real_o,
 output   signed  [DATA_WIDTH-1:0]     data_imag_o
    );

localparam K_NUM = 5;//k = ceil((DATA_WIDTH_EXP - log2(6))/3);
localparam M_NUM = 8;//m = ceil((data_width_s - 1)/2);
localparam EXP = 2;
localparam DATA_WIDTH_EXP = DATA_WIDTH + EXP;
localparam REMAINDER = (DATA_WIDTH + 1 - M_NUM) % 2;
localparam DELAY = 2 + M_NUM + REMAINDER + (DATA_WIDTH - M_NUM)/2;

reg  signed [DATA_WIDTH_EXP:0] data_real_d;
reg  signed [DATA_WIDTH_EXP:0] data_imag_d;
//quadrant map + init reg
always@(posedge clk or negedge rst_n)  
begin
    if(rst_n == 1'b0)begin
        data_real_d <= 'h0;
        data_imag_d <= 'h0;
    end else begin
        case (quad)
            2'b00: begin 
                data_real_d <= {data_imag_i[DATA_WIDTH-1],data_imag_i,{EXP{1'b0}}};
                data_imag_d <= {data_real_i[DATA_WIDTH-1],data_real_i,{EXP{1'b0}}};end
            2'b01: begin 
                data_real_d <= {data_real_i[DATA_WIDTH-1],data_real_i,{EXP{1'b0}}};
                data_imag_d <= {data_imag_i[DATA_WIDTH-1],data_imag_i,{EXP{1'b0}}};end
            2'b10: begin 
                data_real_d <= {data_imag_i[DATA_WIDTH-1],data_imag_i,{EXP{1'b0}}};
                data_imag_d <= {data_real_i[DATA_WIDTH-1],data_real_i,{EXP{1'b0}}};end
            2'b11: begin 
                data_real_d <= {data_real_i[DATA_WIDTH-1],data_real_i,{EXP{1'b0}}};
                data_imag_d <= {data_imag_i[DATA_WIDTH-1],data_imag_i,{EXP{1'b0}}};end
            default: begin 
                data_real_d <= {data_real_i[DATA_WIDTH-1],data_real_i,{EXP{1'b0}}};
                data_imag_d <= {data_imag_i[DATA_WIDTH-1],data_imag_i,{EXP{1'b0}}};end
         endcase
    end
end

reg  signed [DATA_WIDTH_EXP:0]   cos_a_stage1;
reg  signed [DATA_WIDTH_EXP:0]   sin_b_stage1;
reg  signed [DATA_WIDTH_EXP:0]   cos_b_stage1;
reg  signed [DATA_WIDTH_EXP:0]   sin_a_stage1;
reg  signed [DATA_WIDTH_EXP:0]   a_stage1;
reg  signed [DATA_WIDTH_EXP:0]   b_stage1;


//stage1
wire angle_stage1;
fft_delay#(.DATA_WIDTH(1),.DELAY(1)) 
angle_stage1_inst(.clk(clk),.rst_n(rst_n),.data_i(angle[PHASE_WIDTH-1]),.data_o(angle_stage1));
always@(posedge clk or negedge rst_n)  
begin
    if(rst_n == 1'b0)begin
        cos_a_stage1 <= 'h0;
        sin_b_stage1 <= 'h0;
        cos_b_stage1 <= 'h0;
        sin_a_stage1 <= 'h0;
        a_stage1     <= 'h0;
        b_stage1     <= 'h0;
    end else begin
        a_stage1     <= cos_a_stage1 - sin_b_stage1;
        b_stage1     <= cos_b_stage1 + sin_a_stage1;
        if(angle_stage1 == 1'b1)begin
            cos_a_stage1 <= data_real_d - $signed(data_real_d[DATA_WIDTH_EXP:3]) + $signed(data_real_d[DATA_WIDTH_EXP:9]) + $signed(data_real_d[DATA_WIDTH_EXP:11]) + $signed(data_real_d[DATA_WIDTH_EXP:12]);
            sin_b_stage1 <= $signed(data_imag_d[DATA_WIDTH_EXP:1]) - $signed(data_imag_d[DATA_WIDTH_EXP:6]) - $signed(data_imag_d[DATA_WIDTH_EXP:8]) - $signed(data_imag_d[DATA_WIDTH_EXP:10]);
            cos_b_stage1 <= data_imag_d - $signed(data_imag_d[DATA_WIDTH_EXP:3]) + $signed(data_imag_d[DATA_WIDTH_EXP:9]) + $signed(data_imag_d[DATA_WIDTH_EXP:11]) + $signed(data_imag_d[DATA_WIDTH_EXP:12]);
            sin_a_stage1 <= $signed(data_real_d[DATA_WIDTH_EXP:1]) - $signed(data_real_d[DATA_WIDTH_EXP:6]) - $signed(data_real_d[DATA_WIDTH_EXP:8]) - $signed(data_real_d[DATA_WIDTH_EXP:10]);
        end else begin
            cos_a_stage1 <= data_real_d;
            sin_b_stage1 <= 0;
            cos_b_stage1 <= data_imag_d;
            sin_a_stage1 <= 0;
        end
    end
end


//stage2
wire signed [DATA_WIDTH_EXP:0]   cos_a_stage2;
wire signed [DATA_WIDTH_EXP:0]   sin_b_stage2;
wire signed [DATA_WIDTH_EXP:0]   cos_b_stage2;
wire signed [DATA_WIDTH_EXP:0]   sin_a_stage2;
reg  signed [DATA_WIDTH_EXP:0]   a_stage2;
reg  signed [DATA_WIDTH_EXP:0]   b_stage2;
wire                             angle_stage2;

fft_delay#(.DATA_WIDTH(1),.DELAY(3)) 
angle_stage2_inst(.clk(clk),.rst_n(rst_n),.data_i(angle[PHASE_WIDTH-2]),.data_o(angle_stage2));

assign cos_a_stage2 = a_stage1 - $signed(a_stage1[DATA_WIDTH_EXP:5]);
assign sin_b_stage2 = $signed(b_stage1[DATA_WIDTH_EXP:2]) - $signed(b_stage1[DATA_WIDTH_EXP:9]) - $signed(b_stage1[DATA_WIDTH_EXP:11]);
assign cos_b_stage2 = b_stage1 - $signed(b_stage1[DATA_WIDTH_EXP:5]);
assign sin_a_stage2 = $signed(a_stage1[DATA_WIDTH_EXP:2]) - $signed(a_stage1[DATA_WIDTH_EXP:9]) - $signed(a_stage1[DATA_WIDTH_EXP:11]);

always@(posedge clk or negedge rst_n)  
begin
    if(rst_n == 1'b0)begin
        a_stage2     <= 'h0;
        b_stage2     <= 'h0;
    end else begin
        if(angle_stage2 == 1'b1)begin
            a_stage2     <= cos_a_stage2 - sin_b_stage2;
            b_stage2     <= cos_b_stage2 + sin_a_stage2;
        end else begin
            a_stage2     <= a_stage1;
            b_stage2     <= b_stage1;
        end
    end
end

//stage3
wire signed [DATA_WIDTH_EXP:0]   cos_a_stage3;
wire signed [DATA_WIDTH_EXP:0]   sin_b_stage3;
wire signed [DATA_WIDTH_EXP:0]   cos_b_stage3;
wire signed [DATA_WIDTH_EXP:0]   sin_a_stage3;
reg  signed [DATA_WIDTH_EXP:0]   a_stage3;
reg  signed [DATA_WIDTH_EXP:0]   b_stage3;
wire                             angle_stage3;

fft_delay#(.DATA_WIDTH(1),.DELAY(4)) 
angle_stage3_inst(.clk(clk),.rst_n(rst_n),.data_i(angle[PHASE_WIDTH-3]),.data_o(angle_stage3));

assign cos_a_stage3 = a_stage2 - $signed(a_stage2[DATA_WIDTH_EXP:7]);
assign sin_b_stage3 = $signed(b_stage2[DATA_WIDTH_EXP:3]) - $signed(b_stage2[DATA_WIDTH_EXP:12]) - $signed(b_stage2[DATA_WIDTH_EXP:14]);
assign cos_b_stage3 = b_stage2 - $signed(b_stage2[DATA_WIDTH_EXP:7]);
assign sin_a_stage3 = $signed(a_stage2[DATA_WIDTH_EXP:3]) - $signed(a_stage2[DATA_WIDTH_EXP:12]) - $signed(a_stage2[DATA_WIDTH_EXP:14]);

always@(posedge clk or negedge rst_n)  
begin
    if(rst_n == 1'b0)begin
        a_stage3 <= 'h0;
        b_stage3 <= 'h0;
    end else begin
        if(angle_stage3 == 1'b1)begin
            a_stage3 <= cos_a_stage3 - sin_b_stage3;
            b_stage3 <= cos_b_stage3 + sin_a_stage3;
        end else begin
            a_stage3 <= a_stage2;
            b_stage3 <= b_stage2;
        end
    end
end

//stage3
wire signed [DATA_WIDTH_EXP:0]   cos_a_stage4;
wire signed [DATA_WIDTH_EXP:0]   sin_b_stage4;
wire signed [DATA_WIDTH_EXP:0]   cos_b_stage4;
wire signed [DATA_WIDTH_EXP:0]   sin_a_stage4;
reg  signed [DATA_WIDTH_EXP:0]   a_stage4;
reg  signed [DATA_WIDTH_EXP:0]   b_stage4;
wire                             angle_stage4;

fft_delay#(.DATA_WIDTH(1),.DELAY(5)) 
angle_stage4_inst(.clk(clk),.rst_n(rst_n),.data_i(angle[PHASE_WIDTH-4]),.data_o(angle_stage4));

assign cos_a_stage4 = a_stage3 - $signed(a_stage3[DATA_WIDTH_EXP:9]);
assign sin_b_stage4 = $signed(b_stage3[DATA_WIDTH_EXP:4]) - $signed(b_stage3[DATA_WIDTH_EXP:15]);
assign cos_b_stage4 = b_stage3 - $signed(b_stage3[DATA_WIDTH_EXP:9]);
assign sin_a_stage4 = $signed(a_stage3[DATA_WIDTH_EXP:4]) - $signed(a_stage3[DATA_WIDTH_EXP:15]);

always@(posedge clk or negedge rst_n)  
begin
    if(rst_n == 1'b0)begin
        a_stage4 <= 'h0;
        b_stage4 <= 'h0;
    end else begin
        if(angle_stage4 == 1'b1)begin
            a_stage4 <= cos_a_stage4 - sin_b_stage4;
            b_stage4 <= cos_b_stage4 + sin_a_stage4;
        end else begin
            a_stage4 <= a_stage3;
            b_stage4 <= b_stage3;
        end
    end
end


reg  signed [DATA_WIDTH_EXP:0]   k_real[K_NUM:DATA_WIDTH];
reg  signed [DATA_WIDTH_EXP:0]   k_imag[K_NUM:DATA_WIDTH];
wire                             k_angle[K_NUM:DATA_WIDTH];

genvar i;
generate
    for (i = K_NUM ; i < M_NUM; i= i + 1)
    begin: iter_k
        if(i == K_NUM)begin
        
        fft_delay#(.DATA_WIDTH(1),.DELAY(i+1)) 
        angle_stagek_inst(.clk(clk),.rst_n(rst_n),.data_i(angle[PHASE_WIDTH-i]),.data_o(k_angle[i]));
        
        always@(posedge clk or negedge rst_n)begin
            if(rst_n == 1'b0)begin
                k_real[i] <= 'h0;
                k_imag[i] <= 'h0;
            end else begin
                if(k_angle[i]==1'b1)begin //polarity judge
                    k_real[i] <= a_stage4 - $signed(a_stage4[DATA_WIDTH_EXP:(2*i+1)]) - $signed(b_stage4[DATA_WIDTH_EXP:i]);
                    k_imag[i] <= $signed(a_stage4[DATA_WIDTH_EXP:i]) + b_stage4 - $signed(b_stage4[DATA_WIDTH_EXP:(2*i+1)]);
                end else begin
                    k_real[i] <= a_stage4;
                    k_imag[i] <= b_stage4;
                end
            end
        end 
        
        end else begin
        
        fft_delay#(.DATA_WIDTH(1),.DELAY(i+1)) 
        angle_stagek_inst(.clk(clk),.rst_n(rst_n),.data_i(angle[PHASE_WIDTH-i]),.data_o(k_angle[i]));
        
        always@(posedge clk or negedge rst_n)begin
            if(rst_n == 1'b0)begin
                k_real[i] <= 'h0;
                k_imag[i] <= 'h0;
            end else begin
                if(k_angle[i]==1'b1)begin //polarity judge
                    k_real[i] <= k_real[i-1] - $signed(k_real[i-1][DATA_WIDTH_EXP:(2*i+1)]) - $signed(k_imag[i-1][DATA_WIDTH_EXP:i]);
                    k_imag[i] <= $signed(k_real[i-1][DATA_WIDTH_EXP:i]) + k_imag[i-1] - $signed(k_imag[i-1][DATA_WIDTH_EXP:(2*i+1)]);
                end else begin
                    k_real[i] <= k_real[i-1];
                    k_imag[i] <= k_imag[i-1];
                end
            end
        end 
        
        end
    end
endgenerate


       
generate
    for (i = M_NUM ; i <= DATA_WIDTH; i= i + 1)
    begin: iter_m
        if((i % 2) == 0 )begin//ff
        
        fft_delay#(.DATA_WIDTH(1),.DELAY((i-M_NUM)/2 + M_NUM + 1)) 
        angle_stagem_inst(.clk(clk),.rst_n(rst_n),.data_i(angle[PHASE_WIDTH-i]),.data_o(k_angle[i]));
        
        always@(posedge clk or negedge rst_n)begin
            if(rst_n == 1'b0)begin
                k_imag[i] <= 'h0;
                k_real[i] <= 'h0;
            end else begin
                if(k_angle[i]==1'b1)begin //polarity judge
                    k_imag[i] <= k_imag[i-1] + $signed(k_real[i-1][DATA_WIDTH_EXP:i]);
                    k_real[i] <= k_real[i-1] - $signed(k_imag[i-1][DATA_WIDTH_EXP:i]);
                end else begin
                    k_imag[i] <= k_imag[i-1];
                    k_real[i] <= k_real[i-1];
                end
            end
        end 
        
        end else begin//combo
        
        fft_delay#(.DATA_WIDTH(1),.DELAY((i + 1 - M_NUM)/2 + M_NUM + 1)) 
        angle_stagem_inst(.clk(clk),.rst_n(rst_n),.data_i(angle[PHASE_WIDTH-i]),.data_o(k_angle[i]));
        
        always@(*)begin
            if(k_angle[i]==1'b1)begin //polarity judge
                k_imag[i] = k_imag[i-1] + $signed(k_real[i-1][DATA_WIDTH_EXP:i]);
                k_real[i] = k_real[i-1] - $signed(k_imag[i-1][DATA_WIDTH_EXP:i]);
            end else begin
                k_imag[i] = k_imag[i-1];
                k_real[i] = k_real[i-1];
            end
        end 
        
        end
    end
endgenerate

//out
wire            [1:0]                quad_d;
fft_delay#(.DATA_WIDTH(2),.DELAY(DELAY - 1)) 
qual_d_inst(.clk(clk),.rst_n(rst_n),.data_i(quad),.data_o(quad_d));

reg signed [DATA_WIDTH-1:0] cos_r;
reg signed [DATA_WIDTH-1:0] sin_r;
always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        cos_r <= 'h0;
        sin_r <= 'h0;
    end else begin
        case (quad_d)
            2'b00: begin 
                cos_r <=  k_imag[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP];
                sin_r <=  k_real[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP];end
            2'b01: begin 
                cos_r <=  k_imag[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP];
                sin_r <= -$signed(k_real[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP]);end
            2'b10: begin 
                cos_r <=  k_real[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP];
                sin_r <= -$signed(k_imag[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP]);end
            2'b11: begin 
                cos_r <= -$signed(k_real[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP]);
                sin_r <= -$signed(k_imag[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP]);end
            default: begin 
                cos_r <=  k_imag[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP];
                sin_r <=  k_real[DATA_WIDTH][DATA_WIDTH_EXP-1:EXP];end
         endcase
    end
end

assign data_real_o = cos_r;
assign data_imag_o = sin_r;

endmodule