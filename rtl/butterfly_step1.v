`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/03 11:31:54
// Design Name: 
// Module Name: butterfly_step1
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


module butterfly_step1#(
 parameter DATA_WIDTH = 16
)(
 input                                  clk,
 input                                  rst_n,
 input                                  ab_vld_i,
 input         signed  [DATA_WIDTH-1:0] a_real_i,
 input         signed  [DATA_WIDTH-1:0] a_imag_i,
 input         signed  [DATA_WIDTH-1:0] b_real_i,
 input         signed  [DATA_WIDTH-1:0] b_imag_i,
 output  reg                           cd_vld_o,
 output        signed  [DATA_WIDTH-1:0] c_real_o,
 output        signed  [DATA_WIDTH-1:0] c_imag_o,
 output        signed  [DATA_WIDTH-1:0] d_real_o,
 output        signed  [DATA_WIDTH-1:0] d_imag_o
);
    
wire signed  [DATA_WIDTH:0] a_real;
wire signed  [DATA_WIDTH:0] a_imag;
wire signed  [DATA_WIDTH:0] b_real;
wire signed  [DATA_WIDTH:0] b_imag;

reg  signed  [DATA_WIDTH:0] c_real;
reg  signed  [DATA_WIDTH:0] c_imag;
reg  signed  [DATA_WIDTH:0] d_real;
reg  signed  [DATA_WIDTH:0] d_imag;

//expasion 1 signed bit
assign a_real = {a_real_i[DATA_WIDTH-1],a_real_i};
assign a_imag = {a_imag_i[DATA_WIDTH-1],a_imag_i};
assign b_real = {b_real_i[DATA_WIDTH-1],b_real_i};
assign b_imag = {b_imag_i[DATA_WIDTH-1],b_imag_i};

//truncate 1 bit
assign c_real_o = c_real[DATA_WIDTH:1];
assign c_imag_o = c_imag[DATA_WIDTH:1];
assign d_real_o = d_real[DATA_WIDTH:1];
assign d_imag_o = d_imag[DATA_WIDTH:1];

always@(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)begin
        c_real <= 'h0;
        c_imag <= 'h0;
        d_real <= 'h0;
        d_imag <= 'h0;
        cd_vld_o <= 1'b0;
    end else begin
        cd_vld_o <= ab_vld_i;
        if(ab_vld_i == 1'b1)begin
            c_real <= a_real + b_real;
            c_imag <= a_imag + b_imag;
            d_real <= a_real - b_real;
            d_imag <= a_imag - b_imag;
        end
    end
end
 
endmodule
