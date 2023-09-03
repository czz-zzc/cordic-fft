function f_plotPower(xSig, mode, legendOn);
%********************************************************************
% 文件描述:  画信号的时域功率(dB形式), 多个信号画在1张图上
% 作    者:  陆连伟
% 版    本:  Beta 1.0
% 日    期:  2019/4/5 10:56:05
%********************************************************************
% INPUT:
%   xSig      : 输入复信号, 可以为行或列向量，可以为矩阵，若为就矩阵，每一列表示一个信号
%   figId     : 所画图的编号 
%   mode(可选): 显示模式, 0 - dB 形式(默认), 1 - 线性 
%   legendOn(可选)  : 标注开关, 默认开. 0 - 关闭, 1 - 打开.
%********************************************************************
% 例如:
%       
%********************************************************************
%修改记录：
%       1. 
%*********************************************************************/
% save f_plotPower
% load f_plotPower

% -----------------------------------------------
% 参数检查及默认设置
% -----------------------------------------------
% 转换为列向量
if(size(xSig,1) == 1)
    xSig = xSig(:); 
end

[len, num] = size(xSig);

% 转换为列向量
if(~exist('mode','var') || isempty(mode))
    mode = 0;
end

if(~exist('legendOn','var') || isempty(legendOn))
    legendOn = 1; 
end
% -----------------------------------------------
% 程序主体
% -----------------------------------------------
% 计算每个点上的功率
power = xSig.*conj(xSig);
pStr  = '线性值';
if(mode == 0)
    power = 10*log10(power);
    pStr  = 'dB';
end    


% % 画图
% if(~exist('figId','var') || isempty(figId))
%     figure 
% else
%     figure(figId)
% %     clf
% end

% 图线标记
legendStr = 'signal ';

for(i_sig=1:num)
    tmpStr = [legendStr ' = ' num2str(i_sig)];

    % 使用 cell 型的字符串
    tmpStr = cellstr(tmpStr);

    % 使用 cell 型的字符串组
    if(i_sig==1)
        legendStrCell = tmpStr;
    else
        legendStrCell = [legendStrCell;tmpStr];
    end
end

plot(power);
grid on
ylabel(pStr);
xlabel('采样点数');
title(['信号时域功率']);
if(legendOn)
    legend(legendStrCell, 'location', 'best');
end