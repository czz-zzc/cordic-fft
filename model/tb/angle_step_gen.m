
clear all;
clc;
phasewidth = 26;
for i = 2:14
N = 2^i;
angel_step(i) = dec_0_3_bin(pi*2/N,phasewidth);
angel_pi_4 = dec_0_3_bin(pi/4,phasewidth);
end
angel_step = angel_step';