function delay = cal_fft_delay
clc;
clear all;
max_stage=14;
delay = zeros((max_stage-1),2);
for i=1:(max_stage-1)
    N = 2^(i+1);
    delay(i,1) = N;
    delay(i,2) = 2+2;
    if i>4
        for k= 1:1:4
            delay(i,2) = delay(i,2) + 32;
        end
        
        for k= 5:1:i
            delay(i,2) = delay(i,2) + 2^k +1;
        end
    else
        for k= 1:1:i
            delay(i,2) = delay(i,2) + 32;
        end
    end

end