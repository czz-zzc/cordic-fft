clc;
clear all;
Fs = 600e6;            % Sampling frequency  
Fc = 60e6;            % Signal frequency  
T = 1/Fs;              % Sampling period       
overflow_pro = 1;      % overflow pro
FFT_IFFT = 0;          % fft/ifft select 0:fft 1:ifft
data_width_s = 16;
data_width = data_width_s -1;
data_scale = 2^data_width -1;

%%
% for N_de = 12:14 
L  = 4096;
t = (0:L-1)*T;         % Time vector
out_scale = L * (2^overflow_pro);   %缩放因子

S_float = zeros(1,L);
S = zeros(1,L);
Y1 = zeros(1,L);
Y2 = zeros(1,L);
Y3 = zeros(1,L);
Y2_index = zeros(1,L);

%%%generate test vector
S_float = 0.9*(1i*sin(2*pi*Fc*t) + cos(2*pi*Fc*t)) + 0.1*rand(1,L);
%S_float = (randi([-1,1],1,L) + 1*i*randi([-1,1],1,L));
S = floor(data_scale*S_float);

%%% load test vector
%load('s_data_4096.mat');

%%% save test vector
save_s_hex(S,data_width_s);

%%
%%% matlab fft
Y1 = fft(S);
Y1 = (Y1/out_scale);
%%
%%% my fft fixed
[Y2_index,Y2_real,Y_imag] = my_fft_fixed(real(S),imag(S),L,data_width_s,FFT_IFFT,overflow_pro);
Y2 = Y2_real + 1i*Y_imag;

%%
% xilinx model 
generics.C_NFFT_MAX = log2(L);
generics.C_ARCH = 2;
generics.C_HAS_NFFT = 0;
generics.C_USE_FLT_PT = 0;
generics.C_INPUT_WIDTH = data_width_s; % Must be 32 if C_USE_FLT_PT = 1
generics.C_TWIDDLE_WIDTH = 16; % Must be 24 or 25 if C_USE_FLT_PT = 1
generics.C_HAS_SCALING = 1; % Set to 0 if C_USE_FLT_PT = 1
generics.C_HAS_BFP = 0; % Set to 0 if C_USE_FLT_PT = 1
generics.C_HAS_ROUNDING = 0; % Set to 0 if C_USE_FLT_PT = 1
nfft = generics.C_NFFT_MAX;
scaling_sch = ones(1,nfft);

if(overflow_pro == 1)
    scaling_sch(1) = 2;
end

if(FFT_IFFT == 0)
    direction = 1;
else
    direction = 0;
end

factor=generics.C_INPUT_WIDTH-1;
% Set up quantizer for correct twos's complement, fixed-point format: one sign bit, C_INPUT_WIDTH-1 fractional bits
q = quantizer([generics.C_INPUT_WIDTH, generics.C_INPUT_WIDTH-1], 'fixed', 'convergent', 'saturate');
% Format data for fixed-point input
input = quantize(q,S/2^factor);
[Y3, blkexp, overflow] = xfft_v9_1_bitacc_mex(generics, nfft,input, scaling_sch, direction);
Y3 =Y3 * 2^factor;

%% plot 
figure
P2 = abs(Y1);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;
subplot(3,1,1);
plot(f,P1) 
title('Matlab FFT result')
xlabel('f (Hz)')
ylabel('|P1(f)|')


P4 = abs(bit_inver(Y2));
P3 = P4(1:L/2+1);
P3(2:end-1) = 2*P3(2:end-1);
f = Fs*(0:(L/2))/L;
subplot(3,1,2);
plot(f,P3) 
title('My FFT result')
xlabel('f (Hz)')
ylabel('|P1(f)|')

P6 = abs(Y3);
P5 = P6(1:L/2+1);
P5(2:end-1) = 2*P5(2:end-1);
f = Fs*(0:(L/2))/L;
subplot(3,1,3);
plot(f,P5) 
title('XILINX FFT result')
xlabel('f (Hz)')
ylabel('|P1(f)|')

%%
%%% compare fft data
% my fft compare matlab
figure
subplot(2,1,1);
[snrProc, errProc, snrProcMin, errProcMax] = f_cmpProcSnr(bit_inver(Y2),Y1,0,1);
title(['my fft 误差(信噪比均值 SNR=' num2str(mean(snrProc), '%.0fdB') ')'])
subplot(2,1,2);
% xilinx fft compare matlab
[snrProc, errProc, snrProcMin, errProcMax] = f_cmpProcSnr(Y3,Y1,0,1);
title(['xilinx fft 误差(信噪比均值 SNR=' num2str(mean(snrProc), '%.0fdB') ')'])

% end
%%
% fid1 = fopen('F:\workfile2023\soc\fpga\ip_select\ip_select.sim\sim_1\behav\xsim\data_out_real.txt','r');
% trans_data1 = trans_fpga_data(fid1);
% local_data = real(Y2);
% trans_data1 = trans_data1';
% fclose(fid1);

