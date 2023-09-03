% $RCSfile: make_xfft_v9_1_mex.m,v $ $Version: $ $Date: 2010/09/08 12:33:21 $
%
%  (c) Copyright 2008-2009 Xilinx, Inc. All rights reserved.
%
%  This file contains confidential and proprietary information
%  of Xilinx, Inc. and is protected under U.S. and
%  international copyright and other intellectual property
%  laws.
%
%  DISCLAIMER
%  This disclaimer is not a license and does not grant any
%  rights to the materials distributed herewith. Except as
%  otherwise provided in a valid license issued to you by
%  Xilinx, and to the maximum extent permitted by applicable
%  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
%  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
%  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
%  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
%  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
%  (2) Xilinx shall not be liable (whether in contract or tort,
%  including negligence, or under any other theory of
%  liability) for any loss or damage of any kind or nature
%  related to, arising under or in connection with these
%  materials, including for any direct, or any indirect,
%  special, incidental, or consequential loss or damage
%  (including loss of data, profits, goodwill, or any type of
%  loss or damage suffered as a result of any action brought
%  by a third party) even if such damage or loss was
%  reasonably foreseeable or Xilinx had been advised of the
%  possibility of the same.
%
%  CRITICAL APPLICATIONS
%  Xilinx products are not designed or intended to be fail-
%  safe, or for use in any application requiring fail-safe
%  performance, such as life-support or safety devices or
%  systems, Class III medical devices, nuclear facilities,
%  applications related to the deployment of airbags, or any
%  other applications that could lead to death, personal
%  injury, or severe property or environmental damage
%  (individually and collectively, "Critical
%  Applications"). Customer assumes the sole risk and
%  liability of any use of Xilinx products in Critical
%  Applications, subject only to applicable laws and
%  regulations governing limitations on product liability.
%
%  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
%  PART OF THIS FILE AT ALL TIMES. 
%-------------------------------------------------------------------
%
% Matlab .m file to build the Fast Fourier Transform v8.0 C model 
% with Matlab MEX wrapper
%
% Output will be a file called xfft_v9_1_bitacc_mex.mexw<suffix> in the
% working directory, where <suffix> may be w32, w64, glx or a64, depending
% on operating system
%
%-------------------------------------------------------------------

if (~exist('xfft_v9_1_bitacc_cmodel.h'))
  error('ERROR: make_xfft_v9_1_mex.m: xfft_v9_1_bitacc_cmodel.h must be present in this directory to build the MEX function')
end

operating_system = computer;

if (strcmp(operating_system,'PCWIN'))
  
  fprintf('Building NT MEX function...\n');
  
  if(~exist('libIp_xfft_v9_1_bitacc_cmodel.lib'))
    error('ERROR: make_xfft_v9_1_mex.m: libIp_xfft_v9_1_bitacc_cmodel.lib must be present in this directory to build the MEX function');
  end
  
  mex -DWIN32 -DNT -D_USRDLL -O ...
      xfft_v9_1_bitacc_mex.cpp ...
      libIp_xfft_v9_1_bitacc_cmodel.lib ...
      -output xfft_v9_1_bitacc_mex
  
elseif (strcmp(operating_system,'PCWIN64'))
  
  fprintf('Building NT64 MEX function...\n');
  
  if(~exist('libIp_xfft_v9_1_bitacc_cmodel.lib'))
    error('ERROR: make_xfft_v9_1_mex.m: libIp_xfft_v9_1_bitacc_cmodel.lib must be present in this directory to build the MEX function');
  end
  
  mex -DWIN64 -DNT -D_USRDLL -O ...
      xfft_v9_1_bitacc_mex.cpp ...
      libIp_xfft_v9_1_bitacc_cmodel.lib ...
      -output xfft_v9_1_bitacc_mex
  
elseif (strcmp(operating_system,'GLNX86'))

    fprintf('Building LIN32 MEX function...\n');
  
    if(~exist('libIp_xfft_v9_1_bitacc_cmodel.so'))
      error('ERROR: make_xfft_v9_1_mex.m: libIp_xfft_v9_1_bitacc_cmodel.so must be present in this directory to build the MEX function');
    end     
 
    mex -DLIN -DUNIX -DNDEBUG -D_USRDLL -O xfft_v9_1_bitacc_mex.cpp ...
	 -output xfft_v9_1_bitacc_mex -lIp_xfft_v9_1_bitacc_cmodel -L./     

elseif (strcmp(operating_system,'GLNXA64'))

  fprintf('Building LIN64 MEX function...\n');
  
  if(~exist('libIp_xfft_v9_1_bitacc_cmodel.so'))
    error('ERROR: make_xfft_v9_1_mex.m: libIp_xfft_v9_1_bitacc_cmodel.so must be present in this directory to build the MEX function');
  end  

  mex -DLIN64 -DUNIX -DNDEBUG -D_USRDLL -O xfft_v9_1_bitacc_mex.cpp ...
       -output xfft_v9_1_bitacc_mex -lIp_xfft_v9_1_bitacc_cmodel -L./

end

fprintf('MEX function compilation completed successfully\n')
