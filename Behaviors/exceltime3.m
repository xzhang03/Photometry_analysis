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
key=[data{:, 1}];
start_time=minutes(duration(data{:, 2}, 'InputFormat', 'mm:ss'));
end_time=minutes(duration(data{:, 3}, 'InputFormat', 'mm:ss'));
outputmat = [key start_time end_time];
end
