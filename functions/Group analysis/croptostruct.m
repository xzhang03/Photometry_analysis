function datastruct = croptostruct(datastruct, varargin)
% mroptostruct applies cue on/offset regression to photometry data

if nargin < 2
    varargin = {};
end

% Parse input
p  = inputParser;

addOptional(p, 'mode', 'offset'); 
addOptional(p, 'window', [0, 20]);

addOptional(p, 'fcenter', []);
addOptional(p, 'fwidth', 0.1);
addOptional(p, 'powerthreshold', 0.01);
addOptional(p, 'minfreq', 0.8); % Signal below this freq will not be filtered
addOptional(p, 'makefftplot', false);

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

if isscalar(p.powerthreshold)
    p.powerthreshold = p.powerthreshold * ones(length(datastruct), 1);
end

for i = 1 : length(datastruct)
    startpoint = datastruct(i).window_info(1)+datastruct(i).tls(1);
    % disp(i)
    datastruct(i).photometry_trig =...
      multinotch(datastruct(i).photometry_trig, datastruct(i).Fs, 'roi', [startpoint+p.window(1),...
        startpoint+p.window(2)], 'fcenter', p.fcenter, 'fwidth', p.fwidth, 'powerthreshold', p.powerthreshold(i),...
        'minfreq', p.minfreq, 'makefftplot', p.makefftplot, 'plotresult', false);
end