function filtered = tcpLPfilter(raw, LP_freq, Fs, dim)
% tcpLPfilter filters traces with a lowpass filter.
% filtered = tcpLPfilter(raw, LP_freq, Fs, dim)
% Default:
% Fs = 50 Hz
% dim = 1

if nargin < 4
    dim = 1;
    if nargin < 3
        Fs = 50;
    end
end

% Design filter
d = fdesign.lowpass('Fp,Fst,Ap,Ast', LP_freq, LP_freq + 2, 0.5, 40, Fs);
Hd = design(d,'equiripple');

% Initialize
filtered = nan(size(raw));

if dim == 1
    for i = 1 : size(raw,2)
        filtered(:,i) = filter(Hd, raw(:,i));
    end
elseif dim == 2
    for i = 1 : size(raw, 1)
        filtered(i,:) = filter(Hd, raw(i,:));
    end
end    
end