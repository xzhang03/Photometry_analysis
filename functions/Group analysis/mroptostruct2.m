function datastruct = mroptostruct2(datastruct, varargin)
% mroptostruct2 applies motion regression to photometry data

if nargin < 2
    varargin = {};
end

% Parse input
p  = inputParser;

addOptional(p, 'convolvegauss', true); % Convolution of motion data
addOptional(p, 'gaussx', [-20,20]);
addOptional(p, 'gausssig', 5);
addOptional(p, 'runningaverage', false); % Running average of motion data, turn this or gaussian on, but not both
addOptional(p, 'runningaveragewin', 25); % Running average window
addOptional(p, 'reglicking', false);
addOptional(p, 'prewindow', 230);
addOptional(p, 'wt', []);

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Gaussian
%if p.convolvegauss
    gauss_distribution = @(x, mu, s) exp(-.5 * ((x - mu)/s) .^ 2) ./ (s * sqrt(2*pi)); 
    gs1 = gauss_distribution(p.gaussx(1):p.gaussx(2),0,p.gausssig)';
    gs2 = circshift(gs1, 20);
    gs3 = circshift(gs1, 40);
    gs4 = circshift(gs1, 80);
%end

%% Exponential (for real signal)
  exp_fun = @(freq, x, tau) exp(-(0:1/freq:x)/tau); 
  Freqs = 25; % Hz ***
  kernel_length = 60;
  tau = 10; % seconds ***
  exp1 = exp_fun(Freqs,kernel_length,tau)';

%% Process
% Number
n = length(datastruct);


% Loop through
for i = 1 : n
    % Get the dataout
    d = datastruct(i).photometry_trig;
    m = datastruct(i).locomotion;
    f = datastruct(i).ensure;
    if p.reglicking
        l = datastruct(i).lick;
    end
    
    % Size
    sizevec = size(d);
    
    % Running average
    if p.runningaverage
        m = movmean(m, p.runningaveragewin, 1);
        if p.reglicking
            l = movmean(l, p.runningaveragewin, 1);
        end
    end

    % Subtract trial pre-window means
    d2 = d;
    m2 = m;
    f2 = f;
    if p.reglicking
        l2 = l;
    end
    for j = 1:size(d,2)
        d2(:,j) = d2(:,j) - mean(d2(1:p.prewindow)); 
        m2(:,j) = m2(:,j) - mean(m2(1:p.prewindow)); 
        l2(:,j) = l2(:,j) - mean(l2(1:p.prewindow)); 
        f2(:,j) = f2(:,j) - mean(f2(1:p.prewindow));
    end

    % Linearize
    d1v = d(:);
    d2v = d2(:);
    m2v = m2(:);
    f2v = f2(:);
    if p.reglicking
        l2v = l2(:);
    end

    % Prepare for regression
    if p.convolvegauss
        t = conv(m2v, gs1);
        t2 = conv([0;diff(m2v)], gs1);

        t = t(1-p.gaussx(1) : end-p.gaussx(2));
        t2 = t2(1-p.gaussx(1) : end-p.gaussx(2));
        
        if p.reglicking
            l = conv(l2v, gs1);
            l2 = conv([0;diff(l2v)], gs1);
            
            l = l(1-p.gaussx(1) : end-p.gaussx(2));
            l2 = l2(1-p.gaussx(1) : end-p.gaussx(2));
        end

        %convolve feeding mat with exponential decay
        f_exp = conv(f2v,  exp1, 'same');
           
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
    % figure
    % plot(mean(d2,2));
    % hold on
    % plot(mean(reshape(t, sizevec),2));
    % plot(mean(reshape(t2, sizevec),2));
    % plot(mean(reshape(l, sizevec),2));
    % hold off
    
    % Weights
    % if ~isempty(p.wt)
        if p.reglicking
           wt = [f_exp, t, t2, l, l2, t0] \ d2v;
          %wt = glmfit([f_exp, t, t2, l, t0], d2v, 'normal', 'Constant', 'off');
        else
            wt = [f_exp, t, t2, t0] \ d2v;
        %     wt = glmfit([t],d2v, 'normal');
        end
        datastruct(i).GLM_wts = wt; %save wts
    % end
    
    % Subtract from original
    if p.reglicking
        d1s = d1v - [t, t2, l, l2, t0] * wt(2:end);
    else
        d1s = d1v - [t, t2, t0] * wt(2:end);
    %     d2s = d2v - [t, t0] * wt([1 3]);
    end
    
    % Reshape back
    d1s = reshape(d1s, sizevec);
    
    % Put the means back
    datastruct(i).photometry_trig = d1s;
    datastruct(i).photometry_trigavg = mean(d1s, 2);
end




end