`define TP 0
//`define INITIALIZE_RAMS
//  ------------------------------------------------------------------------
//
//                    (C) COPYRIGHT 2002 - 2016 SYNOPSYS, INC.
//                            ALL RIGHTS RESERVED
//
//  This software and the associated documentation are confidential and
//  proprietary to Synopsys, Inc.  Your use or disclosure of this
//  software is subject to the terms and conditions of a written
//  license agreement between you, or your company, and Synopsys, Inc.
//
// The entire notice above must be reproduced on all authorized copies.
//
//  ------------------------------------------------------------------------

// -------------------------------------------------------------------------
// ---  RCS information:
// ---    $DateTime: 2016/02/18 14:50:28 $
// ---    $Revision: 1.4 $
// ---    $Id: ram2p.v,v 1.4 2020/04/01 12:44:22 xuxiubo Exp $
// -------------------------------------------------------------------------
// --- Module Description:  Generic 2-port synchronous RAM model.
// -----------------------------------------------------------------------------
// --- This will normally be replaced with a vendor-specific RAM.
// -----------------------------------------------------------------------------


module ram2p (
    addra,
    addrb,
    clka,
    clkb,
    dina,
    doutb,
    ena,
    enb,
    wea
);


// -----------------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------------
parameter WD = 8;       // Width of RAM
parameter PW = 12;      // Size of address
parameter DP = (1<<PW); // Depth of RAM (default is power of 2)
parameter RD_LATENCY = 1; // Num clock cycles last access to memory data

input       [PW-1:0]    addra;
input       [PW-1:0]    addrb;
input                   clka;
input                   clkb;
input       [WD-1:0]    dina;
input                   ena;
input                   enb;
input                   wea;
output      [WD-1:0]    doutb;

wire [WD-1:0]           doutb;
reg [WD-1:0]            doutb_int;

reg         [WD-1:0]    mem [0:DP-1];   // The memory array

// Writes
always @(posedge clka)
begin
    if (ena & wea)
        mem[addra]      <= #(`TP) dina;
    if ( ena === 1'b1 && wea === 1'b1 && addra >= DP && DP > 0)
        $display("%t: ERROR: Memory (%m) write address error. Address is %x, Max is %x, DP = 0x%x, PW = 0x%x", $time, addra, DP-1,DP,PW);
end

// Reads

  always @(posedge clkb)
  begin
    if (enb)
        doutb_int           <= #(`TP) mem[addrb];
    else
        // SMD: RHS of the assignment contains 'X'
        // SJ: The assignment of 'X' is part of RAM model
        // spyglass disable_block NoAssignX-ML
        doutb_int           <= #(`TP) {WD{1'bx}};
        // spyglass enable_block NoAssignX-ML
    if ( enb === 1'b1 && addrb >= DP  && DP > 0)
        $display("%t: ERROR: Memory (%m) read address error. Address is %x, Max is %x, DP = 0x%x, PW = 0x%x", $time, addrb, DP-1,DP,PW);
  end


genvar g_reg_elements;
generate
    if (RD_LATENCY > 1) begin 
       reg [WD-1:0] doutb_int_d[RD_LATENCY-2:0]; // Only register the data output if LATENCY >= 2.  

       for(g_reg_elements = 0; g_reg_elements < RD_LATENCY-1; g_reg_elements = g_reg_elements + 1) begin : gen_reg_elements
            always @(posedge clkb) begin
                  if (g_reg_elements == 0) begin
                      doutb_int_d[g_reg_elements]  <= doutb_int; 
                  end else begin
                      doutb_int_d[g_reg_elements]  <= doutb_int_d[g_reg_elements-1];
                  end
            end
       end // for

       assign doutb = doutb_int_d[RD_LATENCY-2];

    end else // !(RD_LATENCY > 1)
       assign doutb = doutb_int; 

endgenerate

`ifdef INITIALIZE_RAMS
integer i;
initial
	begin
        for (i = 0; i<DP; i = i+1) begin

			mem[i]     = {WD{1'b1}};

		end
	end
`endif

initial $display("\n****************************************************");
initial $display("\nRAM Size Information: Instance name =  %m");
initial $display("\nRAM Size Information: RAM depth     =  %d",DP);
initial $display("\nRAM Size Information: RAM width     =  %d",WD);
initial $display("\nRAM Size Information: Address width =  %d",PW);
initial $display("\n****************************************************\n");



endmodule
