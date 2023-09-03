function [snrProc, errProc, snrProcMin, errProcMax] = f_cmpProcSnr(xSig, xSig0, agcEn, figOn, figNum)
%***********************************************************************************************************************
% 文件描述: 计算处理信噪比, 可计算定点化引入的量化信噪比(sqnr: Signal to Quantizing Noise Ratio).
% 程序说明：
%           1. snr 越大, 处理误差越小
%           2. 量化信噪比在 40 dB 以上时(对应处理误差在 1% 以下), 基本没有影响
%***********************************************************************************************************************
% 输入:
%    xSig           : 经过处理后的数据, 向量或矩阵, 矩阵时, 每列为一个信号
%    xSig0          : 原始/理想数据, 向量或矩阵, 矩阵时, 每列为一个信号, 与 xSig 一一对应
%    agcEn(可选)    : 对数据进行幅度调整, 默认不调整. 通常在浮点数对比时使用
%    figOn(可选)    : 将两个数据画到一张图上, 0 - 关闭, 其它 - 打开,  默认关闭.
%    figNum(可选)   : 图编号.
% 输出:
%    snrProc        : 误差信噪比
%    errProc        : 处理引入的误差百分比, 类似 evm
%    snrProcMin     : 最大误差对应的信噪比, 
%    errProcMax     : 最大误差 
%
%***********************************************************************************************************************
% 修改记录:
%    001    LLW, 2020/5/25, create.
%    002    LLW, 2020/6/01, 增加处理误差百分比指标.
%    003    LLW, 2021/9/10, 增加最大误差指标, 画图使用功率归一化误差(dB 值), 取反即为每个点的误差 snr.
%         
%***********************************************************************************************************************
% save f_cmpProcSnr
% load f_cmpProcSnr

% -----------------------------------------------
% 参数检查及默认设置
% -----------------------------------------------
% 默认配置
if(~exist('figOn','var') || isempty(figOn))
    figOn = 0; 
end

if(~exist('agcEn','var') || isempty(agcEn))
    agcEn = 0; 
end

% -----------------------------------------------
% 程序主体
% -----------------------------------------------
if(agcEn)
    xSig  = f_agc(xSig);
    xSig0 = f_agc(xSig0);
end

% 处理信噪比
snrLine = f_power(xSig0)./f_power(xSig0-xSig); % 线性值
snrProc = 10*log10(snrLine);                   % dB 值
errProc = 1./sqrt(snrLine);

% 计算最大误差(平均功率比上最大误差), 对应最小信噪比
% snrLineMin = min(abs(xSig0).^2./abs(xSig0-xSig).^2); % 线性值, 当 xSig0 取0时, 无法很好地反映实际情况
snrLineMin = min(f_power(xSig0)./abs(xSig0-xSig).^2);  % 线性值, 使用均值功率作为信号功率
snrProcMin = 10*log10(snrLineMin);                   % dB 值
errProcMax = 1./sqrt(snrLineMin);

% 画图
if(figOn)
    % 默认配置, 新图
%     if(~exist('figNum','var') || isempty(figNum))
%         figNum = []; 
%     end
    
    % 归一化误差
    err = [xSig-xSig0]./sqrt(f_power(xSig0)); % 功率归一 
    f_plotPower(err, [], 0)  % 相对功率
    title(['误差(信噪比均值 SNR=' num2str(mean(snrProc), '%.0fdB') ')'])
end

end

%***********************************************************************************************************************
% 子函数
%***********************************************************************************************************************
function [p] = f_power(x)
    % 计算能量
    p = mean(x.*conj(x));
end

function xSig = f_agc(xSig)
 
    % 计算每个信号统计位置上的平均功率
    power = mean(xSig.*conj(xSig));
    
    % 需要调整的幅度
    amp = sqrt(power);
    
    % 调整信号功率
    xSig = xSig./amp;
end
