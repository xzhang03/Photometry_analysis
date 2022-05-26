function out = extrabinoptostruct(optostruct, varargin)
% Extract binned values in opto structures

% Parse input
p  = inputParser;

addOptional(p, 'datasets', []); % Which datasets to use. Leave blank to keep all data.

% Nans and other keep criteria
addOptional(p, 'removenans', true); % Remove nans or not. Based on the first field
addOptional(p, 'nantolerance', 0); % Remove trials with more than this fraction of nan data
addOptional(p, 'keepc', {'order',[]}); % Criteria for keeping data (just a 1 x 2 cell)

% Binning and extraction info
addOptional(p, 'fields', {'photometry_trig', 'locomotion'});
addOptional(p, 'window', {});
addOptional(p, 'baselinewindow', {});
addOptional(p, 'bin', 1);

% Correlation
addOptional(p, 'docorr', true);
addOptional(p, 'binnedcorr', false);
                                                             
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;


%% Clean up
% Corr
nfields = length(p.fields);
pairs = nchoosek(1 : nfields, 2);
npairs = size(pairs,1);

%% Load
% Load data
datacell = cell(nfields, 1);
for i = 1 : nfields
    fid = p.fields{i};
    if isempty(p.datasets)
        datamat = cell2mat({optostruct(:).(fid)});
    else
        datamat = cell2mat({optostruct(p.datasets).(fid)});
    end
    datacell{i} = datamat;
end

% Get trials per session
trialspersession = size(optostruct(1).(fid), 2);

% Number of trials
ntrials = size(datamat, 2);
            
% Keep data as criteria
% (Skip this if we are plotting pre/post-triggered data)
if ~isempty(p.keepc{1,2})
    % Calculate which datasets to keep
    keepvec = ones(ntrials, 1);
    nkeepc = size(p.keepc, 1);
    
    for i = 1 : nkeepc
        if isempty(p.datasets)
            % vector for keeping stuff
            keepvec_curr = cell2mat({optostruct(:).(p.keepc{i,1})})';
        else
            keepvec_curr = cell2mat({optostruct(p.datasets).(p.keepc{i,1})})';
        end

        % Grab the critia
        cri = p.keepc{i,2};

        % Do the comparison
        keepvec_curr = keepvec_curr * ones(1, length(cri)) ==...
            ones(ntrials, 1) * cri;
        keepvec_curr = sum(keepvec_curr, 2) > 0;
        
        % Update keep vector
        keepvec = keepvec .* keepvec_curr;
    end
    
    % Update data
    for i = 1 : nfields
        datamat = datacell{i};
        datamat = datamat(:, keepvec > 0);
        datacell{i} = datamat;
    end
    
    % Update Number of trials
    ntrials = size(datamat, 2);
end

if p.removenans
    goodtrials = mean(isnan(datacell{1}),1) >= p.nantolerance;
    % Update data
    for i = 1 : nfields
        datamat = datacell{i};
        datamat = datamat(:, goodtrials);
        datacell{i} = datamat;
    end
    
    ntrials = size(datamat, 2);
end


%% Extract
% Extract mat
extractdatamat = zeros(ntrials, nfields);
for i = 1 : nfields
    % Windows
    w = p.window{i};
    wb = p.baselinewindow{i};
        
    if isempty(wb)
        extractdatamat(:,i) = nanmean(datacell{i}(w(1):w(2),:));
    else
        extractdatamat(:,i) = nanmean(datacell{i}(w(1):w(2),:)) - nanmean(datacell{i}(wb(1):wb(2),:));
    end
end

%% Binning
if p.bin > 1
    extractdatamat_bin = imresize(extractdatamat, [ntrials/p.bin nfields]);
    trialspersession_bin = trialspersession / p.bin;
    ntrials_bin = ntrials/p.bin;
else
    extractdatamat_bin = extractdatamat;
    trialspersession_bin = trialspersession;
    ntrials_bin = ntrials;
end

%% Corr
corrvec = nan(npairs, 1);
if p.docorr
    for i = 1 : npairs
        if p.binnedcorr
            corrtmp = corr(extractdatamat_bin(:, pairs(i,:)), 'rows', 'complete');
            corrvec(i) = corrtmp(2, 1);
        else
            corrtmp = corr(extractdatamat(:, pairs(i,:)), 'rows', 'complete');
            corrvec(i) = corrtmp(2, 1);
        end
    end
end

%% Output
% Initialize
outputmat = reshape(extractdatamat_bin, [trialspersession_bin, ntrials_bin/trialspersession_bin, nfields]);
outputmat = squeeze(mean(outputmat, 2));

% Output
out.fields = p.fields;
out.data = outputmat;
out.corr = corrvec;
out.pairs = pairs;

end