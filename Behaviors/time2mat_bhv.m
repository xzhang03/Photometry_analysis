function time2mat_bhv(A, mouse, date, runnum, filepath)
% time2mat convert scoring data to behavioral matrix. This version does not
% use photometry path.
% time2mat(A, filepath)

%% Initialization
if nargin < 5 
    % Default path
    defaultpath = '\\anastasia\data\behavior';
    if nargin < 4
        % run
        runnum = input('Run: ');
        
        if nargin < 3
            % Date
            date = input('Date: ', 's');
            
            if nargin < 2
                % Mouse
                mouse = input('Mouse: ', 's');
            end
        end
    end
else
    defaultpath = filepath;
end



%% Processing

% Find A matrix
if isempty(A)
    disp('A-matrix cannot be empty.')
else
    % Clean up mouse name
    mouse = upper(mouse);
    
    % CLean up date
    if ~ischar(date)
        date = num2str(date);
    end
    
    % Clean up run
    if runnum < 10
        runstr = sprintf('00%i', runnum);
    elseif runum < 100
        runstr = sprintf('0%i', runnum);
    else
        runstr = num2str(runnum);
    end
    
    % Date mouse
    datemouse = sprintf('%s_%s', date, mouse);
    
    
    % Mouse folder
    if ~exist(fullfile(defaultpath, mouse), 'dir')
        fprintf('Making a new mouse folder: %s.\n', mouse)
        mkdir(defaultpath, mouse);
    end
    
    % Date folder
    if ~exist(fullfile(defaultpath, mouse, datemouse), 'dir')
        fprintf('Making a new date folder: %s.\n', datemouse);
        mkdir(fullfile(defaultpath, mouse, datemouse));
    end
    
    % Work out outputpath
    filename_output = sprintf('%s-%s-%s-nidaq_A.mat', mouse, date, runstr);
    filepath_output = fullfile(defaultpath, mouse, datemouse);
    
    % If more than one row of behvioral scoring
    if size(A,2) > 1
        A = A';
        A = A(:);
    end

    A = reshape(A, 3, [])';
    A = A(A(:,2) > 0, :);
    
    if ~exist(fullfile(filepath_output, filename_output), 'file')
        % Save
        save(fullfile(filepath_output, filename_output), 'A', 'mouse', 'date', 'runstr');
        fprintf('Saved to: %s\n', fullfile(filepath_output, filename_output));
    elseif input('Behavior mat file already exists. Overwrite? (1 = Yes, 0 = No): ') == 1
        % Save
        save(fullfile(filepath_output, filename_output), 'A', 'mouse', 'date', 'runstr');
        fprintf('Saved to: %s\n', fullfile(filepath_output, filename_output));
    end
    
end
end