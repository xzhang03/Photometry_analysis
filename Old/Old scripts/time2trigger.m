%%
% signaldff = percentiledff(signal' + 4, 50, 30,10);

subtract = true;


signal = ch1_fixed_filtered - ch2_fixed_filtered + 4;
expfit = fit([10:length(signal)]',signal(10:end), 'exp1');
signal = signal - expfit(1:length(signal));

%%
mu = nanmean(signal);
lambda = nanstd(signal);
signalz = (signal - mu) / lambda;

% attach a nan tail
signalz_t = [signalz; nan(500, 1)];

%%

if size(A,2) > 1
    A = A';
    A = A(:);
end

A = reshape(A, 3, [])';
A = A(A(:,2) > 0, :);

% Fs = 2500;
delay = find(data(4,:) > 0.5,1) / Fs;
% delay = 0;
B = A;
Timestampfps = 30;
Pulserate;
Recordedfps = pulserate;
% Recordedfps = 14.77;
B(:,2:3) = A(:,2:3) * Timestampfps / Recordedfps + delay/60;

%%
defaultn = 20;
pretime = 10;
posttime = 10;
posttime_intro = 120;

% Tracking when female is in
Mat_female_in = nan((pretime + posttime) * freq + 1, 1);

% Tracking close exam
Mat_close_exam = nan((pretime + posttime) * freq + 1, defaultn);
ind_close_exam = 0;

% Tracking mounting
Mat_mount = nan((pretime + posttime) * freq + 1, defaultn);
ind_mount = 0;

% Tracking intromission
Mat_intro_long = nan((pretime + posttime_intro) * freq + 1, defaultn);
ind_intro = 0;

% Tracking transfer
Mat_transfer_long = nan((pretime + posttime_intro) * freq + 1, defaultn);
ind_transfer = 0;

% Tracking escaping
Mat_escape = nan((pretime + posttime) * freq + 1, defaultn);
ind_escape = 0;

% Tracking eating
Mat_eat = nan((pretime + posttime) * freq + 1, defaultn);
ind_eat = 0;

% Tracking lower body grroming
Mat_LB_grooming = nan((pretime + posttime) * freq + 1, defaultn);
ind_LB_grooming = 0;

% Tracking lower body grroming
Mat_fighting = nan((pretime + posttime) * freq + 1, defaultn);
ind_fighting = 0;


for i = 1 : size(B,1)
    startind = round(B(i,2) * 60 * freq - pretime * freq);
    endind = round(B(i,2) * 60 * freq + posttime * freq);
    endind_intro = round(B(i,3) * 60 * freq);
    
    if startind > 0 % Bandaid fix
        switch B(i,1)
            case -1
                Mat_female_in = signalz_t(startind:endind)';

            case 0.5
                ind_close_exam = ind_close_exam + 1;
                Mat_close_exam(:,ind_close_exam) = signalz_t(startind:endind);
            case 1
                ind_mount = ind_mount + 1;
                Mat_mount(:,ind_mount) = signalz_t(startind:endind);
            case 2
                ind_intro = ind_intro + 1;

                % Attach NaN tail if not long enough
                Mat_intro_long(:, ind_intro) = [signalz_t(startind:endind_intro);
                    nan((pretime + posttime_intro) * freq - endind_intro + startind,1)];

            case 3
                ind_transfer = ind_transfer + 1;
                Mat_transfer_long(:, ind_transfer) = [signalz_t(startind:endind_intro);
                    nan((pretime + posttime_intro) * freq - endind_intro + startind,1)];
            case 4
                ind_escape = ind_escape + 1;
                Mat_escape(:, ind_escape) = signalz_t(startind:endind);
            case 6
                ind_eat = ind_eat + 1;
                Mat_eat(:, ind_eat) = signalz_t(startind:endind);
            case 7
                ind_LB_grooming = ind_LB_grooming + 1;
                Mat_LB_grooming(:, ind_LB_grooming) = signalz_t(startind:endind);
            case 9
                ind_fighting = ind_fighting + 1;
                Mat_fighting(:, ind_fighting) = signalz_t(startind:endind);
        end
    end
end

Mat_close_exam = Mat_close_exam(:,1:ind_close_exam);
Mat_mount = Mat_mount(:, 1:ind_mount);

Mat_intro_long = Mat_intro_long(1 : find(sum(~isnan(Mat_intro_long),2), 1, 'last'), 1:ind_intro);
Mat_intro = Mat_intro_long(1:(pretime + posttime) * freq + 1, :);
Mat_escape = Mat_escape(:, 1:ind_escape);
Mat_transfer_long = Mat_transfer_long(:, 1:ind_transfer);
Mat_eat = Mat_eat(:, 1:ind_eat);
Mat_LB_grooming = Mat_LB_grooming(:, 1:ind_LB_grooming);
Mat_fighting = Mat_fighting(:, 1:ind_fighting);

Mat_intro_long_backalligned = Mat_intro_long;

for i = 1 : ind_intro
    naninds = isnan(Mat_intro_long(:,i));
    
    Mat_intro_long_backalligned(:,i) = [Mat_intro_long(naninds,i); Mat_intro_long(~naninds,i)];
    
end

%% Save
%
save(fullfile(filepath, [filename_output_fixed(1:end-4), '_triggered.mat']),...
    'Mat_close_exam', 'Mat_mount', 'Mat_intro', 'Mat_intro_long',...
    'Mat_intro_long_backalligned', 'Mat_escape', 'Mat_eat', 'Mat_LB_grooming',...
    'ind_close_exam', 'ind_mount', 'ind_intro', 'ind_escape', 'ind_eat', 'ind_LB_grooming',...
    'Mat_fighting', 'ind_fighting', 'ind_transfer', 'Mat_transfer_long',...
    'filepath', 'filename', 'A', 'B');
%}