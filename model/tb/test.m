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



%% plot 
figure
P2 = abs(Y1);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;
subplot(2,1,1);
plot(f,P1) 
title('Matlab FFT result')
xlabel('f (Hz)')
ylabel('|P1(f)|')


P4 = abs(bit_inver(Y2));
P3 = P4(1:L/2+1);
P3(2:end-1) = 2*P3(2:end-1);
f = Fs*(0:(L/2))/L;
subplot(2,1,2);
plot(f,P3) 
title('My FFT result')
xlabel('f (Hz)')
ylabel('|P1(f)|')


%%
%%% compare fft data
% my fft compare matlab
figure
subplot(1,1,1);
[snrProc, errProc, snrProcMin, errProcMax] = f_cmpProcSnr(bit_inver(Y2),Y1,0,1);
title(['my fft 误差(信噪比均值 SNR=' num2str(mean(snrProc), '%.0fdB') ')'])

% end
%%
% fid1 = fopen('F:\workfile2023\soc\fpga\ip_select\ip_select.sim\sim_1\behav\xsim\data_out_real.txt','r');
% trans_data1 = trans_fpga_data(fid1);
% local_data = real(Y2);
% trans_data1 = trans_data1';
% fclose(fid1);

