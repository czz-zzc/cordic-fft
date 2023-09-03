function [out y] = dec_0_3_bin(x,width)
i=1;
y = zeros(1,width);
switch(floor(x))
    case 0
        y(2)=0;
        y(1)=0;
        x = x;
    case 1
        y(2)=1;
        y(1)=0;
        x = x-1;
    case 2
        y(2)=0;
        y(1)=1;
        x = x-2;
    case 3 
        y(2)=1;
        y(1)=1;
        x = x-3;
    otherwise 
        error('dec2bin3 over flow!!!!!!.');
end
i = i+2;
multi=x*2;
S=fix(multi);
T=multi-S;
y(i)=S;
while (i<width)
    i=i+1;
    multi=T*2;
    S=fix(multi);
    T=multi-S;
    y(i)=S;
end
out = 0;
for i =1:width
	out = y(i)*2^(width-i) + out;
end
end