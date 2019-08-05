function binneddata = tcpBin(inputdata, inputFs, outputFs, method, dim)
% tcpBin bins data to a different sample rate. If the binning factor is not
% integer, the program will attempt to approximate rationalized factor, in 
% the form of a fraction.
% binneddata = tcpBin(inputdata, inputFs, outputFs, method, dim)
% intputdata: 1 or 2 dimensional data
% method: a string that can be 'mean', 'median', 'downsample', 'max', 'min'
% dim: the dimension along which the binning happens


% Index for downsample (take the Xth number every cycle).
ds_ind = 1;

% Defaults
if nargin < 5
    dim = 1;
    if nargin < 4
        method = 'mean';
        if nargin < 3
            outputFs = 5;
            if nargin < 2
                inputFs = 50;
            end
        end
    end
end

% Adjust and grab dimensions
if dim == 2
    inputdata = inputdata';
end
[nsamples, nseries] = size(inputdata);

% Calculate binning factor
binfact = inputFs / outputFs;

% Anonymous funciton for integer determination
intcheck = @(x) floor(x) == x;

% Divisibility check
if intcheck (binfact)
    disp(['Using a binning factor of ', num2str(binfact)]);
    disp(['Throwing away the last: ', ...
        num2str(mod(nsamples, binfact)), ' frames']);
    
    % Number of samples after binning
    nsamples_result = floor(nsamples/binfact);
    
    % Data after binning
    binneddata_tensor = nan(binfact, nsamples_result, nseries);
    
    for i = 1 : nseries
        % Grab data
        datavec = inputdata(1 : nsamples_result * binfact, i);
        
        % Reshape and fill
        binneddata_tensor(:,:,i) =...
            reshape(datavec, binfact, nsamples_result);
    end
    
else
    [binN, binD] = rat(binfact, 0.01);
    disp(['Binning factor is not integer. Using a fraction instead: ',...
        num2str(binN), '/', num2str(binD)]);
    disp(['Throwing away the last: ', ...
        num2str(mod(nsamples * binD, binN) / binD), ' frames']);
    
    % Number of samples after binning
    nsamples_result = floor(nsamples / binN) * binD;
    
    % Data after binning
    binneddata_tensor = nan(binN, nsamples_result, nseries);
    
    for i = 1 : nseries
        % Grab data
        datavec = inputdata(1 : nsamples_result / binD * binN, i);
        
        % Expand the data
        datavec2 = ones(binD,1) * datavec';
        datavec2 = datavec2(:);
        
        % Reshape and fill
        binneddata_tensor(:,:,i) =...
            reshape(datavec2, binN, nsamples_result);
    end
end

% Initialize
binneddata = nan(nsamples_result, nseries);

% Loop through and apply filter
for i = 1 : nseries
    switch method
        case 'mean'
            binneddata(:,i) = mean(binneddata_tensor(:,:,i), 1)';
        case 'median'
            binneddata(:,i) = median(binneddata_tensor(:,:,i), 1)';
        case 'downsample'
            binneddata(:,i) = binneddata_tensor(ds_ind,:,i)';
        case 'max'
            binneddata(:,i) = max(binneddata_tensor(:,:,i), [], 1)';
        case 'min'
            binneddata(:,i) = min(binneddata_tensor(:,:,i), [], 1)';
    end
end



end