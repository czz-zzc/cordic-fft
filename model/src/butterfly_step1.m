function y = butterfly_step1(x)
y_real = zeros(2,1);
y_imag = zeros(2,1);
y=complex(y_real,y_imag);
 y(1) = floor((x(1) + x(2))/2);
 y(2) = floor((x(1) - x(2))/2);
end