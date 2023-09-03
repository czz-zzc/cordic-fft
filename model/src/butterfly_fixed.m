function y = butterfly_fixed(x,data_width,phasewidth,angel_ture,qual)
y_real = zeros(2,1);
y_imag = zeros(2,1);
y=complex(y_real,y_imag);
 y(1) = floor((x(1) + x(2))/2);
 
 test = floor((x(1) - x(2))/2);
 %test0 = test*exp(-1j*W_2);
 test1 = cordic_fft_new(test,data_width,angel_ture,qual,phasewidth);
 %test2 = cordic_fft_fixed(test,W,data_width,phasewidth,iteration,atan_table,K,cordic_coe);
 %result1 = abs((test1-test0)/test0);
 %result2 = abs((test2-test0)/test0);
%  if(result1 > 0.02)
%     error(' err!!!!!!.');
%  end
 y(2) = test1;
 
end