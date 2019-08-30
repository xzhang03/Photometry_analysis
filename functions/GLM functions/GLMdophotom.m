function [Model_coef, devex, Modeled_data, Actual_data] = GLMdophotom(basisstruct, varargin)
% GLMdophotom uses matlab native function glmfit to implement a GLM
% [Model_coef, devex, Modeled_data, Actual_data] = GLMdophotom(basisstruct, varargin)

% Parse inputs
p = inputParser;

% Master variables
addOptional(p, 'MODE', 'fit'); % Do GLM 'fit' or 'test' existing GLM variables

% General variables
addOptional(p, 'PlotOrNot', true); % Plot or not
addOptional(p, 'DataFieldName', 'data'); % Field name for what data to do GLM on
addOptional(p, 'SetsToUse', []); % Which sets to use
addOptional(p, 'Regularization', 'none');   % Regularization methods:
                                            % 'none', 'lasso'
addOptional(p, 'Lambda', 0.01); % Regularization strength
addOptional(p, 'Alpha', 1); % L1 (1) vs L2 (2) optimization wegihts.
                            % L2 takes a while.
addOptional(p, 'Standardize', false);   % Make basis functions all mu = 0, 
                                        % and sigma = 1; Modeled data is
                                        % inaccuarate is this is set to 
                                        % true right now.
addOptional(p, 'detailedDevex', false);  % give detailed deviance explained data
addOptional(p, 'Coef', []); % Coefficients of the model
                                        
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% Fix sets to use if needed
if isempty(p.SetsToUse)
    p.SetsToUse = 1 : size(basisstruct, 1);
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
    Actual_data_cell{i} = basisstruct(setind).(p.DataFieldName);
    
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

% Actual data
Actual_data = cell2mat(Actual_data_cell(:));

switch p.MODE
    case 'fit'
        switch p.Regularization
            case 'none'
                % Fit
                Model_coef = glmfit(BASISfun, Actual_data, 'normal');

                % Calculate model data
                Modeled_data = BASISfun * Model_coef(2:end) + Model_coef(1);
            case 'lasso'
                % Fit
                Model_coef = lassoglm(BASISfun, Actual_data, 'normal',...
                    'Standardize', p.Standardize, 'Lambda', p.Lambda, 'Alpha',...
                    p.Alpha);

                % Calculate model data
                Modeled_data = BASISfun * Model_coef;
        end
    case 'test'
        % Grab coefficient
        Model_coef = p.Coef;
        
        switch p.Regularization
            case 'none'
                % Grab coefficient and calculate modeled data
                Modeled_data = BASISfun * Model_coef(2:end) + Model_coef(1);
            case 'lasso'
                % Grab coefficient and calculate modeled data
                Modeled_data = BASISfun * Model_coef;
        end
    case 'visualize'
        % Grab coefficient
        Model_coef = p.Coef;
        
        switch p.Regularization
            case 'none'
                % Grab coefficient and calculate modeled data
                Modeled_data = BASISfun * Model_coef(2:end) + Model_coef(1);
            case 'lasso'
                % Grab coefficient and calculate modeled data
                Modeled_data = BASISfun * Model_coef;
        end
end

% Calculate deviance explained
devex.all = devexp(Modeled_data, Actual_data);

% Plot if asked for
if p.PlotOrNot
    figure
    plot([Actual_data, Modeled_data]);
    legend({'Actual data', 'Modeled data'})
    title(p.MODE);
end

% Detailed deviance data if asked for
if p.detailedDevex
    
    % current basis index
    basis_ind_curr = 0;
    
    for eventind = 1 : length(basisfield_names)
        % Event name
        eventname_sbf = basisfield_names{eventind};
        eventname_nsbf = [eventname_sbf(1:end-3), 'nsbf'];
        
        % Number of basis funcitons (Just take it from the first one)
        nsbf = sum(basisstruct(1).(eventname_nsbf));
        
        % If any of the weights is not 0
        if any(Model_coef(basis_ind_curr + 1 :...
                basis_ind_curr + nsbf) ~= 0)
            % Reproduce coefficients and remove the current ones
            Model_coef_tmp = Model_coef;
            Model_coef_tmp(basis_ind_curr + 1 :...
                basis_ind_curr + nsbf) = 0;

            devex.(eventname_sbf) = devex.all - ...
                devexp(BASISfun * Model_coef_tmp, Actual_data);
        else
            devex.(eventname_sbf) = 0;
        end

        % Propogate index
        basis_ind_curr = basis_ind_curr + nsbf;

    end
end

end

