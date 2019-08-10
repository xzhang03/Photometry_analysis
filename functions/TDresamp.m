function [data_res, res_f] = TDresamp(inputdata,varargin)
% CONTRESAMP up- or downsample data in a cont struct, with antialiasing
%
%  [data_res, res_f] = contresamp(inputdata, [param/value pair args])
%
%  Usage note: to resample a cont struct to a specific samplerate (rather
%  than by a fraction), use the continterp function with the 'samplerate'
%  option. 
%  
% Inputs:
%  * inputdata - input data
%  *'resample'- fraction to up/downsample signal
%
%  Infrequently-used options:
%   'tol' - fractional tolerance for detecting integer resampling factors
%   'res_filtlen' - length of resampling filter to apply in non-decimation
%      case (defaults to 10)
%
% Example: To downsample data to a 5x lower sampling frequency
%
%  dataout = contresamp(data, 'resample', 1/5);

% Tom Davidson <tjd@alum.mit.edu> 2003-2010 
% Modified by Stephen Zhang 2019

  
  
  a = struct(...
      'resample',[],...
      'tol', 0.001,...
      'res_filtlen', 10,...
      'res_beta', 5);
  
  a = parseArgsLite(varargin,a);

  % keep it, for later
  datatype = class(inputdata);
  [nrows, ncols] = size(inputdata);

  if islogical(inputdata)
    error('Can''t filter data of type ''logical''');
  end
  
  if ~isempty(a.resample)
    
    if a.resample == 1
      disp('Resample factor == 1, nothing to do...');
      return
    end
      

    % 'resample'
    % use a wider tolerance than the default (1e-6) to get smaller terms
    % for resampling (use continterp for very precise control over sampling
    % rates/times)
    [res_num, res_den] = rat(a.resample, a.resample.*a.tol);
    res_f = res_num / res_den;
    filtlen = a.res_filtlen;
    
%     disp(['Resampling by a factor of ', num2str(res_f)]);
    
    % pre-allocate
    % (note must use res_num/res_den rather than res_f for this calculation,
    % since this is what 'resample' uses internally, and in some cases
    % (e.g. 6724096*47/46) float error would cause the 2 to give a different
    % answer).
    data_res = zeros(ceil(nrows*res_num/res_den), ncols, datatype);
    for col = 1:ncols 
        
        % resample can't handle 'single' type data. bug
        % filed with mathworks 11/14/06. R14SP2 and later correctly error
        % on 'single' inputs)
        data_res(:,col) = cast(resample(double(inputdata(:,col)),...
                                    res_num, res_den,...
                                    filtlen, a.res_beta),...
                                    datatype);
    end


  else
    disp('no resample requested');
  end
end