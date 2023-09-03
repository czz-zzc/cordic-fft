
clc;
clear all;
angel_step = zeros(14,1);
for i=2:14
    N = 2^i;
    angel_step(i) = dec_0_3_bin((2*pi*1/N),20);
end

clear all
angel_tran = dec2bin(123,20);
a(1) = angel_tran(1);
if(a(1) == '0')
    b=2
end