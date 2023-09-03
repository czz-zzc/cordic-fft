function f_plotPower(xSig, mode, legendOn);
%********************************************************************
% �ļ�����:  ���źŵ�ʱ����(dB��ʽ), ����źŻ���1��ͼ��
% ��    ��:  ½��ΰ
% ��    ��:  Beta 1.0
% ��    ��:  2019/4/5 10:56:05
%********************************************************************
% INPUT:
%   xSig      : ���븴�ź�, ����Ϊ�л�������������Ϊ������Ϊ�;���ÿһ�б�ʾһ���ź�
%   figId     : ����ͼ�ı�� 
%   mode(��ѡ): ��ʾģʽ, 0 - dB ��ʽ(Ĭ��), 1 - ���� 
%   legendOn(��ѡ)  : ��ע����, Ĭ�Ͽ�. 0 - �ر�, 1 - ��.
%********************************************************************
% ����:
%       
%********************************************************************
%�޸ļ�¼��
%       1. 
%*********************************************************************/
% save f_plotPower
% load f_plotPower

% -----------------------------------------------
% ������鼰Ĭ������
% -----------------------------------------------
% ת��Ϊ������
if(size(xSig,1) == 1)
    xSig = xSig(:); 
end

[len, num] = size(xSig);

% ת��Ϊ������
if(~exist('mode','var') || isempty(mode))
    mode = 0;
end

if(~exist('legendOn','var') || isempty(legendOn))
    legendOn = 1; 
end
% -----------------------------------------------
% ��������
% -----------------------------------------------
% ����ÿ�����ϵĹ���
power = xSig.*conj(xSig);
pStr  = '����ֵ';
if(mode == 0)
    power = 10*log10(power);
    pStr  = 'dB';
end    


% % ��ͼ
% if(~exist('figId','var') || isempty(figId))
%     figure 
% else
%     figure(figId)
% %     clf
% end

% ͼ�߱��
legendStr = 'signal ';

for(i_sig=1:num)
    tmpStr = [legendStr ' = ' num2str(i_sig)];

    % ʹ�� cell �͵��ַ���
    tmpStr = cellstr(tmpStr);

    % ʹ�� cell �͵��ַ�����
    if(i_sig==1)
        legendStrCell = tmpStr;
    else
        legendStrCell = [legendStrCell;tmpStr];
    end
end

plot(power);
grid on
ylabel(pStr);
xlabel('��������');
title(['�ź�ʱ����']);
if(legendOn)
    legend(legendStrCell, 'location', 'best');
end