// $RCSfile: xfft_v9_1_bitacc_mex.cpp,v $ $Version: $ $Date: 2010/09/08 12:33:22 $
//
//  (c) Copyright 2007-2009 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES. 
//-------------------------------------------------------------------

// C model for xfft_v9_1.  Matlab MEX interface.

//-------------------------------------------------------------------

#include "mex.h"
#include "matrix.h"
#include <string.h>
#include <float.h>
#include <math.h>
#include "xfft_v9_1_bitacc_cmodel.h"

//Types and functions to help with checks on floating point inputs
typedef unsigned int u32;
typedef union
{ u32 i;
  float f;
} f32conv;

const u32 exp_mask=2139095040;
const u32 sign_mask=2147483648;
const u32 mant_mask=8388607;

int is_nan(float x) {
  f32conv flt_to_int;
  flt_to_int.f=x;
  if ( ((flt_to_int.i & exp_mask) == exp_mask) && ((flt_to_int.i & mant_mask) != 0) ) {
    //Exponent is all ones and the mantissa is non-zero so is a NaN, sign doens't matter
    return 1;
  }
  return 0;
}

int is_inf(float x) {
  f32conv flt_to_int;
  flt_to_int.f=x;
  if ( ((flt_to_int.i & exp_mask) == exp_mask) && ((flt_to_int.i & mant_mask) == 0) ) {
    //Exponent is all ones and the mantissa is zero so is a Inf, sign doens't matter
    return 1;
  }
  return 0;
}

// The FFT core's state must persist from one MEX function call to the next,
// and the pointer to the state must be available to both the MEX function
// and the exit function that destroys the state on Matlab exit.
// Therefore the state pointer must be a static global variable.
static xilinx_ip_xfft_v9_1_state* xfft_v9_1_state;


// Exit function that Matlab will call before it exits, to free the memory
// used by the persistent state structure
static void xfft_v9_1_mex_exit(void)
{
  // Destroy the state to free up memory, if the state exists
  if (xfft_v9_1_state != NULL) {
    // mexPrintf("DEBUG: in xfft_v9_1_mex_exit, destroying state structure\n");
    xilinx_ip_xfft_v9_1_destroy_state(xfft_v9_1_state);
  }
}


