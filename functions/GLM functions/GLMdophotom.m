function [Modeled_data, Model_coef, Actual_data] = GLMdophotom(datastruct, basisstruct, varargin)
% GLMdophotom uses matlab native function glmfit to implement a GLM
% [Modeled_data, Model_coef, Actual_data] = GLMdophotom(datastruct, basisstruct, varargin)

% Parse inputs
p = inputParser;

% General variables
addOptional(p, 'PlotOrNot', true); % Plot or not
addOptional(p, 'DataFieldName', 'photometry'); % Field name for what data to do GLM on
addOptional(p, 'SetsToUse', []);

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% Fix sets to use if needed
if isempty(p.SetsToUse)
    p.SetsToUse = 1 : size(datastruct, 1);
end

% Find basisfunctions fields
fieldnames_list = fieldnames(basisstruct);
basisfields =  endsWith(fieldnames_list,'_sbf');
basisfield_names = fieldnames_list(basisfields);

% Initialize a cell that contains all the basis functions
basis_cell = cell(length(p.SetsToUse), sum(basisfields));

% Initialize a cell that contains all the photometry data
Actual_data_cell = cell(length(p.SetsToUse), 1);

% Loop through
for i = 1 : length(p.SetsToUse)
    % Set index
    setind = p.SetsToUse(i);
    
    % Fill in data
    Actual_data_cell{i} = datastruct(setind).(p.DataFieldName);
    
    for j = 1 : sum(basisfields)
        % Fill in
        basis_cell{i,j} = basisstruct(setind).(basisfield_names{j});
    end
end

% Initialize a cell that concatenates the basis fucntions
basis_cell_total = cell(1, sum(basisfields));

% Loop through
for j = 1 : sum(basisfields)
     basis_cell_total{j} = cell2mat(basis_cell(:,j)); % Concatenate across experiments
end

% Total basis function
BASISfun = [basis_cell_total{:}];
% BASISfun = [ones(size(BASISfun,1),1),BASISfun];

% Actual data
Actual_data = cell2mat(Actual_data_cell(:));

% Fit
Model_coef = lassoglm(BASISfun, Actual_data, 'normal', 'Standardize', false, 'Lambda', 0.01);

% Calculate model data
% Modeled_data = BASISfun * Model_coef(2:end) + Model_coef(1);
Modeled_data = BASISfun * Model_coef;

% Plot if asked for
if p.PlotOrNot
    plot([Actual_data, Modeled_data]);
    legend({'Actual data', 'Modeled data'})
end

end

