function [basis, nbasis] = GLMbasisphotom(inputvector, varargin)
% GLMbasisgen generates basis functions for photometry analysis
% [basis, nbasis] = GLMbasisphotom(inputvector, varargin)

% Parse inputs
p = inputParser;

% Sampling rate
addOptional(p, 'Fs', 1); % Default Fs

% Gaussian options
addOptional(p, 'UseGaussian', true); % Use gaussians
addOptional(p, 'GauSigma', 1);  % Sigma of the gaussians
addOptional(p, 'nSigma', 4); % Number of signals to use
addOptional(p, 'GauSpacing', 1); % Spacing of the gaussians
addOptional(p, 'nGauBefore', 1); % Number of gaussians to add before
addOptional(p, 'nGauAfter', 1); % Number of gaussians to add after


% Ramp options
addOptional(p, 'useRampUp', false); % Use ramp-ups
addOptional(p, 'RampUpJitterSpacing', 1); % Jitter spacing for ramp-ups
addOptional(p, 'RampUpJitterN', 1); % Number of jitters to do for ramp-ups 
                                    % (e.g., 1 means 1 left and 1 right);
addOptional(p, 'useRampDown', false); % Use ramp-downs
addOptional(p, 'RampDownJitterSpacing', 1); % Jitter spacing for ramp-downs
addOptional(p, 'RampDownJitterN', 1);   % Number of jitters to do for ramp-
                                        % downs (e.g., 1 means 1 left and
                                        % 1 right);
                                        
% Copy options
addOptional(p, 'useCopy', false); % Use copies
addOptional(p, 'CopyJitterSpacing', 1); % Jitter spacing for copies
addOptional(p, 'CopyJitterN', 1); % Number of jitters to do for copies
                                    % (e.g., 1 means 1 left and 1 right);

% Step-function options
addOptional(p, 'useStep', false); % Use steps
addOptional(p, 'EventToStep', 'first'); % Which event to step
addOptional(p, 'StepWhen', 'onset'); % Step on onset or offset
addOptional(p, 'StepJitterSpacing', 1); % Jitter spacing for steps
addOptional(p, 'StepJitterN', 1); % Number of jitters to do for steps
                                    % (e.g., 1 means 1 left and 1 right);

                                    
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% Initialize nbasis
nbasis = zeros(5,1); % Gaussian, ramp up, ramp down, copies, steps

% Length
L = length(inputvector);

% Chains of events
E_chains = chainfinder(inputvector > 0);
n_Events = size(E_chains, 1);
startinds = E_chains(:,1);
endinds = E_chains(:, 1) + E_chains(:,2) - 1;
lengths = E_chains(:, 2);

%% Gaussian
if p.UseGaussian
        
    % Number of gaussians within each event
    E_GauN = ceil(E_chains(:,2) / (p.GauSpacing * p.Fs)) + 1;
    E_GauN_max = max(E_GauN);
    
    % Generate Gaussian kernel
    ker_Gau = normpdf(-p.nSigma: 1/(p.GauSigma * p.Fs): p.nSigma);
    
    % Initialize basis function (as delta functions)
    basis_Gau = zeros(L, E_GauN_max + p.nGauBefore + p.nGauAfter);
    gau_ind = 0;
    
    % Pre-event gaussians
    for i = 1 : p.nGauBefore
        % Delta function
        gau_ind = gau_ind + 1;
        basis_Gau(startinds - i * (p.GauSpacing * p.Fs), gau_ind) = 1;
        
        % Convolve
        basis_Gau(:, gau_ind) = conv(basis_Gau(:, gau_ind), ker_Gau, 'same');
    end
    
    % During-event gaussians
    for i = 1 : E_GauN_max
        % Index
        gau_ind = gau_ind + 1;
        
        % Don't draw gaussians outside of the events
        E_GauN_curr = min(E_GauN, i);
        
        % Put in the delta functions
        basis_Gau(startinds + (E_GauN_curr - 1) * (p.GauSpacing * p.Fs), gau_ind) = 1;
        
        % Convolve
        basis_Gau(:, gau_ind) = conv(basis_Gau(:, gau_ind), ker_Gau, 'same');
    end
    
    % Post-event gaussians
    for i = 1 : p.nGauAfter
        % Delta function
        gau_ind = gau_ind + 1;
        basis_Gau(startinds + (E_GauN + i) * (p.GauSpacing * p.Fs), gau_ind) = 1;
        
        % Convolve
        basis_Gau(:, gau_ind) = conv(basis_Gau(:, gau_ind), ker_Gau, 'same');
    end
    
    % Gaussian basis numbers
    nbasis(1) = gau_ind;
    
    % Make sure that the gaussians do not go over
    basis_Gau = datasplitter(basis_Gau, [1, L], 1);
else
    basis_Gau = [];
end
   

