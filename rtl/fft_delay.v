`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/10 09:44:45
// Design Name: 
// Module Name: fft_delay
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
module fft_delay#(
parameter DATA_WIDTH = 16,
parameter DELAY = 2
)(
input                          clk,
input                          rst_n,
input   [DATA_WIDTH-1:0]       data_i,
output  [DATA_WIDTH-1:0]       data_o
   );

reg  [DATA_WIDTH-1:0]       data_d[0:DELAY-1];
generate
    if (DELAY==0) begin: delay_0
        
        assign data_o = data_i;
        
    end else begin: delay_big_0
    
        assign data_o = data_d[DELAY-1];
     
        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0)begin
                data_d[0] <= 'h0;
            end else begin
                data_d[0] <= data_i;
            end
        end
    end
endgenerate



genvar i;
generate
    for (i=1; i < DELAY; i= i+1)
    begin:delay
        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0)begin
                data_d[i]  <= 'h0;
            end else begin
                data_d[i]  <= data_d[i-1];
            end
        end
    end
endgenerate



endmodule