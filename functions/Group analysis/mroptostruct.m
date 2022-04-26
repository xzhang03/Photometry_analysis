function datastruct = mroptostruct(datastruct, varargin)
% mroptostruct applies motion regression to photometry data

if nargin < 2
    varargin = {};
end

% Parse input
p  = inputParser;

addOptional(p, 'convolvegauss', true); % Convolution of motion data
addOptional(p, 'gaussx', [-20,20]);
addOptional(p, 'gausssig', 5);
addOptional(p, 'reglicking', false);

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
    if p.reglicking
        l = datastruct(i).lick;
    end
    
    % Size
    sizevec = size(d);
    
    % means
    meanvecd = mean(d,1);
    meanvecm = mean(m,1);
    if p.reglicking
        meanvecl = mean(l,1);
    end
    
    % Subtract means
    d2 = d - ones(sizevec(1),1) * meanvecd;
    m2 = m - ones(sizevec(1),1) * meanvecm;
    if p.reglicking
        l2 = l - ones(sizevec(1),1) * meanvecl;
    end
    
    % Linearize
    d2v = d2(:);
    m2v = m2(:);
    if p.reglicking
        l2v = l2(:);
    end
    
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
        
        if p.reglicking
            l = conv(l2v, gs);
            l2 = conv([0;diff(l2v)], gs);
            
            l = l(1-p.gaussx(1) : end-p.gaussx(2));
            l2 = l2(1-p.gaussx(1) : end-p.gaussx(2));
        end
        

    else
        t = m2v;
        t2 = [0;diff(m2v)];
        
        if p.reglicking
            l = l2v;
            l2 = [0;diff(l2v)];
        end
    end
   	t0 = ones(sizevec(1) * sizevec(2), 1);
    
    % Look
%     figure
%     plot(mean(d2,2));
%     hold on
%     plot(mean(reshape(t, sizevec),2));
%     plot(mean(reshape(t2, sizevec),2));
%     hold off
    
    % Weights
    if p.reglicking
        wt = [t, t2, l, t0] \ d2v;
    else
        wt = [t, t2, t0] \ d2v;
    %     wt = glmfit([t],d2v, 'normal');
    end
    
    % Subtract
    if p.reglicking
        d2s = d2v - [t, t2, l, t0] * wt;
    else
        d2s = d2v - [t, t2, t0] * wt;
    %     d2s = d2v - [t, t0] * wt([1 3]);
    end
    
    % Reshape back
    d2s = reshape(d2s, sizevec);
    d2s = d2s + ones(sizevec(1),1) * meanvecd;
    
    % Put the means back
    datastruct(i).photometry_trig = d2s;
    datastruct(i).photometry_trigavg = mean(d2s, 2);
end




end