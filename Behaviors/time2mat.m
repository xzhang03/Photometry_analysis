function time2mat(A, filepath)
% time2mat convert scoring data to behavioral matrix
% time2mat(A, filepath)

%% Initialization
if nargin < 2 
    % Default path
    defaultpath = '\\anastasia\data\photometry';
else
    defaultpath = filepath;
end

% Recording frame rate
cam_save_fps = 30;

% Camera pulse channel
cam_pulse_ch = 4;

%% Processing

% Find A matrix
if isempty(A)
    disp('A-matrix cannot be empty.')
else
    % Got a working A-matrix
    % Work out outputpath
    [filename, filepath] = uigetfile(fullfile(defaultpath , '*nidaq.mat'));
    filename_output = [filename(1:end-4), '_A.mat'];
    load(fullfile(filepath, filename), 'data', 'Fs');

    % Find camera frame rate
    [p_ch1, freq_ch1] = ft2(data(cam_pulse_ch, :), Fs, false);
    [PKS,LOCS]= findpeaks(p_ch1);
    [~, id] = max(PKS);
    cam_pulse_fps = freq_ch1(LOCS(id));
    
    disp(['Pulse rate (Hz): ', num2str(cam_pulse_fps)]);
    
    % If more than one row of behvioral scoring
    if size(A,2) > 1
        A = A';
        A = A(:);
    end

    A = reshape(A, 3, [])';
    A = A(A(:,2) > 0, :);
    
    % Calculate delay
    delay =  find(data(cam_pulse_ch,:) > 0.5, 1) / Fs;
    disp(['Delay (s): ', num2str(delay)]);
    
    % Get aligned behavioral matrix ready
    B = A;
    
    % Align behavioral matrix
    B(:,2:3) = A(:,2:3) * cam_save_fps / cam_pulse_fps + delay/60;
    
    % Save
    save(fullfile(filepath, filename_output), 'A', 'B', 'cam_pulse_fps');
end
end