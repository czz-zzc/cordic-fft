// $RCSfile: run_bitacc_cmodel.c,v $ $Version: $ $Date: 2010/09/08 12:33:20 $
//
// (c) Copyright 2008-2009 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//-------------------------------------------------------------------
//
// Example code for FFT v8.0 C model
//
//-------------------------------------------------------------------

#include "xfft_v9_1_bitacc_cmodel.h"
#include <iostream>
#include <string>
#include <sstream>

using namespace std;

int main()
{

  // Generics for this smoke test
  // (Any legal combination should work)
  const int C_NFFT_MAX      = 10;
  const int C_ARCH          = 3;
  const int C_USE_FLT_PT    = 0;
  const int C_HAS_NFFT      = 0;
  const int C_INPUT_WIDTH   = 16;
  const int C_TWIDDLE_WIDTH = 16;
  const int C_HAS_SCALING   = 1;
  const int C_HAS_BFP       = 0;
  const int C_HAS_ROUNDING  = 0;

  // Handle multichannel FFTs if required
  const int channels = 1;

  // Declare generic struct and set to generics to test
  struct xilinx_ip_xfft_v9_1_generics generics;
  generics.C_NFFT_MAX      = C_NFFT_MAX;
  generics.C_ARCH          = C_ARCH;
  generics.C_USE_FLT_PT    = C_USE_FLT_PT;
  generics.C_HAS_NFFT      = C_HAS_NFFT;
  generics.C_INPUT_WIDTH   = C_INPUT_WIDTH;
  generics.C_TWIDDLE_WIDTH = C_TWIDDLE_WIDTH;
  generics.C_HAS_SCALING   = C_HAS_SCALING;
  generics.C_HAS_BFP       = C_HAS_BFP;
  generics.C_HAS_ROUNDING  = C_HAS_ROUNDING;

  // Create FFT state
  struct xilinx_ip_xfft_v9_1_state* state = xilinx_ip_xfft_v9_1_create_state(generics);
  if (state == NULL) {
    cerr << "ERROR: could not create FFT state object" << endl;
    return 1;
  }

  // Create structure for FFT inputs and input data arrays
  struct xilinx_ip_xfft_v9_1_inputs inputs;
  // point size
  inputs.nfft = C_NFFT_MAX;
  const int samples = 1 << C_NFFT_MAX;
  double xn_re[samples];
  double xn_im[samples];
  inputs.xn_re = &xn_re[0];
  inputs.xn_re_size = samples;
  inputs.xn_im = &xn_im[0];
  inputs.xn_im_size = samples;

  // Create structure for FFT outputs and output data arrays
  struct xilinx_ip_xfft_v9_1_outputs outputs;
  double xk_re[samples];
  double xk_im[samples];
  outputs.xk_re = &xk_re[0];
  outputs.xk_re_size = samples;
  outputs.xk_im = &xk_im[0];
  outputs.xk_im_size = samples;

  // Loop through channels in a multichannel FFT, if required
  bool all_ok = true;
  for (int c=1; c<=channels; c++) {
    string channel_text;
    if (channels > 1) {
      ostringstream c_str;
      c_str << c;
      channel_text = " for channel " + c_str.str();
    }

    // Create input data frame: constant data
    double constant_input = 0.5;
    int i;
    for (i=0; i<samples; i++) {
      xn_re[i] = constant_input;
      xn_im[i] = 0.0;
    }

    // Set scaling schedule to 1/N : 2 in each stage for radix-4 / streaming, 1 in each stage for radix-2 [Lite]
    const int stages = (C_ARCH == 1 || C_ARCH == 3) ? (C_NFFT_MAX+1)/2 : C_NFFT_MAX;
    const int scaling = (C_ARCH == 1 || C_ARCH == 3) ? 2 : 1;
    int scaling_sch[stages];
    for (i=0; i<stages; i++) {
      if (i == stages-1 && (C_ARCH == 1 || C_ARCH == 3) && inputs.nfft % 2 == 1) {
        // Scaling must be 1 or 0 in the final stage when log2(point size) is odd
        // for Radix-4 or Pipelined Streaming architectures
        scaling_sch[i] = 1;
      } else {
        scaling_sch[i] = scaling;
      }
    }
    inputs.scaling_sch = &scaling_sch[0];
    inputs.scaling_sch_size = stages;

    // Set direction to forward
    inputs.direction = 1;

    // Simulate the FFT
    cout << "Running the C model" << channel_text << "..." << endl;
    if (xilinx_ip_xfft_v9_1_bitacc_simulate(state, inputs, &outputs) != 0) {
      cerr << "ERROR: simulation did not complete successfully" << endl;
      // Destroy the FFT state to free up memory
      xilinx_ip_xfft_v9_1_destroy_state(state);
      return 1;
    } else {
      cout << "Simulation completed successfully" << endl;
    }

    // Check outputs are correct
    // The FFT of constant input data is an impulse
    // Therefore all output samples should be zero except for the first
    // The value of the first sample depends on the type of scaling used
    bool ok = true;

    // Check xk_re_size and xk_im_size
    if (outputs.xk_re_size != samples) {
      cerr << "ERROR:" << channel_text << " xk_re_size is incorrect: expected " << samples << ", actual " << outputs.xk_re_size << endl;
      ok = false;
    }
    if (outputs.xk_im_size != samples) {
      cerr << "ERROR:" << channel_text << " xk_im_size is incorrect: expected " << samples << ", actual " << outputs.xk_im_size << endl;
      ok = false;
    }

    // Check xk_re data: only xk_re[0] should be non-zero
    double expected_xk_re_0;
    if (C_HAS_SCALING == 0) {
      expected_xk_re_0 = constant_input * (1 << C_NFFT_MAX);
    } else {
      expected_xk_re_0 = constant_input;
    }
    if (xk_re[0] != expected_xk_re_0) {
      cerr << "ERROR:" << channel_text << " xk_re[0] is incorrect: expected " << expected_xk_re_0 << ", actual " << xk_re[0] << endl;
      ok = false;
    }
    for (i=1; i<samples; i++) {
      if (xk_re[i] != 0.0) {
        cerr << "ERROR:" << channel_text << " xk_re[" << i << "] is incorrect: expected " << 0.0 << ", actual " << xk_re[i] << endl;
        ok = false;
      }
    }

    // Check xk_im data: all values should be zero
    for (i=1; i<samples; i++) {
      if (xk_im[i] != 0.0) {
        cerr << "ERROR:" << channel_text << " xk_im[" << i << "] is incorrect: expected " << 0.0 << ", actual " << xk_im[i] << endl;
        ok = false;
      }
    }

    // Check blk_exp if used: should be nfft
    if (C_HAS_BFP == 1) {
      if (outputs.blk_exp != inputs.nfft) {
        cerr << "ERROR:" << channel_text << " blk_exp is incorrect: expected " << inputs.nfft << ", actual " << outputs.blk_exp << endl;
        ok = false;
      }
    }

    // Check overflow if used: scaling schedule should ensure that overflow never occurs
    if (C_HAS_SCALING == 1 && C_HAS_BFP == 0) {
      if (outputs.overflow != 0) {
        cerr << "ERROR:" << channel_text << " overflow is incorrect: expected " << 0 << ", actual " << outputs.overflow << endl;
        ok = false;
      }
    }

    // That's all of the checks done
    if (ok) {
      cout << "Outputs from simulation" << channel_text << " are correct" << endl;
    } else {
      cout << "Some outputs from simulation" << channel_text << " are incorrect" << endl;
    }

    // Repeat for all channels
    all_ok = all_ok && ok;
  }

  // Destroy the FFT state to free up memory
  xilinx_ip_xfft_v9_1_destroy_state(state);

  // Return value indicates if all outputs of all channels were correct
  if (all_ok) {
    return 0;
  } else {
    return 1;
  }

}
