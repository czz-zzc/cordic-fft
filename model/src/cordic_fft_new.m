function y = cordic_fft_new(x,data_width,angel_ture,qual,phase_scale)
    data_width_s = data_width + 1;
    k = ceil((data_width_s - log2(6))/3);
    m = ceil((data_width_s - 1)/2);
    exp_bit = 2^2;
    b_out = 0;
    a_out = 0;
    a_in = 0;
    b_in = 0;
    a_in = real(x)* exp_bit;
    b_in = imag(x)* exp_bit;
    angel_tran = dec2bin(angel_ture,phase_scale);
    angel_bin = zeros(1,phase_scale);
%     for i = 1:phase_scale
%         angel_bin(i) = str2num(angel_tran(i));
%     end
    switch qual
        case 0
            mid_ab = a_in;
            a_in = b_in;
            b_in = mid_ab;
        case 1
            a_in = a_in;
            b_in = b_in;
        case 2
            mid_ab = a_in;
            a_in = b_in;
            b_in = mid_ab;
        case 3
            a_in = a_in;
            b_in = b_in;
        otherwise
            error('angle err!!!!!!.');
    end
    
    %%stage 1
    if angel_tran(3) =='1'
        cos_a_stage1 = a_in - floor(a_in/(2^3)) + floor(a_in/(2^9)) + floor(a_in/(2^11))+ floor(a_in/(2^12));
        sin_b_stage1 = floor(b_in/2) - floor(b_in/(2^6)) - floor(b_in/(2^8))- floor(b_in/(2^10));
        cos_b_stage1 = b_in - floor(b_in/(2^3)) + floor(b_in/(2^9)) + floor(b_in/(2^11))+ floor(b_in/(2^12));
        sin_a_stage1 = floor(a_in/2) - floor(a_in/(2^6)) - floor(a_in/(2^8))- floor(a_in/(2^10));
        a_stage1 = cos_a_stage1 - sin_b_stage1;
        b_stage1 = cos_b_stage1 + sin_a_stage1;
    else
        a_stage1 = a_in;
        b_stage1 = b_in;
    end
    
    
    %%stage 2
    if angel_tran(4) =='1'
        cos_a_stage2 = a_stage1 - floor(a_stage1/(2^(2*2+1)));
        sin_b_stage2 = floor(b_stage1/(2^2)) - floor(b_stage1/(2^(3*2+3))) - floor(b_stage1/(2^(3*2+5)));
        cos_b_stage2 = b_stage1 - floor(b_stage1/(2^(2*2+1)));
        sin_a_stage2 = floor(a_stage1/(2^2)) - floor(a_stage1/(2^(3*2+3))) - floor(a_stage1/(2^(3*2+5)));
        a_stage2 = cos_a_stage2 - sin_b_stage2;
        b_stage2 = cos_b_stage2 + sin_a_stage2;
    else
        a_stage2 = a_stage1;
        b_stage2 = b_stage1;
    end

    
    %%stage 3
    if angel_tran(5) =='1'
        cos_a_stage3 = a_stage2 - floor(a_stage2/(2^(2*3+1)));
        sin_b_stage3 = floor(b_stage2/(2^3)) - floor(b_stage2/(2^(3*3+3))) - floor(b_stage2/(2^(3*3+5)));
        cos_b_stage3 = b_stage2 - floor(b_stage2/(2^(2*3+1)));
        sin_a_stage3 = floor(a_stage2/(2^3)) - floor(a_stage2/(2^(3*3+3))) - floor(a_stage2/(2^(3*3+5)));
        a_stage3 = cos_a_stage3 - sin_b_stage3;
        b_stage3 = cos_b_stage3 + sin_a_stage3;
    else
        a_stage3 = a_stage2;
        b_stage3 = b_stage2;
    end
    
    
     %%stage 4
    if angel_tran(6) =='1'
        cos_a_stage4 = a_stage3 - floor(a_stage3/(2^(2*4+1)));
        sin_b_stage4 = floor(b_stage3/(2^4)) - floor(b_stage3/(2^(3*4+3)));
        cos_b_stage4 = b_stage3 - floor(b_stage3/(2^(2*4+1)));
        sin_a_stage4 = floor(a_stage3/(2^4)) - floor(a_stage3/(2^(3*4+3)));
        a_stage4 = cos_a_stage4 - sin_b_stage4;
        b_stage4 = cos_b_stage4 + sin_a_stage4;
    else
        a_stage4 = a_stage3;
        b_stage4 = b_stage3;
    end
    
    a_in = a_stage4;
    b_in = b_stage4;
    

    for i = k:(m-1)
        if(angel_tran(i+2) == '1')
            a_out = a_in - floor(a_in/(2^(2*i+1))) -floor(b_in/(2^i));
            b_out =  floor(a_in/(2^i)) + b_in - floor(b_in/(2^(2*i+1)));
            a_in = a_out;
            b_in = b_out;
        else
            a_out = a_in;
            b_out = b_in;
            a_in = a_out;
            b_in = b_out;
        end
    end
    
    for i =m:(data_width_s)
        if(angel_tran(i+2) == '1')
            a_out = a_in -floor(b_in/(2^i));
            b_out = floor(a_in/(2^i)) + b_in;
            a_in = a_out;
            b_in = b_out;
        else
            a_out = a_in;
            b_out = b_in;
            a_in = a_out;
            b_in = b_out;
        end
    end
    
    
    switch qual
        case 0
            y =  floor(b_out/exp_bit) + 1j* floor(a_out/exp_bit);
        case 1
            y =  floor(b_out/exp_bit) - 1j* floor(a_out/exp_bit);
        case 2
            y =  floor(a_out/exp_bit) - 1j* floor(b_out/exp_bit);
        case 3
            y = -floor(a_out/exp_bit) - 1j* floor(b_out/exp_bit);
        otherwise
            error('angle err!!!!!!.');
    end
    
    if(abs(real(y))>((2^data_width)) )
        disp('over flow err!!!!!!.');
    end
end