// The FFT v8.0 MEX function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // Keep track of the generics used to create the persistent state
  // so we can work out if a call to the MEX function uses the same
  // generics and hence can use the same state.
  // This generics structure must be static so that it persists from
  // one MEX function call to the next.
  static xilinx_ip_xfft_v9_1_generics state_generics;

  // Constants defining number of arguments to/from the MEX function and their positions
  const unsigned char NUM_LHS_ARGS       = 3;
  const unsigned char NUM_RHS_ARGS       = 5;
  const unsigned char LHS_OUTPUTDATA_ARG = 0;
  const unsigned char LHS_BLKEXP_ARG     = 1;
  const unsigned char LHS_OVERFLOW_ARG   = 2;
  const unsigned char RHS_GENERICS_ARG   = 0;
  const unsigned char RHS_NFFT_ARG       = 1;
  const unsigned char RHS_INPUTDATA_ARG  = 2;
  const unsigned char RHS_SCALINGSCH_ARG = 3;
  const unsigned char RHS_DIRECTION_ARG  = 4;

  // Number of fields in the generics structure
  const char NUM_GENERICS_FIELDS = 9;

  // Check number of input and output arguments and print usage if wrong
  if (nlhs != NUM_LHS_ARGS || nrhs != NUM_RHS_ARGS) {
    mexErrMsgTxt(
"usage: [output_data, blk_exp, overflow] = xfft_v9_1_bitacc_mex(generics, nfft, input_data, scaling_sch, direction)\n"
"  Inputs:\n"
"    generics : single-element, 9-field structure containing all relevant generics defining the core:\n"
"      generics.C_NFFT_MAX      - log2(maximum transform length): 3-16\n"
"      generics.C_ARCH          - Architecture:\n"
"                                 1 = Radix-4, Burst I/O,        2 = Radix-2, Burst I/O,\n"
"                                 3 = Pipelined, Streaming I/O,  4 = Radix-2 Lite, Burst I/O\n"
"      generics.C_HAS_NFFT      - Run-time configurable transform length: 0=no, 1=yes\n"
"      generics.C_USE_FLT_PT    - Type of data format: 0 = fixed point, 1 = single precision floating point\n"
"      generics.C_INPUT_WIDTH   - Input data width: 8-34 bits (32 when C_USE_FLT_PT = 1)\n"
"      generics.C_TWIDDLE_WIDTH - Twiddle factor width: 8-34 bits (24 or 25 when C_USE_FLT_PT = 1)\n"
"      generics.C_HAS_SCALING   - Type of scaling: 0 = unscaled, 1 = determined by C_HAS_BFP (1 when C_USE_FLT_PT = 1)\n"
"      generics.C_HAS_BFP       - Type of scaling if C_HAS_SCALING=1: 0 = fixed scaling, 1 = block floating point (0 when C_USE_FLT_PT = 1)\n"
"      generics.C_HAS_ROUNDING  - Type of rounding: 0 = truncation, 1 = convergent rounding (0 when C_USE_FLT_PT = 1)\n"
"    nfft : Single integer. log2(transform length) for this transform. Maximum value is C_NFFT_MAX. Minimum\n"
"      value is 6 for Radix-4 architecture or 3 for other architectures. Only used for run-time configurable\n"
"      transform length (C_HAS_NFFT=1) - ignored otherwise and C_NFFT_MAX used instead.\n"
"    input_data : 1D array of complex data with 2^nfft elements. All components must be -1.0 <= data < +1.0. To\n"
"      ensure identical numerical behavior to the hardware, pre-quantize the data values to have precision\n"
"      determined by C_INPUT_WIDTH.\n"
"    scaling_sch : 1D array of integer values size S = number of stages. For Radix-4 and Streaming architectures,\n"
"      S = nfft/2, rounded up to the next integer.  For Radix-2 and Radix-2 Lite architectures, S = nfft.\n"
"      Each value corresponds to scaling to be performed by the corresponding stage, and must be in the range\n"
"      0 to 3. Only used for fixed scaling (if C_HAS_SCALING=1 and C_HAS_BFP=0) - ignored otherwise.\n"
"      scaling_sch[0] is the scaling for the first FFT stage\n"
"    direction : Single integer. Transform direction: 1=forward FFT, 0=inverse FFT (IFFT).\n"
"  Outputs:\n"
"    output_data : 1D array of complex data with 2^nfft elements.\n"
"    blk_exp : Single integer. Block exponent. Only valid if using block floating point (if C_HAS_SCALING=1\n"
"      and C_HAS_BFP=1). Will be zero otherwise.\n"
"    overflow : Single integer. 1 indicates overflow occurred, 0 indicates no overflow occurred. Only valid if\n"
"      using fixed scaling (if C_HAS_SCALING=1 and C_HAS_BFP=0). Will be zero otherwise.\n"
);
  }

  // Check input (right-hand side) arguments are the correct format and have legal values
  // generics
  if (!mxIsStruct(prhs[RHS_GENERICS_ARG]))
    mexErrMsgTxt("Error: generics parameter must be a structure");
  if (mxGetNumberOfFields(prhs[RHS_GENERICS_ARG]) != NUM_GENERICS_FIELDS)
    mexErrMsgTxt("Error: generics parameter structure has the wrong number of fields");
  if (mxGetNumberOfDimensions(prhs[RHS_GENERICS_ARG]) != 2)
    mexErrMsgTxt("Error: generics parameter must be a single structure, not an array of structures");
  if (mxGetM(prhs[RHS_GENERICS_ARG]) != 1)
    mexErrMsgTxt("Error: generics parameter must be a single structure, not an array of structures");
  if (mxGetN(prhs[RHS_GENERICS_ARG]) != 1)
    mexErrMsgTxt("Error: generics parameter must be a single structure, not an array of structures");
  char field_num;
  for (field_num=0; field_num<NUM_GENERICS_FIELDS; field_num++) {
    const char* field_name = mxGetFieldNameByNumber(prhs[RHS_GENERICS_ARG], field_num);
    if (field_name == NULL)
      mexErrMsgTxt("Error: internal error when getting field names of generics structure - please contact Xilinx Support");
    if (strcmp(field_name, "C_NFFT_MAX") != 0 &&
        strcmp(field_name, "C_ARCH") != 0 &&
        strcmp(field_name, "C_HAS_NFFT") != 0 &&
        strcmp(field_name, "C_INPUT_WIDTH") != 0 &&
        strcmp(field_name, "C_TWIDDLE_WIDTH") != 0 &&
        strcmp(field_name, "C_HAS_SCALING") != 0 &&
        strcmp(field_name, "C_HAS_BFP") != 0 &&
        strcmp(field_name, "C_HAS_ROUNDING") != 0 &&
        strcmp(field_name, "C_USE_FLT_PT") != 0)
      mexErrMsgTxt("Error: generics parameter structure has an unrecognised field name");
  }

  xilinx_ip_xfft_v9_1_generics generics;
  double input_val = mxGetScalar(mxGetField(prhs[RHS_GENERICS_ARG], 0, "C_NFFT_MAX"));
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: generics.C_NFFT_MAX parameter is not an integer");
  generics.C_NFFT_MAX = (int)input_val;
  input_val = mxGetScalar(mxGetField(prhs[RHS_GENERICS_ARG], 0, "C_ARCH"));
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: generics.C_ARCH parameter is not an integer");
  generics.C_ARCH = (int)input_val;
  input_val = mxGetScalar(mxGetField(prhs[RHS_GENERICS_ARG], 0, "C_HAS_NFFT"));
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: generics.C_HAS_NFFT parameter is not an integer");
  generics.C_HAS_NFFT = (int)input_val;
  input_val = mxGetScalar(mxGetField(prhs[RHS_GENERICS_ARG], 0, "C_USE_FLT_PT"));
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: generics.C_USE_FLT_PT parameter is not an integer");
  generics.C_USE_FLT_PT = (int)input_val;
  input_val = mxGetScalar(mxGetField(prhs[RHS_GENERICS_ARG], 0, "C_INPUT_WIDTH"));
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: generics.C_INPUT_WIDTH parameter is not an integer");
  generics.C_INPUT_WIDTH = (int)input_val;
  input_val = mxGetScalar(mxGetField(prhs[RHS_GENERICS_ARG], 0, "C_TWIDDLE_WIDTH"));
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: generics.C_TWIDDLE_WIDTH parameter is not an integer");
  generics.C_TWIDDLE_WIDTH = (int)input_val;
  input_val = mxGetScalar(mxGetField(prhs[RHS_GENERICS_ARG], 0, "C_HAS_SCALING"));
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: generics.C_HAS_SCALING parameter is not an integer");
  generics.C_HAS_SCALING = (int)input_val;
  input_val = mxGetScalar(mxGetField(prhs[RHS_GENERICS_ARG], 0, "C_HAS_BFP"));
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: generics.C_HAS_BFP parameter is not an integer");
  generics.C_HAS_BFP = (int)input_val;
  input_val = mxGetScalar(mxGetField(prhs[RHS_GENERICS_ARG], 0, "C_HAS_ROUNDING"));
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: generics.C_HAS_ROUNDING parameter is not an integer");
  generics.C_HAS_ROUNDING = (int)input_val;

  // mexPrintf("DEBUG: generic values are:\nC_NFFT_MAX = %d\nC_ARCH = %d\nC_HAS_NFFT = %d\nC_INPUT_WIDTH = %d\nC_TWIDDLE_WIDTH = %d\nC_HAS_SCALING = %d\nC_HAS_BFP = %d\nC_HAS_ROUNDING = %d\nC_USE_FLT_PT = %d\n", generics.C_NFFT_MAX, generics.C_ARCH, generics.C_HAS_NFFT, generics.C_INPUT_WIDTH, generics.C_TWIDDLE_WIDTH, generics.C_HAS_SCALING, generics.C_HAS_BFP, generics.C_HAS_ROUNDING, generics.C_USE_FLT_PT);

  // Check generics all have legal values
  if (generics.C_NFFT_MAX < 3 || generics.C_NFFT_MAX > 16)
    mexErrMsgTxt("Error: generics.C_NFFT_MAX parameter is invalid: must be in the range 3 to 16");
  if (generics.C_ARCH < 1 || generics.C_ARCH > 4)
    mexErrMsgTxt("Error: generics.C_ARCH parameter is invalid: must be in the range 1 to 4");
  if (generics.C_HAS_NFFT < 0 || generics.C_HAS_NFFT > 1)
    mexErrMsgTxt("Error: generics.C_HAS_NFFT parameter is invalid: must be in the range 0 to 1");
  if (generics.C_USE_FLT_PT == 0) { 
    if (generics.C_INPUT_WIDTH < 8 || generics.C_INPUT_WIDTH > 34)
      mexErrMsgTxt("Error: generics.C_INPUT_WIDTH parameter is invalid: must be in the range 8 to 34");
  } else {
    if (generics.C_INPUT_WIDTH < 32 || generics.C_INPUT_WIDTH > 32)
      mexErrMsgTxt("Error: generics.C_INPUT_WIDTH parameter is invalid: must be 32");
  }
  if (generics.C_TWIDDLE_WIDTH < 8 || generics.C_TWIDDLE_WIDTH > 34)
    mexErrMsgTxt("Error: generics.C_TWIDDLE_WIDTH parameter is invalid: must be in the range 8 to 34");
  if (generics.C_HAS_SCALING < 0 || generics.C_HAS_SCALING > 1)
    mexErrMsgTxt("Error: generics.C_HAS_SCALING parameter is invalid: must be in the range 0 to 1");
  if (generics.C_HAS_BFP < 0 || generics.C_HAS_BFP > 1)
    mexErrMsgTxt("Error: generics.C_HAS_BFP parameter is invalid: must be in the range 0 to 1");
  if (generics.C_HAS_ROUNDING < 0 || generics.C_HAS_ROUNDING > 1)
    mexErrMsgTxt("Error: generics.C_HAS_ROUNDING parameter is invalid: must be in the range 0 to 1");
  if (generics.C_USE_FLT_PT < 0 || generics.C_USE_FLT_PT > 1)
    mexErrMsgTxt("Error: generics.C_USE_FLT_PT parameter is invalid: must be in the range 0 to 1");

  // Check combinations of generics are legal
  // Radix-4 architecture has minimum point size of 64
  if (generics.C_NFFT_MAX < 6 && generics.C_ARCH == 1)
    mexErrMsgTxt("Error: generics.C_NFFT_MAX < 6 (transform length less than 2^6 = 64) and generics.C_ARCH = 1 (Radix-4, Burst I/O architecture): \n"
                 "    this architecture has a minimum transform length of 64, so C_NFFT_MAX must be 6 or greater.");
  // Variable point size is nonsensical with minimum point size
  if (generics.C_NFFT_MAX == 3 && generics.C_HAS_NFFT == 1)
    mexErrMsgTxt("Error: generics.C_NFFT_MAX = 3 (transform length of 2^3 = 8) and generics.C_HAS_NFFT = 1 (run-time configurable transform length): \n"
                 "    the minimum transform length of 8 cannot be run-time configurable as it cannot be reduced.");
  // Variable point size is nonsensical with minimum point size: special case in radix-4
  if (generics.C_NFFT_MAX == 6 && generics.C_ARCH == 1 && generics.C_HAS_NFFT == 1)
    mexErrMsgTxt("Error: generics.C_NFFT_MAX = 6 (transform length of 2^6 = 64) and generics.C_HAS_NFFT = 1 (run-time configurable transform length) \n"
                 "    and generics.C_ARCH = 1 (Radix-4, Burst I/O architecture): the minimum transform length of 64 \n"
                 "    in this architecture cannot be run-time configurable as it cannot be reduced.");
  // The combination C_HAS_SCALING = 0, C_HAS_BFP = 1 does not specify a scaling type
  if (generics.C_HAS_SCALING == 0 && generics.C_HAS_BFP == 1)
    mexErrMsgTxt("Error: generics.C_HAS_SCALING = 0 (unscaled) and generics.C_HAS_BFP = 1 (block floating point scaling): \n"
                 "    these contradict and do not specify a valid scaling option.");
  
  // nfft
  int nfft;
  if (generics.C_HAS_NFFT == 1) {  // nfft parameter is used
    if (!mxIsNumeric(prhs[RHS_NFFT_ARG]))
      mexErrMsgTxt("Error: nfft parameter must be a single integer");
    if (mxGetNumberOfDimensions(prhs[RHS_NFFT_ARG]) != 2)
      mexErrMsgTxt("Error: nfft parameter must be a single integer, not an array");
    if (mxGetM(prhs[RHS_NFFT_ARG]) != 1)
      mexErrMsgTxt("Error: nfft parameter must be a single integer, not an array");
    if (mxGetN(prhs[RHS_NFFT_ARG]) != 1)
      mexErrMsgTxt("Error: nfft parameter must be a single integer, not an array");

    input_val = mxGetScalar(prhs[RHS_NFFT_ARG]);
    if (input_val != floor(input_val))
      mexErrMsgTxt("Error: nfft parameter is not an integer");
    nfft = (int)input_val;
    if (generics.C_ARCH == 1) {
      if (nfft < 6 || nfft > generics.C_NFFT_MAX)
        mexErrMsgTxt("Error: nfft parameter is invalid: must be in the range 6 to generics.C_NFFT_MAX when generics.C_ARCH = 1 (Radix-4, Burst I/O architecture)");
    } else {
      if (nfft < 3 || nfft > generics.C_NFFT_MAX)
        mexErrMsgTxt("Error: nfft parameter is invalid: must be in the range 3 to generics.C_NFFT_MAX");
    }
  } else {  // nfft parameter is ignored
    if (mxIsNumeric(prhs[RHS_NFFT_ARG])) {
      input_val = mxGetScalar(prhs[RHS_NFFT_ARG]);
      if ((int)input_val != generics.C_NFFT_MAX)
        mexPrintf("Warning: nfft parameter will be ignored because generics.C_HAS_NFFT = 0 (not run-time configurable transform length):\n"
                  "    transform length is determined by generics.C_NFFT_MAX\n");
    }
    nfft = generics.C_NFFT_MAX;
  }

  // input_data
  if (mxGetNumberOfDimensions(prhs[RHS_INPUTDATA_ARG]) != 2)
    mexErrMsgTxt("Error: input_data parameter must be a one-dimensional array");
  // don't care if it's a column vector or row vector, as long as it's not two-dimensional
  const int input_data_rows    = mxGetM(prhs[RHS_INPUTDATA_ARG]);
  const int input_data_columns = mxGetN(prhs[RHS_INPUTDATA_ARG]);
  if (input_data_rows != 1 && input_data_columns != 1)
    mexErrMsgTxt("Error: input_data parameter must be a one-dimensional array");
  const int input_data_size = input_data_rows * input_data_columns;  // get maximum - at least one of these is 1
  if (input_data_size != (1 << nfft))
    mexErrMsgTxt("Error: input_data parameter is the wrong size: it must be a one-dimensional array with 2^nfft elements");
  if (!mxIsNumeric(prhs[RHS_INPUTDATA_ARG]))
    mexErrMsgTxt("Error: input_data parameter must be an array of floating-point numbers");
  bool input_is_complex = true;
  if (!mxIsComplex(prhs[RHS_INPUTDATA_ARG])) {
    #ifndef NO_WARNINGS
    mexPrintf("Warning: input_data parameter is an array of real-only numbers. Imaginary parts of the input to the FFT will be set to zero.\n");
    #endif
    input_is_complex = false;
  }

  // Check input data is in correct range
  double* input_data_re = mxGetPr(prhs[RHS_INPUTDATA_ARG]);
  double* input_data_im = mxGetPi(prhs[RHS_INPUTDATA_ARG]);  // NULL if input_is_complex == false
  int sample;
  for (sample=0; sample<input_data_size; sample++) {
    if (generics.C_USE_FLT_PT == 0) {
      if (input_data_re[sample] < -1.0 || input_data_re[sample] >= 1.0) {
        mexErrMsgTxt("Error: all values in input_data array must be in the range -1.0 <= value < +1.0");
      }
      if (input_is_complex) {
        if (input_data_im[sample] < -1.0 || input_data_im[sample] >= 1.0) {
          mexErrMsgTxt("Error: all values in input_data array must be in the range -1.0 <= value < +1.0");
        }
      }
    } else {      
      f32conv flt_to_int;
    
      if ( (input_data_re[sample] > FLT_MAX || input_data_re[sample] < -FLT_MAX) && !is_inf(float(input_data_re[sample])) ) {
        mexErrMsgTxt("Error: all values in input_data array must be in the range supported by single precision floating point");
      }
      
      //Check for denormalized numbers in input data
      flt_to_int.f=float(input_data_re[sample]);
      if ( (flt_to_int.i & exp_mask) == 0 && (flt_to_int.i & mant_mask) != 0 ) {
        //exponent is zero and mantissa is non-zero so denormalized number
        //Set to zero
        input_data_re[sample]=0;
        mexPrintf("Warning: a denormalized value is present in input_data array. This value will be set to zero\n");
      }
      //Look for invalid or infinite values on the input data
      if (is_nan(float(input_data_re[sample])) || is_inf(float(input_data_re[sample]))) {
        mexPrintf("Warning: a value in the input_data array is set to inf or NaN, the output will be invalidated\n");
      }
      
      if (input_is_complex) {
        if ( (input_data_im[sample] > FLT_MAX || input_data_im[sample] < -FLT_MAX) && !is_inf(float(input_data_im[sample])) ) {
          mexErrMsgTxt("Error: all values in input_data array must be in the range supported by single precision floating point");
        }
        
        //Check for denormalized numbers in input data
        flt_to_int.f=float(input_data_im[sample]);
        if ( (flt_to_int.i & exp_mask) == 0 && (flt_to_int.i & mant_mask) != 0 ) {
          //exponent is zero and mantissa is non-zero so denormalized number
          //Set to zero
          input_data_im[sample]=0;
          mexPrintf("Warning: a denormalized value is present in input_data array. This value will be set to zero\n");
        }
        //Look for invalid or infinite values on the input data
        if (is_nan(float(input_data_im[sample])) || is_inf(float(input_data_im[sample]))) {
          mexPrintf("Warning: a value in the input_data array is set to inf or NaN, the output will be invalidated\n");
        }
      }
    }
  }

  // scaling_sch
  bool has_fixed_scaling = false;
  double* scaling_sch_dbl;
  const char stages = (generics.C_ARCH == 1 || generics.C_ARCH == 3) ? (nfft+1)/2 : nfft;
  if (generics.C_HAS_SCALING == 1 && generics.C_HAS_BFP == 0 && generics.C_USE_FLT_PT == 0) {  // scaling_sch parameter is used
    has_fixed_scaling = true;
    if (mxGetNumberOfDimensions(prhs[RHS_SCALINGSCH_ARG]) != 2)
      mexErrMsgTxt("Error: scaling_sch parameter must be a one-dimensional array");
    // don't care if it's a column vector or row vector, as long as it's not two-dimensional
    const char scaling_sch_rows    = mxGetM(prhs[RHS_SCALINGSCH_ARG]);
    const char scaling_sch_columns = mxGetN(prhs[RHS_SCALINGSCH_ARG]);
    if (scaling_sch_rows != 1 && scaling_sch_columns != 1)
      mexErrMsgTxt("Error: scaling_sch parameter must be a one-dimensional array");
    const char scaling_sch_size = scaling_sch_rows * scaling_sch_columns;  // get maximum - at least one of these is 1
    if (scaling_sch_size < stages)
      mexErrMsgTxt("Error: scaling_sch parameter is too small: it must be a one-dimensional array with elements = stages = \n"
                   "    nfft for Radix-2, Burst I/O (C_ARCH = 2) and Radix-2 Lite, Burst I/O (C_ARCH = 4) architectures, \n"
                   "    nfft/2 rounded up for Radix-4, Burst I/O (C_ARCH = 1) and Pipelined, Streaming I/O (C_ARCH = 3) architectures");
    if (scaling_sch_size > stages)
      mexPrintf("Warning: scaling_sch array is larger than required: it has more elements than stages = \n"
                "    nfft for Radix-2, Burst I/O (C_ARCH = 2) and Radix-2 Lite, Burst I/O (C_ARCH = 4) architectures, \n"
                "    nfft/2 rounded up for Radix-4, Burst I/O (C_ARCH = 1) and Pipelined, Streaming I/O (C_ARCH = 3) architectures.\n"
                "    Only the first (stages) elements will be used; other elements will be ignored.\n");
    if (!mxIsNumeric(prhs[RHS_SCALINGSCH_ARG]))
      mexErrMsgTxt("Error: scaling_sch parameter must be an array of integers");

    // Check elements of scaling_sch that we will use are in the correct range
    scaling_sch_dbl = mxGetPr(prhs[RHS_SCALINGSCH_ARG]);
    unsigned char scale_stage;
    for (scale_stage=0; scale_stage<stages; scale_stage++) {
      int scaling_sch_int = (int)(scaling_sch_dbl[scale_stage]);
      if ((double)scaling_sch_int != scaling_sch_dbl[scale_stage])
        mexErrMsgTxt("Error: values in scaling_sch array must be integers");
      if (scaling_sch_int < 0 || scaling_sch_int > 3)
        mexErrMsgTxt("Error: values in scaling_sch array must be in the range 0 to 3");
    }
    // A Radix-4 or Streaming architecture with odd nfft can only scale by 0 or 1 in its final stage
    if ((generics.C_ARCH == 1 || generics.C_ARCH == 3) &&
        (nfft % 2 == 1) &&
        ((int)(scaling_sch_dbl[stages - 1]) > 1))
      mexErrMsgTxt("Error: with the Radix-4, Burst I/O (C_ARCH = 1) and Pipelined, Streaming I/O (C_ARCH = 3) architectures,\n"
                   "    when nfft is odd, the value in scaling_sch array corresponding to the final stage must be 0 or 1");
  }

  // direction
  char direction;
  if (!mxIsNumeric(prhs[RHS_DIRECTION_ARG]))
    mexErrMsgTxt("Error: direction parameter must be a single integer");
  if (mxGetNumberOfDimensions(prhs[RHS_DIRECTION_ARG]) != 2)
    mexErrMsgTxt("Error: direction parameter must be a single integer, not an array");
  if (mxGetM(prhs[RHS_DIRECTION_ARG]) != 1)
    mexErrMsgTxt("Error: direction parameter must be a single integer, not an array");
  if (mxGetN(prhs[RHS_DIRECTION_ARG]) != 1)
    mexErrMsgTxt("Error: direction parameter must be a single integer, not an array");

  // Check direction is a legal value
  input_val = mxGetScalar(prhs[RHS_DIRECTION_ARG]);
  if (input_val != floor(input_val))
    mexErrMsgTxt("Error: direction parameter is not an integer");
  direction = (int)input_val;
  if (direction != 0 && direction != 1)
    mexErrMsgTxt("Error: direction parameter is invalid: must be either 1 (forward FFT) or 0 (inverse FFT / IFFT)");

  // Check if xn_re / xn_im inputs are correctly quantized
  // Note that the actual quantization, if necessary, is not done here:
  // that is done inside the actual C model, in xilinx_ip_xfft_v9_1_bitacc_simulate
  double xn_tmp;
  char must_quantize = 0;
  const double scale_factor = (double)(1ULL << (generics.C_INPUT_WIDTH - 1));
  if (generics.C_USE_FLT_PT == 0) {
    //Only check when fixed point. 
    for (sample=0; sample<input_data_size; sample++) {
      xn_tmp = input_data_re[sample] * scale_factor;  // Scale up: xn_tmp should be an integer
      if (xn_tmp != floor(xn_tmp)) {
        must_quantize = 1;  // To show we need to internally quantize inputs
        break;          // Exit the for loop
      }
      if (input_is_complex) {  // Only check imaginary parts if they exist!
        xn_tmp = input_data_im[sample] * scale_factor;  // Scale up: xn_tmp should be an integer
        if (xn_tmp != floor(xn_tmp)) {
          must_quantize = 1;  // To show we need to internally quantize inputs
          break;          // Exit the for loop
        }
      }
    }
  }
  if (must_quantize == 1) {
    mexPrintf("Warning: values in input_data array are not pre-quantized to signed two's-complement fixed-point values\n"
              "    of precision generics.C_INPUT_WIDTH bits.  All real and imaginary data will be internally rounded to\n"
              "    the nearest quantization level for this precision (using convergent rounding to nearest even). Use\n"
              "    Matlab's quantize function to pre-quantize input_data for accurate modelling of the Xilinx FFT core.\n");
  }


  // Now know that all input parameters are legal.
  // Check if generics match the existing state structure (if one exists): if not, create a new one
  if (xfft_v9_1_state == NULL) {  // No existing state structure
    // mexPrintf("DEBUG: state pointer is NULL, creating a new state structure\n");
    xfft_v9_1_state = xilinx_ip_xfft_v9_1_create_state(generics);    
  } else if (state_generics.C_NFFT_MAX      != generics.C_NFFT_MAX      ||
             state_generics.C_ARCH          != generics.C_ARCH          ||
             state_generics.C_HAS_NFFT      != generics.C_HAS_NFFT      ||
             state_generics.C_INPUT_WIDTH   != generics.C_INPUT_WIDTH   ||
             state_generics.C_TWIDDLE_WIDTH != generics.C_TWIDDLE_WIDTH ||
             state_generics.C_HAS_SCALING   != generics.C_HAS_SCALING   ||
             state_generics.C_HAS_BFP       != generics.C_HAS_BFP       ||
             state_generics.C_HAS_ROUNDING  != generics.C_HAS_ROUNDING  ||
             state_generics.C_USE_FLT_PT    != generics.C_USE_FLT_PT ) {
    // Existing state structure has different generics to current function call; create a new state structure
    // mexPrintf("DEBUG: state structure is different, destroying and creating state\n");
    xilinx_ip_xfft_v9_1_destroy_state(xfft_v9_1_state);
    xfft_v9_1_state = xilinx_ip_xfft_v9_1_create_state(generics);
    // mexPrintf("DEBUG: destroying state structure, creating new one\n");
  }
  // DEBUG
  else
    // mexPrintf("DEBUG: state structure matches current generics, not changing state structure\n");

  // Register an exit function for Matlab to call before it exits or clears this MEX function
  // that will destroy the state structure in order to free up the memory it is using
  mexAtExit(xfft_v9_1_mex_exit);

  // Copy current generics to state_generics, to track them from one function call to the next
  state_generics.C_NFFT_MAX      = generics.C_NFFT_MAX;
  state_generics.C_ARCH          = generics.C_ARCH;
  state_generics.C_HAS_NFFT      = generics.C_HAS_NFFT;
  state_generics.C_INPUT_WIDTH   = generics.C_INPUT_WIDTH;
  state_generics.C_TWIDDLE_WIDTH = generics.C_TWIDDLE_WIDTH;
  state_generics.C_HAS_SCALING   = generics.C_HAS_SCALING;
  state_generics.C_HAS_BFP       = generics.C_HAS_BFP;
  state_generics.C_HAS_ROUNDING  = generics.C_HAS_ROUNDING;
  state_generics.C_USE_FLT_PT    = generics.C_USE_FLT_PT;

  // If input data is real-only, we need to create a block of zero-valued memory
  // to be the imaginary component of the input data
  if (!input_is_complex)
    input_data_im = (double*)mxCalloc(input_data_size, sizeof(double));

  // scaling_sch input to the FFT needs to be an array of ints but scaling_sch parameter
  // from Matlab is an array of doubles.  Create an int array and copy the values across
  int* scaling_sch;
  if (has_fixed_scaling) {
    scaling_sch = (int*)mxCalloc(stages, sizeof(int));
    int scale_stage;
    for (scale_stage=0; scale_stage<stages; scale_stage++) {
      scaling_sch[scale_stage] = (int)(scaling_sch_dbl[scale_stage]);
    }
  }

  // Create and populate an inputs structure
  xilinx_ip_xfft_v9_1_inputs inputs;
  inputs.nfft = nfft;
  inputs.xn_re = input_data_re;
  inputs.xn_re_size = input_data_size;
  inputs.xn_im = input_data_im;
  inputs.xn_im_size = input_data_size;
  inputs.scaling_sch = (has_fixed_scaling ? scaling_sch : NULL);
  inputs.scaling_sch_size = (has_fixed_scaling ? stages : 0);
  inputs.direction = direction;

  // Create matrices for the MEX function's return arguments
  plhs[LHS_OUTPUTDATA_ARG] = mxCreateDoubleMatrix(input_data_rows, input_data_columns, mxCOMPLEX);
  plhs[LHS_BLKEXP_ARG]     = mxCreateDoubleMatrix(1, 1, mxREAL);
  plhs[LHS_OVERFLOW_ARG]   = mxCreateDoubleMatrix(1, 1, mxREAL);

  // Create and populate an outputs structure
  xilinx_ip_xfft_v9_1_outputs outputs;
  outputs.xk_re = mxGetPr(plhs[LHS_OUTPUTDATA_ARG]);
  outputs.xk_re_size = input_data_size;
  outputs.xk_im = mxGetPi(plhs[LHS_OUTPUTDATA_ARG]);
  outputs.xk_im_size = input_data_size;

  // Simulate the FFT
  char result = xilinx_ip_xfft_v9_1_bitacc_simulate(xfft_v9_1_state, inputs, &outputs);
  if (result != 0) {
    mexPrintf("Error: internal error running FFT C model, return code = %d\n", result);
    mexErrMsgTxt("Error: internal error. Please contact Xilinx Support");
  }
  // Copy block exponent and overflow outputs into return matrices
  double* blk_exp_dbl = mxGetPr(plhs[LHS_BLKEXP_ARG]);
  blk_exp_dbl[0] = (double)(outputs.blk_exp);
  double* overflow_dbl = mxGetPr(plhs[LHS_OVERFLOW_ARG]);
  overflow_dbl[0] = (double)(outputs.overflow);

  // Tidy up before exit
  if (!input_is_complex)
    mxFree(input_data_im);
  if (has_fixed_scaling)
    mxFree(scaling_sch);

}
