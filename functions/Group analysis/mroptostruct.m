function datastruct = mroptostruct(datastruct, varargin)
% mroptostruct applies motion regression to photometry data

if nargin < 2
    vararin = {};
end

% Parse input
p  = inputParser;

addOptional(p, 'convolvegauss', true); % Convolution of motion data
addOptional(p, 'gaussx', [-20,20]);
addOptional(p, 'gausssig', 5);

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Gaussian
if p.convolvegauss
    gauss_distribution = @(x, mu, s) exp(-.5 * ((x - mu)/s) .^ 2) ./ (s * sqrt(2*pi)); 
    gs = gauss_distribution(p.gaussx(1):p.gaussx(2),0,p.gausssig)';
end

%% Process
% Number
n = length(datastruct);


% Loop through
for i = 1 : n
    % Get the dataout
    d = datastruct(i).photometry_trig;
    m = datastruct(i).locomotion;
    
    % Size
    sizevec = size(d);
    
    % means
    meanvecd = mean(d,1);
    meanvecm = mean(m,1);
    
    % Subtract means
    d2 = d - ones(sizevec(1),1) * meanvecd;
    m2 = m - ones(sizevec(1),1) * meanvecm;
    
    % Linearize
    d2v = d2(:);
    m2v = m2(:);
    
    % Look
%     inds = 5000:8000;
%     t= conv(m2v(inds), gs);
%     t = t(1-p.gaussx(1) : end-p.gaussx(2));
%     t2 = conv(diff(m2v(inds)), gs);
%     t2 = t2(1-p.gaussx(1)-1 : end-p.gaussx(2));
%     plot(inds,d2v(inds),inds, t2)
%     plot(inds,d2v(inds),inds(1:end-1),diff(m2v(inds)))

    % Prepare for regression
    if p.convolvegauss
        t = conv(m2v, gs);
        t2 = conv([0;diff(m2v)], gs);

        t = t(1-p.gaussx(1) : end-p.gaussx(2));
        t2 = t2(1-p.gaussx(1) : end-p.gaussx(2));
    else
        t = m2v;
        t2 = [0;diff(m2v)];
    end
   	t0 = ones(sizevec(1) * sizevec(2), 1);
    
    % Weights
    wt = [t, t2, t0] \ d2v;
    
    % Subtract
    d2s = d2v - [t, t2, t0] * wt;
    
    % Reshape back
    d2s = reshape(d2s, sizevec);
    d2s = d2s + ones(sizevec(1),1) * meanvecd;
    
    % Put the means back
    datastruct(i).photometry_trig = d2s;
    datastruct(i).photometry_trigavg = mean(d2s, 2);
end




end