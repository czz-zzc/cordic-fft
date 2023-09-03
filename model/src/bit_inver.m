function y = bit_inver(x);
    N = length(x);
    N_bin_length = log2(N);
    index = zeros(1,N);
    y = zeros(1,N);
    for i = 0:N-1
        i_bin = dec2bin(i,N_bin_length);
        i_bin_inve = dec2bin(i,N_bin_length);
        for k = 1:N_bin_length;
            i_bin_inve(k) = i_bin(N_bin_length+1-k);
        end
        i_inve = bin2dec(i_bin_inve);
        index(i+1) = i_inve;
    end

    for i = 1:N
        y(index(i)+1) = x(i);
    end
end