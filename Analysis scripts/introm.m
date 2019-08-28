%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Which data files to look at {mouse, date, run}
inputloadingcell = {'SZ129', 190707, 2; 'SZ132', 190720, 2;...
                    'SZ133', 190709, 2; 'SZ133', 190720, 2;...
                    'SZ133', 190720, 3};


%% Make data struct
[datastruct, n_series] = mkdatastruct(inputloadingcell, defaultpath);

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 5, 'smooth_window', 5, 'zscore_badframes', 1 : 10, 'First_point', 15, 'BlankTime', 20};
datastruct_pp = ppdatastruct(datastruct, varargin_pp);

%% GLM basis functions
% User variables 
GauSigma = 1; % in seconds
SpacingBasis = 1; % in seconds

% General inputs
varargin_GLMGeneral = {'Fs', [], 'UseGaussian', true, 'GauSigma', GauSigma,...
    'GauSpacing', SpacingBasis, 'nGauBefore', 3, 'nGauAfter', 3, 'useRampUp', false,...
    'useRampDown', false, 'useCopy', false, 'useStep', false};

% Introm inputs
varargin_GLMintro = {'Fs', [], 'UseGaussian', true, 'GauSigma', GauSigma,...
    'GauSpacing', SpacingBasis, 'nGauBefore', 3, 'nGauAfter', 3, 'useRampUp', true,...
    'RampUpJitterSpacing', SpacingBasis, 'RampUpJitterN', 3, ...
    'useRampDown', false, 'RampDownJitterSpacing', SpacingBasis,...
    'RampDownJitterN', 3, 'useCopy', false, 'CopyJitterSpacing',...
    SpacingBasis, 'CopyJitterN', 5, 'useStep', false};

% Transfer inputs
varargin_GLMtransfer = {'Fs', [], 'UseGaussian', true, 'GauSigma', GauSigma,...
    'GauSpacing', SpacingBasis, 'nGauBefore', 3, 'nGauAfter', 3, 'useRampUp', true,...
    'RampUpJitterSpacing', SpacingBasis, 'RampUpJitterN', 3, ...
    'useRampDown', true, 'RampDownJitterSpacing', SpacingBasis,...
    'RampDownJitterN', 3, 'useCopy', false, 'CopyJitterSpacing',...
    SpacingBasis, 'CopyJitterN', 3, 'useStep', true,...
    'EventToStep', 'last', 'StepWhen', 'offset', 'StepJitterSpacing',...
    SpacingBasis, 'StepJitterN', 3};

% All simple basis function inputs
varargin_simplebasis = {'varargin_GLMGeneral', varargin_GLMGeneral;...
    'varargin_GLMintro', varargin_GLMintro;...
    'varargin_GLMtransfer', varargin_GLMtransfer};

% IntroTransfer state input
varargin_State_IntroTransfer = {'Name', 'IntroTransfer', 'DynamicOnOffset', 'onset',...
    'WhichStaticEvent', 'last', 'StaticOnOffset', 'offset',...
    'useDynBeforeSta', true, 'useDynAfterSta', true};

% Formula for generating simple basis functions
basis_formula = {'FemInvest', ''; 'CloseExam', 'varargin_GLMGeneral'; ...
    'Mount', 'varargin_GLMGeneral'; 'Introm', 'varargin_GLMintro'; 'Transfer',...
    'varargin_GLMtransfer'; 'Escape', 'varargin_GLMGeneral'; 'Dig',...
    'varargin_GLMGeneral'; 'Feed', 'varargin_GLMGeneral'; 'LBgroom',...
    'varargin_GLMGeneral'; 'UBgroom', 'varargin_GLMGeneral';...
    'varargins', varargin_simplebasis};

% Formula for generating state basis functions
state_formula = {'Introm', 'Transfer', varargin_State_IntroTransfer};

% Make basis functions
basisstruct = GLMbasisbatch(datastruct_pp, 'photometry', basis_formula, state_formula);

