`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/03 17:34:04
// Design Name: 
// Module Name: butterfly_stepn
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


module butterfly_stepn_opt#(
 parameter DATA_WIDTH = 16,
 parameter PHASE_WIDTH = 24,
 parameter ADDR_WIDTH = 11,
 parameter ANGEL_STEP = 402,
 parameter ANGEL_PI_4 = 205887,
 parameter CORDIC_DELAY = 15
)(
 input                            clk,
 input                            rst_n,
 input           [ADDR_WIDTH-1:0] addr,
 input                            ab_vld_i,
 input   signed  [DATA_WIDTH-1:0] a_real_i,
 input   signed  [DATA_WIDTH-1:0] a_imag_i,
 input   signed  [DATA_WIDTH-1:0] b_real_i,
 input   signed  [DATA_WIDTH-1:0] b_imag_i,
 
 output                           c_vld_o,
 output                           d_vld_o,
 output  signed  [DATA_WIDTH-1:0] c_real_o,
 output  signed  [DATA_WIDTH-1:0] c_imag_o,
 output  signed  [DATA_WIDTH-1:0] d_real_o,
 output  signed  [DATA_WIDTH-1:0] d_imag_o
    );       

wire                            c_vld;
wire   signed  [DATA_WIDTH-1:0] mid_real;
wire   signed  [DATA_WIDTH-1:0] mid_imag;
reg                             c_vld_delay[0:CORDIC_DELAY-1];
assign c_vld_o = c_vld;
butterfly_step1#(
.DATA_WIDTH         ( DATA_WIDTH     )
)butterfly_step1_inst(
.clk                ( clk            ),
.rst_n              ( rst_n          ),
.ab_vld_i           ( ab_vld_i       ),
.a_real_i           ( a_real_i       ),
.a_imag_i           ( a_imag_i       ),
.b_real_i           ( b_real_i       ),
.b_imag_i           ( b_imag_i       ),
.cd_vld_o           ( c_vld          ),
.c_real_o           ( c_real_o       ),
.c_imag_o           ( c_imag_o       ),
.d_real_o           ( mid_real       ),
.d_imag_o           ( mid_imag       )
);

//generate vld
always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        c_vld_delay[0] <= 1'b0;
    end else begin
        c_vld_delay[0] <= c_vld;
    end
end

genvar i;
generate
    for (i=1; i < CORDIC_DELAY; i= i+1)
    begin:delay
        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0)begin
                c_vld_delay[i] <= 'h0;
            end else begin
                c_vld_delay[i] <= c_vld_delay[i-1];
            end
        end
    end
endgenerate

assign d_vld_o = c_vld_delay[CORDIC_DELAY-1];

reg            [PHASE_WIDTH-1:0]    angle;
reg            [1:0]                quad;

generate
    if (ADDR_WIDTH > 2) begin:big
    always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        angle <= 'h0;
        quad  <= 'h0;
    end else begin
        case(addr[ADDR_WIDTH-1:ADDR_WIDTH-2])
            2'b00: begin 
                quad <= 2'b00;
                if((|addr[ADDR_WIDTH-3:0])==1'b0)begin
                    angle <= 'h0;
                end else begin
                    angle <= angle + ANGEL_STEP;
                end
            end
            2'b01: begin 
                quad <= 2'b01;
                if((|addr[ADDR_WIDTH-3:0])==1'b0)begin
                    angle <= ANGEL_PI_4;
                end else begin
                    angle <= angle - ANGEL_STEP;
                end
            end
            2'b10: begin 
                quad <= 2'b10;
                if((|addr[ADDR_WIDTH-3:0])==1'b0)begin
                    angle <= 'h0;
                end else begin
                    angle <= angle + ANGEL_STEP;
                end
            end
            2'b11: begin 
                quad <= 2'b11;
                if((|addr[ADDR_WIDTH-3:0])==1'b0)begin
                    angle <= ANGEL_PI_4;
                end else begin
                    angle <= angle - ANGEL_STEP;
                end
            end
            default: begin 
                quad <= 2'b00;
                if((|addr[ADDR_WIDTH-3:0])==1'b0)begin
                    angle <= 'h0;
                end else begin
                    angle <= angle + ANGEL_STEP;
                end
            end
        endcase
    end
    end
    
    end else if (ADDR_WIDTH==2) begin: mid
    
    always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        angle <= 'h0;
        quad  <= 'h0;
    end else begin
        case(addr[ADDR_WIDTH-1:ADDR_WIDTH-2])
            2'b00: begin 
                quad <= 2'b00;
                angle <= 'h0; 
            end
            2'b01: begin 
                quad <= 2'b01;
                angle <= ANGEL_PI_4;
            end
            2'b10: begin 
                quad <= 2'b10;
                angle <= 'h0;
            end
            2'b11: begin 
                quad <= 2'b11;
                angle <= ANGEL_PI_4;
            end
            default: begin 
                quad <= 2'b00;
                angle <= 'h0; 
            end
        endcase
    end
    end
    
    end else begin: smal
    
    always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        angle <= 'h0;
        quad  <= 'h0;
    end else begin
        case(addr)
            1'b0: begin 
                quad <= 2'b00;
                angle <= 'h0; 
            end
            1'b1: begin 
                quad <= 2'b10;
                angle <=  'h0;
            end
            default: begin 
                quad <= 2'b00;
                angle <= 'h0; 
            end
        endcase
    end
    end
    
    end
endgenerate


cordic_fft_opt#(
.DATA_WIDTH         ( DATA_WIDTH     ),
.PHASE_WIDTH        ( PHASE_WIDTH    )
)cordic_fft_inst(
.clk                ( clk            ),
.rst_n              ( rst_n          ),
.angle              ( angle          ),
.quad               ( quad           ),
.data_real_i        ( mid_real       ),
.data_imag_i        ( mid_imag       ),
.data_real_o        ( d_real_o       ),
.data_imag_o        ( d_imag_o       )
);

endmodule
