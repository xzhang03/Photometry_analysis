function loadingcell = mkloadingcell(inputcell, genpath)
% mkloadingcell makes a loading cell for pathing. Inputcell should be in
% the format of {mouse, date, run}.
% loadingcell = mkloadingcell(inputcell, genpath)

if nargin < 2
    genpath = '\\anastasia\data\photometry';
end

% Initialize loading cell
loadingcell = cell(size(inputcell, 1), 4);

for i = 1 : size(inputcell,1)
    % Mouse
    mouse = inputcell{i,1};
    
    % Date
    if ~ischar(inputcell{i,2})
        date = num2str(inputcell{i,2});
    else
        date = inputcell{i,2};
    end
    
    % run
    if ~ischar(inputcell{i,3})
        if inputcell{i,3} < 10
            runind = ['00',num2str(inputcell{i,3})];
        elseif inputcell{i,3} < 100
            runind = ['0',num2str(inputcell{i,3})];
        else
            runind = num2str(inputcell{i,3});
        end
    else
        runind = inputcell{i,3};
    end
    
    
    % Folder name
    loadingcell{i,1} =...
        fullfile(genpath, inputcell{i,1}, [date,'_',mouse]);
    
    % Photometry data name
    loadingcell{i,2} =...
        sprintf('%s-%s-%s-nidaq_preprocessed_fixed.mat', mouse, date, runind);
    
    % Behavior data name
    loadingcell{i,3} =...
        sprintf('%s-%s-%s-nidaq_A.mat', mouse, date, runind);
    
    % Preprocessed data name
    loadingcell{i,4} =...
        sprintf('%s-%s-%s-nidaq_preprocessed.mat', mouse, date, runind);
    
end

end
