function [datastruct, n_series] = mkoptostruct(inputloadingcell, defaultpath)
% mkdatastruct makes a triggered opto structure based on the input data addresses.
% [datastruct, n_series] = mkoptostruct(inputloadingcell, defaultpath)

% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell,defaultpath);

% data samples
n_series = size(loadingcell, 1);

% Initialize
datastruct = struct('photometry_trig', 0, 'photometry_trigavg', 0, 'Fs', 0,...
    'nstims', 0, 'window_info', [0 0 0]);
datastruct = repmat(datastruct, [size(loadingcell,1), 1]);

% Load data
for i = 1 : n_series
    % Load photometry things
    loaded = load (fullfile(loadingcell{i,1}, loadingcell{i,6}));
    datastruct(i).photometry_trig = loaded.trigmat;
    datastruct(i).photometry_trigavg = loaded.trigmat_avg;
    datastruct(i).Fs = loaded.freq;
    
    % Load window info
    datastruct(i).window_info = [loaded.prew_f, loaded.postw_f, loaded.l];
    
    % Number of stims
    datastruct(i).nstims = loaded.n_optostims;
end


end