% Formula for aligning basis functions
sync_formula = {'FemInvest', ''; 'CloseExam', 'alignfront'; 'Mount',...
    'alignfront'; 'Introm', 'alignback'; 'Transfer', 'alignfront';...
    'Escape', 'alignfront'; 'Dig', 'alignfront'; 'Feed', 'alignfront';...
    'LBgroom', 'alignfront'; 'UBgroom', 'alignfront'; 'IntroTransfer',...
    'alignback'};

% Align basis functions
basisstruct_sync = GLMbasissync(basisstruct, sync_formula);

%% Split up the dataset in to a training set and a testing set
% Trainig set matrix
tr_mat = [1 1 0 1 0; 0 1 1 1 1; 1 1 0 1 1; 1 1 1 0 0; 0 1 1 1 1];

% Testing set matrix
te_mat = 1 - tr_mat;

varargin_split = {'train_mat', tr_mat, 'test_mat', te_mat};
[basisstruct_train, basisstruct_test] = GLMbasissplit(basisstruct_sync, varargin_split);

%% GLM fitting and testing
% Regularizaiton method;
regmet = 'lasso';

% GLM fitting parameters
varargin_GLMfit = {'MODE', 'fit', 'PlotOrNot', true, 'SetsToUse', [],...
    'Regularization', regmet, 'Lambda', 0.1, 'Alpha', 0.01,...
    'Standardize', false};

% GLM fitting
disp('=============================================')
fprintf('GLM fitting...')
tic;
[Model_coef, Deviance_explained, ~, ~] =...
    GLMdophotom(basisstruct_train, varargin_GLMfit);
fprintf('Done.');
toc
disp(['Deviance explained (fitting): ', num2str(Deviance_explained)]);

% GLM testing parameters
varargin_GLMtest = {'MODE', 'test', 'PlotOrNot', true, 'SetsToUse', [],...
    'Coef', Model_coef, 'Regularization', regmet};

% GLM testing
fprintf('GLM testing...')
tic;
[~, Deviance_explained, ~, ~] =...
    GLMdophotom(basisstruct_test, varargin_GLMtest);
fprintf('Done.');
toc
disp(['Deviance explained (testing): ', num2str(Deviance_explained)]);

% GLM visrualize parameters
varargin_GLMvis = {'MODE', 'visualize', 'PlotOrNot', true, 'SetsToUse', 2,...
    'Coef', Model_coef, 'Regularization', regmet};
[~, ~, ~, ~] =...
    GLMdophotom(basisstruct_sync, varargin_GLMvis);
%% Make an intromission construct
%{
% Normalized length (in points)
norm_length = 40;

% Initialize
Intromstruct = struct('session', 0, 'data', 0, 'ln_data', 0,...
    'length', 0, 'order', 0, 'rorder', 0, 'Fs', 0);
Intromstruct = repmat(Intromstruct, [sum([datastruct_pp(:).nIntrom]), 1]);

% loop through and parse
ind = 0;
for i = 1 : n_series
    % Get behavior table
    bhv_tab_temp = chainfinder(datastruct_pp(i).Introm > 0.5);
    
    % Loop through each intromission
    for j = 1 : size(bhv_tab_temp, 1)
        % index
        ind = ind + 1;
        
        % Fill name
        Intromstruct(ind).session = i;
        
        % Fill Fs
        Intromstruct(ind).Fs = datastruct_pp(i).Fs;
        
        % Fill length
        Intromstruct(ind).length = bhv_tab_temp(j, 2);
        
        % Fill order
        Intromstruct(ind).order = j;
        
        % Fill reverse order
        Intromstruct(ind).rorder = datastruct_pp(i).nIntrom - j;
        
        % Fill data
        Intromstruct(ind).data = ...
            datastruct_pp(i).photometry(bhv_tab_temp(j, 1)...
            : (bhv_tab_temp(j, 1) + bhv_tab_temp(j, 2) - 1));
        
        % Fill length-normalized data
        % resampling factor
        rsfactor = norm_length / Intromstruct(ind).length;
        if rsfactor == 1
            Intromstruct(ind).ln_data = Intromstruct(ind).data;
        else
            Intromstruct(ind).ln_data = ...
                tcpBin(Intromstruct(ind).data, Intromstruct(ind).Fs,...
                Intromstruct(ind).Fs * rsfactor, 'mean', 1, true);
        end
    end
end
%}
