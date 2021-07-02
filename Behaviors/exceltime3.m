function outputmat = exceltime3(varargin)
% exceltime
% Output is a m x 3 matrix, in which the colums are [Code, Start_time,
% End_time].
% outputmat = exceltime()

prompt = {'Excel paste:'};
dlgtitle = 'Excel Time';
dims = [10 70];
definput = {''};
inputdata = inputdlg(prompt, dlgtitle, dims, definput);

data = textscan(inputdata{:},'%f%s%s');
key =[data{:, 1}];

% manually parse -_-
pre_start_time = cellfun(@(x) strsplit(x, ':'), data{:, 2}, 'UniformOutput', false);
pre_start_time = vertcat(pre_start_time{:});
pre_start_time = cell2mat(cellfun(@(x) str2num(x), pre_start_time, 'UniformOutput', false));
start_time = pre_start_time(:, 1) + (pre_start_time(:, 2)/60);

% manually parse -_-
pre_end_time = cellfun(@(x) strsplit(x, ':'), data{:, 3}, 'UniformOutput', false);
pre_end_time = vertcat(pre_end_time{:});
pre_end_time = cell2mat(cellfun(@(x) str2num(x), pre_end_time, 'UniformOutput', false));
end_time = pre_end_time(:, 1) + (pre_end_time(:, 2)/60);

outputmat = [key start_time end_time];
end
