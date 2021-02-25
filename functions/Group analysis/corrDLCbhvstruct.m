function corrDLCbhvstruct(bhvstruct, DLCbhvstruct, varargin)
% corrDLCbhvstruct performs correlatoin between behavioral metrics and
% photometry data
% corrDLCbhvstruct(bhvstruct, DLCbhvstruct, varargin)

% Parse input
p  = inputParser;

addOptional(p, 'keepc', {}); % Criteria for keeping the data. Leave blank to keep all data.
addOptional(p, 'eventonly', false); % Event only, overrides the window below
addOptional(p, 'corrwindow', [-5 5]); % Can be vector or just the 'event'
                                                             
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Apply keep criteria
% Number of datasets
nset = size(bhvstruct, 1);
nsetDLC = size(DLCbhvstruct, 1);

% Calculate which datasets to keep
keepvec = ones(nset, 1);
keepvecDLC = ones(nsetDLC, 1);
nkeepc = size(p.keepc, 1);

% Loop through to update the keep vector
for i = 1 : nkeepc
    
    % Grab the critia
    cri = p.keepc{i,2};
    
    if ~isempty(cri) % Empty means keep everything
        % Using field as a keep option
        % Grab the relevant data
        keepvec_curr = [bhvstruct(:).(p.keepc{i,1})]';
        keepvec_curr_DLC = [DLCbhvstruct(:).(p.keepc{i,1})]';
        
        % Do the comparison
        keepvec_curr = keepvec_curr * ones(1, length(cri)) ==...
            ones(nset, 1) * cri;
        keepvec_curr_DLC = keepvec_curr_DLC * ones(1, length(cri)) ==...
            ones(nset, 1) * cri;
        keepvec_curr = sum(keepvec_curr, 2) > 0;
        keepvec_curr_DLC = sum(keepvec_curr_DLC, 2) > 0;

        % Update the keep vector
        keepvec = keepvec .* keepvec_curr;
        keepvecDLC = keepvecDLC .* keepvec_curr_DLC;
    end
end
        
% Apply keep vecc
bhvstruct = bhvstruct(keepvec > 0);
DLCbhvstruct = DLCbhvstruct(keepvec > 0);

%% Match trials
% Match by session and event start time
% Decimal factor (for combining two vectors into one);
eventtime = [bhvstruct(:).eventtime]';
DLCeventtime = [DLCbhvstruct(:).eventtime]';
decifactor = 10^ceil(log(max(max(eventtime), max(DLCeventtime)))/log(10));
matchvec = [bhvstruct(:).session]' + eventtime/decifactor;
matchvecDLC = [DLCbhvstruct(:).session]' + DLCeventtime/decifactor;

% matching
[~, ibhv, idlc] = intersect(matchvec, matchvecDLC);
bhvstruct = bhvstruct(ibhv);
DLCbhvstruct = DLCbhvstruct(idlc);

% Sets
nset = size(bhvstruct, 1);

%% Extract data
% Window
if ~p.eventonly
    w = p.corrwindow * bhvstruct(1).Fs + bhvstruct(1).bhvind(1);
    wDLC = p.corrwindow * DLCbhvstruct(1).fps + DLCbhvstruct(1).bhvind(1);
end

% Initialize
datacell = cell(nset, 2);

for i = 1 : nset
    % Window (event-only mode)
    if p.eventonly
        wDLC = DLCbhvstruct(i).bhvind;
        w = bhvstruct(i).bhvind;
        w(2) = w(1) + diff(wDLC);
    end
    
    % Load
    datacell{i,1} = bhvstruct(i).data(w(1):w(2));
    datacell{i,2} = DLCbhvstruct(i).data(wDLC(1):wDLC(2));
end

% Convert to matrixform
datamat = cell2mat(datacell);

%% Plot
% Get R
R = corr(datamat);
R = R(1,2);

% Fit
linfit = fit(datamat(:,1), datamat(:,2), 'poly1');

% Plot
figure
plot(linfit, datamat(:,1), datamat(:,2), 'o');
xlabel('Photometry data');
ylabel('DLC data');
title(sprintf('Correlation = %1.3f', R));

end