%% Ramp up
if p.useRampUp
    % Initialize ramp-ups
    RU_ind = 1;
    basis_RU = zeros(L, p.RampUpJitterN * 2 + 1);
    
    % Make the first ramp up
    for i = 1 : n_Events
        basis_RU(startinds(i):endinds(i), RU_ind) =...
            0 : 1/(lengths(i) - 1) : 1;
    end
    
    % Jiggle
    for i = 1 : p.RampUpJitterN
        % Jiggle left
        RU_ind = RU_ind + 1;
        basis_RU(:, RU_ind) =...
            [basis_RU(p.RampUpJitterSpacing * p.Fs * i + 1 : end, 1);...
            zeros(p.RampUpJitterSpacing * p.Fs * i, 1)];
        
        % Jiggle right
        RU_ind = RU_ind + 1;
        basis_RU(:, RU_ind) =...
            [zeros(p.RampUpJitterSpacing * p.Fs * i, 1);
            basis_RU(1 : (L - p.RampUpJitterSpacing * p.Fs * i), 1)];
    end
    
    % Ramp-up basis numbers
    nbasis(2) = RU_ind;

else
    basis_RU = [];

end

%% Ramp down
if p.useRampDown
    % Initialize ramp-downs
    RD_ind = 1;
    basis_RD = zeros(L, p.RampDownJitterN * 2 + 1);
    
    % Make the first ramp down
    for i = 1 : n_Events
        basis_RD(startinds(i):endinds(i), RD_ind) =...
            1 : -1/(lengths(i) - 1) : 0;
    end
    
    % Jiggle
    for i = 1 : p.RampDownJitterN
        % Jiggle left
        RD_ind = RD_ind + 1;
        basis_RD(:, RD_ind) =...
            [basis_RD(p.RampDownJitterSpacing * p.Fs * i + 1 : end, 1);...
            zeros(p.RampDownJitterSpacing * p.Fs * i, 1)];
        
        % Jiggle right
        RD_ind = RD_ind + 1;
        basis_RD(:, RD_ind) =...
            [zeros(p.RampDownJitterSpacing * p.Fs * i, 1);
            basis_RD(1 : (L - p.RampDownJitterSpacing * p.Fs * i), 1)];
    end
    
    % Ramp-down basis numbers
    nbasis(3) = RD_ind;
else
    basis_RD = [];
end

%% Copy
if p.useCopy
    % Initialize ramp-ups
    Cp_ind = 1;
    basis_Cp = zeros(L, p.CopyJitterN * 2 + 1);
    
    % Make the first copy
    basis_Cp(:, Cp_ind) = inputvector;
    
    
    % Jiggle
    for i = 1 : p.CopyJitterN
        % Jiggle left
        Cp_ind = Cp_ind + 1;
        basis_Cp(:, Cp_ind) =...
            [basis_Cp(p.CopyJitterSpacing * p.Fs * i + 1 : end, 1);...
            zeros(p.CopyJitterSpacing * p.Fs * i, 1)];
        
        % Jiggle right
        Cp_ind = Cp_ind + 1;
        basis_Cp(:, Cp_ind) =...
            [zeros(p.CopyJitterSpacing * p.Fs * i, 1);
            basis_Cp(1 : (L - p.CopyJitterSpacing * p.Fs * i), 1)];
    end
    
    % Copy basis numbers
    nbasis(4) = Cp_ind;
else
    basis_Cp = [];
end

%% Step
if p.useStep
    % Initialize ramp-ups
    St_ind = 1;
    basis_St = zeros(L, p.StepJitterN * 2 + 1);
    
    % Which event to step and when the step during event
    switch p.EventToStep
        case 'first'
            switch p.StepWhen
                case 'onset'
                    Steptime = startinds(1);
                case 'offset'
                    Steptime = endinds(1);
            end
        case 'last'
            switch p.StepWhen
                case 'onset'
                    Steptime = startinds(end);
                case 'offset'
                    Steptime = endinds(end);
            end
    end
    
    % Make first basis function
    basis_St(Steptime : L, St_ind) = 1;
    
    
    % Jiggle
    for i = 1 : p.StepJitterN
        % Jiggle left
        St_ind = St_ind + 1;
        basis_St(:, St_ind) =...
            [basis_St(p.StepJitterSpacing * p.Fs * i + 1 : end, 1);...
            ones(p.StepJitterSpacing * p.Fs * i, 1)];
        
        % Jiggle right
        St_ind = St_ind + 1;
        basis_St(:, St_ind) =...
            [zeros(p.StepJitterSpacing * p.Fs * i, 1);
            basis_St(1 : (L - p.StepJitterSpacing * p.Fs * i), 1)];
    end
    
    % Copy basis numbers
    nbasis(5) = St_ind;
else
    basis_St = [];
end

%% Together
% Put together all the basis functions
basis = [basis_Gau, basis_RU, basis_RD, basis_Cp, basis_St];
end