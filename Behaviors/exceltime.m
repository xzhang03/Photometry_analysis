function outputmat = exceltime()
% exceltime converts excel time to decimal times in units of minutes.
% Output is a m x 3 matrix, in which the colums are [Code, Start_time,
% End_time].
% outputmat = exceltime()
% Stephen Zhang 2020/01/27

%% Settings
% Assume time input is min:sec (can be changed to hour:min)
timeformat = 'min:sec';

% Default values
Defaultt0 = '0:03';
DefaultCode = '0';
DefaultPaste = '';

%% Initialize
% Flag variables
CollectMore = true;

% Cell for the times (Initialize 10 to start)
Timecell = cell(10, 2);
ind = 0;

% Loop
while CollectMore
    %% Input
    % Collect data
    prompt = {'Starting time:', 'Behavioral code:', 'Excel paste:'};
    dlgtitle = 'Excel Time';
    dims = [1 70; 1 70; 10 70];
    definput = {Defaultt0, DefaultCode, DefaultPaste};
    data = inputdlg(prompt, dlgtitle, dims, definput);

    %% Parse
    % Get time text
    timetext = data{3};
    
    % If multiple rows, linearize them
    if size(timetext,1) > 1
        % Linearize (also remove left and right spaces and tabs)
        timetexttemp = timetext;
        timetext = strtrim(timetexttemp(1,:));
        
        for i = 2 : size(timetexttemp,1)
            timetext = horzcat(timetext, sprintf('\t'), timetexttemp(i,:)); %#ok<AGROW>
        end
    else
        % Remove left and right spaces and tabs
        timetext = strtrim(timetext);
    end
    
    % If empty, discard the entry
    if isempty(timetext)
        % Don't collect more
        CollectMore = false;
    else
        % Propagate ind
        ind = ind + 1;
        
        %% T0
        % Grab t0 string and trim
        t0s = strtrim(data{1});
                
        % Locate indices
        colonind = strfind(t0s, ':');
        l = length(t0s);
        minind = [1 colonind-1];
        secind = [colonind+1 l];
        
        % Min and sec
        min0 = str2double(t0s(minind(1) : minind(2)));
        sec0 = str2double(t0s(secind(1) : secind(2)));
        
        % Log time 0
        switch timeformat
            case 'min:sec'
                t0 = min0 + sec0 / 60;
            case 'house:sec'
                t0 = min0 * 60 + sec0;
        end
        
        %% Time paste
        % Locate string markers
        colonind = strfind(timetext, ':');
        tabind = regexp(timetext, '\t');
        l = length(timetext);
        n = length(colonind);
        
        % Get the indices
        minind1 = [1 tabind+1];
        minind2 = colonind-1;
       
        secind1 = colonind+1;
        secind2 = [tabind-1 l];
        
        % Get a vector of times
        timevec = zeros(1, n);
        for i = 1 : n
            % Get min and sec
            min_c = str2double(timetext(minind1(i) : minind2(i)));
            sec_c = str2double(timetext(secind1(i) : secind2(i)));
            
            % Calcualte decimal min
            switch timeformat
                case 'min:sec'
                    timevec(i) = min_c + sec_c / 60;
                case 'house:sec'
                    timevec(i) = min_c * 60 + sec_c;
            end
        end
        
        % Log time vec after subtracting t0
        Timecell{ind, 2} = timevec - t0;
        
        %% Behavioral code
        % Just log
        Timecell{ind, 1} = str2double(data{2}) * ones(1, n/2);
        
        %% See if collect more
        % Dialog
        moreornot = questdlg('More times?', 'Continue', 'Yes', 'No', 'No');
        
        % If more
        if strcmp(moreornot, 'Yes')
            % Refresh defaults if more
            Defaultt0 = data{1};
            DefaultCode = data{2};
        else
            % Flag disontinue
            CollectMore = false;
        end
    end
end

%% Concatenate data
% Total time vectors and code vectors
Timevec_total = [Timecell{1:ind, 2}];
Codevec_total = [Timecell{1:ind, 1}];
N_total = length(Codevec_total);

% Reshape and output
outputmat = horzcat(Codevec_total', reshape(Timevec_total, 2, N_total)');

end