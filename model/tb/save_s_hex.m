function save_s_hex(S,data_width)
info_I=real(S);
info_Q=imag(S);
N= length(S);
% data_I=zeros(N,data_width/4);
% data_Q=zeros(N,data_width/4);
file_id = fopen("data_in_real.txt",'w');
for (i=1:N)
    if (info_I(i))>=0
        obj=dec2hex(info_I(i),data_width/4);
    else
        obj=dec2hex((2^16+info_I(i)),data_width/4);
    end
    
    fprintf(file_id,'%s\n',obj);
end
fclose(file_id);

file_id = fopen("data_in_imag.txt",'w');
for (i=1:N)
    if (info_Q(i))>=0
        obj=dec2hex(info_Q(i),data_width/4);
    else
        obj=dec2hex((2^16+info_Q(i)),data_width/4);
    end

    fprintf(file_id,'%s\n',obj);
end
fclose(file_id);

end
