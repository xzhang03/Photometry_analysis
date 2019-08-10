function [filteredvec, filt, samplerate] = TDfilt(inputvec, varargin)
% CONTFILT - filter data in a cont structure
%
%  [filteredvec, filt] = TDfilt(inputvec, varargin)
%
% Filter all channels in a cont struct using provided filter or filter
% design criteria. By default, downsamples highly oversampled signals before
% filtering for computational efficiency. Compensates for group delay.
%
% Inputs: (* means required, -> indicates default value)
%   * inputvec - a vector to be filtered
%   *'filtopt' - filter design struct as created by mkfiltopt. See
%      example usage below 
%    'filt' - provide a filt struct as created by mkfilt (or as returned
%       from a previous run of contfilt). Saves filter design time, and
%       useful for maintaining consistency in analysis. 
%    'autoresample' - whether to downsample the signal before
%       low-pass or band-pass filtering. Very conservative and
%       safe--downsampling is to 20x the Nyquist of the end of the high
%       stopband (->true, false).
%
%   Infrequently used inputs:
%    'cache' - an object cache containing previously designed filters can
%       be searched to save design time. (default []).
%
%   Outputs:
%    filteredvec - filtered (possibly resampled) data
%
%   Example: Filter some data in the theta band:
%
%     fopt = mkfiltopt('filttype', 'bandpass', ...
%                      'F', [4 6 10 12], ... % passband is 6-10 Hz
%                      'name', 'theta')
%
%     dat_theta = contfilt(dat, 'filtopt', fopt);

% Tom Davidson <tjd@alum.mit.edu> 2003-2010
% Modified by Stephen Zhang 2019


a = struct(...
  'filt', [],...
  'filtopt', [],...
  'nonlinphaseok', false,...
  'nodelaycorrect', false,...
  'samplerate', [],...
  'autoresample', true);

a = parseArgsLite(varargin,a);


if isempty(a.autoresample)
    a.autoresample = true;
end

  
% Auto resample if needed    
if a.autoresample && ~strcmp(a.filtopt.filttype, 'highpass')
    oversampf = 10; % new Fs factor above 2 * top of highest stop band
  
    % resampling factor
    res_f = a.filtopt.F(end) * 2 * oversampf / a.samplerate;
  
    if res_f >= 1
        disp('no resampling necessary');
    else        
        % resample
        [inputvec, res_f] = TDresamp(inputvec,'resample', res_f);
        a.samplerate = a.samplerate * res_f;
    end
  
end


% Use provided filter if there is one (risky).
if ~isempty(a.filt)
%     disp('Using the provided filter')
    filt = a.filt;
else
    % if we are making a filter, set the samplerate from the data
    a.filtopt.Fs = a.samplerate;
    
    % Make filter
    filt = mkfilt('filtopt', a.filtopt);
end

% Filter
filteredvec = subf_contfilter(inputvec,filt,a);
  
% Output sample rate
samplerate = a.samplerate;
                  
  
  
function data = subf_contfilter(data,filt,a)
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% filter data
  
% can't test whether 'isa' 'dfilt' object, so:
  try
    get(filt.dfilt,'FilterStructure');
  catch
    error('''dfilt'' field of ''filt''  must be a dfilt structure');
  end
  
  dataclass = class(data);
  
  filtlen = length(filt.dfilt.Numerator);
  
  % if samplerate is within 1%, use the filters (i.e. 200Hz would be 204Hz) 
  if abs(log10(filt.filtopt.Fs/a.samplerate)) > log10(1.01),
    error(['samplerate of filter doesn''t match data, use a filtopt struct ' ...
           'instead']);
  end
  
  % get rid of previous states, if any
  reset(filt.dfilt);
  
  if ~filt.dfilt.islinphase && ~a.nonlinphaseok
    
    % not linear phase, could use filtfilt to correct instead of erroring...
    warning('Filter has non-linear phase distortion, group delay compensation disabled');
    a.nodelaycorrect = true;
    
    %    warning('dfiltfilt will give sharper responses');
    %    error('dfiltfilt not yet implemented')
    %    c.data = dfiltfilt(a.dfilt,c.data);
    % delta nbad_start and nbad_end will be 2x?
    
  end
  
  % linear phase (can do one-way filt, then correct for grpdelay)
  if ~mod(filtlen,2) && ~a.nodelaycorrect
    warning(['filter length is even, group delay compensation will be ' ...
             'off by 1/2 sample']); %#ok
  end
  
  % if data is 'single', use 'single' arithmetic to save memory
  if strcmp(dataclass,'single')
    filt.dfilt.arithmetic = 'single';
  end
  
%   disp('filtering...');
  
  nchans = size(data,2);
  
  
  % call the 'filter' method of dfilt object
%   try
%     data = filt.dfilt.filter(data);
%   catch
    for k = 1:nchans
      data(:,k) = filt.dfilt.filter(data(:,k));
    end
%   end
  
  
  if ~a.nodelaycorrect
    
    % correct for group delay, zero-pad end (see nbad, below)
    Gd = filt.dfilt.order/2;
    for k = 1:nchans
      data(1:end-Gd,k) = data(Gd+1:end,k);
      data(end-Gd+1:end,k) = 0;
    end
    
   
  end
  

    
%   % cast it back to single, or whatever (necessary?)
%   c.data = cast(c.data, dataclass);
  assert(strcmp(class(data), dataclass));
  
  
end
end