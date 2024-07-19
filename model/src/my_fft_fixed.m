function [index,y_real,y_imag] = my_fft_fixed(x_real,x_imag,N,data_width_s,fft_ifft,overflow_pro)
%% 参数说明
% x_real        :输入数据实部
% x_imag        :输入数据虚部
% N             :变换点数
% data_width_s  :数据位宽 12~16位，最高位为符号位
% fft_ifft      :0-fft变化；1-ifft变换
% y_real        :变换数据输出实部，数据位宽等于data_width_s
% y_imag        :变换数据输出虚部，数据位宽等于data_width_s
% index         :变换输出输出索引
% overflow_pro  :防溢出处理
% 注：fft变换时每级截一位
%
%%
data_width = data_width_s-1;
phasewidth = 26;
iteration = data_width+1;
phase_scale = 2^phasewidth;

x = x_real + 1i* x_imag;
if(overflow_pro == 1)
    x = floor(real(x)/2) + 1i*floor(imag(x)/2);
end
%ifft时，交换实部和虚部
if(fft_ifft == 1)
    x = imag(x) + 1i*real(x);
end


step_N = log2(N);%迭代次数
stage_out_real = zeros(N,1);
stage_out_imag = zeros(N,1);
stage_out = complex(stage_out_real,stage_out_imag);
cmpmult_out_real = zeros(2,1);
cmpmult_out_imag = zeros(2,1);
cmpmult_out=complex(cmpmult_out_real,cmpmult_out_imag);

for step=1:1:step_N
    cmpmult_gap= N/(2^step);%旋转因子最大值
    cmpmult_num = 2^(step-1);%重复次数最大值
    angel_step = dec_0_3_bin(pi*1/(N/2^step),phasewidth);
    angel_pi_4 = dec_0_3_bin(pi/4,phasewidth);
    
    if(step ==1)
        cmpmult_in = x;
    else
        cmpmult_in = stage_out;
    end
    
    if(step == step_N)
        for s=1:cmpmult_num %重复次数
            offset=(s-1)*(cmpmult_gap*2);
            for k=1:cmpmult_gap
                cmpmult_out = butterfly_step1([cmpmult_in(k+offset) cmpmult_in(k+offset+cmpmult_gap)]);
                stage_out(k+offset)=cmpmult_out(1);
                stage_out(k+offset+cmpmult_gap)=cmpmult_out(2);
            end
        end
    else   
        for s=1:cmpmult_num %重复次数
            angel_sum = 0;
            offset=(s-1)*(cmpmult_gap*2);
            for k=1:cmpmult_gap
                if(k ==1)
                    angel_sum = 0;
                    qual = 0;
                elseif(k>1 && k<=cmpmult_gap*1/4)
                    angel_sum = angel_sum + angel_step;
                    qual = 0;
                elseif(k==(cmpmult_gap*1/4 +1))
                    angel_sum = angel_pi_4;
                    qual = 1;
                elseif(k>(cmpmult_gap*1/4 +1) && k<=cmpmult_gap*2/4)
                    angel_sum = angel_sum - angel_step;
                    qual = 1;
                elseif(k==(cmpmult_gap*2/4 +1))
                    angel_sum = 0;
                    qual = 2;
                elseif(k>(cmpmult_gap*2/4 +1) && k<=cmpmult_gap*3/4)
                    angel_sum = angel_sum + angel_step;
                    qual = 2;
                elseif(k==(cmpmult_gap*3/4 + 1))
                    angel_sum = angel_pi_4;
                    qual = 3;
                elseif(k>(cmpmult_gap*3/4 +1)&& k<=cmpmult_gap)
                    angel_sum = angel_sum - angel_step;
                    qual = 3;
                else 
                    error('angel_sum1 err!!!!!!.');
                end
                
                if angel_sum<0
                    error('angel_sum_neg err!!!!!!.');
                end
                angel_sum_test = dec2bin(angel_sum,24);
                %if(angel_sum_test(3)=='1')
                % error('angel_sum_neg err!!!!!!.');
                %end  
                %if(angel_sum_test(4)=='1')
                % error('angel_sum_neg err!!!!!!.');
                %end  
              
                cmpmult_out = butterfly_fixed([cmpmult_in(k+offset) cmpmult_in(k+offset+cmpmult_gap)],data_width,phasewidth,angel_sum,qual);
                stage_out(k+offset)=cmpmult_out(1);
                stage_out(k+offset+cmpmult_gap)=cmpmult_out(2);
            end
        end
    end
    
end

%ifft时，交换实部和虚部
if(fft_ifft == 1)
    stage_out = imag(stage_out) + 1i*real(stage_out);
end

%y=bit_inver(stage_out);
y = stage_out;
y_real = real(y);
y_imag = imag(y);
index = zeros(N,1);
for m=1:N
    index(m) = m-1;
end
index = bit_inver(index);
end

