function datastruct = trimoptostruct(datastruct, varargin)
% Re-trim photometry triggered data per trial or subselect trials 


if nargin < 2
    varargin = {};
end

% Parse input
p  = inputParser;

addOptional(p, 'Fs', []);
addOptional(p, 'prew', []);
addOptional(p, 'postw', []);

addOptional(p, 'filterbyensure', false); % Subselect only trials with ensure

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Filter by ensure
if p.filterbyensure
    for i = 1 : length(datastruct)
        e = max(datastruct(i).ensure, [], 1) > 0.5;
        datastruct(i).photometry_trig = datastruct(i).photometry_trig(:,e);
        datastruct(i).photometry_trigavg = mean(datastruct(i).photometry_trig, 2);
        datastruct(i).mouseid = datastruct(i).mouseid(e);
        datastruct(i).order = datastruct(i).order(e);
        datastruct(i).rorder = datastruct(i).rorder(e);
        datastruct(i).nstims = sum(e);
        datastruct(i).tls = datastruct(i).tls(e);
        datastruct(i).locomotion = datastruct(i).locomotion(:,e);
        datastruct(i).lick = datastruct(i).lick(:,e);
        datastruct(i).ensure = datastruct(i).ensure(:,e);
    end
end

%% Loop through to trim traces
if ~isempty(p.Fs) && ~isempty(p.prew) && ~isempty(p.postw)
    prew = p.Fs * p.prew;
    postw = p.Fs * p.postw;
    
    for i = 1 : length(datastruct)
        if datastruct(i).Fs ~= p.Fs || datastruct(i).window_info(1) ~= prew || datastruct(i).window_info(2) ~= postw
            % Data tranches
            predata = datastruct(i).photometry_trig(1:datastruct(i).window_info(1), :);
            middata = datastruct(i).photometry_trig(datastruct(i).window_info(1)+1, :);
            postdata = datastruct(i).photometry_trig(datastruct(i).window_info(1)+2:end, :);
            
            % Locomotion tranches
            preloco = datastruct(i).locomotion(1:datastruct(i).window_info(1), :);
            midloco = datastruct(i).locomotion(datastruct(i).window_info(1)+1, :);
            postloco = datastruct(i).locomotion(datastruct(i).window_info(1)+2:end, :);
            
            % Lick tranches
            prelick = datastruct(i).locomotion(1:datastruct(i).window_info(1), :);
            midlick = datastruct(i).locomotion(datastruct(i).window_info(1)+1, :);
            postlick = datastruct(i).locomotion(datastruct(i).window_info(1)+2:end, :);

            % Bin pre
            if  datastruct(i).Fs ~= p.Fs 
                predata = tcpBin(predata, datastruct(i).Fs, p.Fs, 'mean', 1);
                postdata = tcpBin(postdata, datastruct(i).Fs, p.Fs, 'mean', 1);
                preloco = tcpBin(preloco, datastruct(i).Fs, p.Fs, 'mean', 1);
                postloco = tcpBin(postloco, datastruct(i).Fs, p.Fs, 'mean', 1);
                prelick = tcpBin(prelick, datastruct(i).Fs, p.Fs, 'mean', 1);
                postlick = tcpBin(postlick, datastruct(i).Fs, p.Fs, 'mean', 1);
            end
    
            % Get pre
            if size(predata, 1) ~= prew
                predata = predata(end-prew+1:end,:);
                preloco = preloco(end-prew+1:end,:);
                prelick = prelick(end-prew+1:end,:);
            end
    
            % Get post
            if size(postdata, 1) ~= postw
                postdata = postdata(1:postw,:);
                postloco = postloco(1:postw,:);
                postlick = postlick(1:postw,:);
            end
    
            datastruct(i).photometry_trig = cat(1, predata, middata, postdata);
            datastruct(i).photometry_trigavg = mean(datastruct(i).photometry_trig, 2);
            datastruct(i).locomotion = cat(1, preloco, midloco, postloco);
            datastruct(i).lick = cat(1, prelick, midlick, postlick);
            datastruct(i).window_info = [prew, postw, prew+postw+1];
            datastruct(i).Fs = p.Fs;
        end
    end
end

end