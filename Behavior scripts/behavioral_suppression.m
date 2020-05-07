%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\behavior';

%% Loading cells
% Which data files to look at {mouse, date, run}
loadingcell = {'SZ05', 181225, 11; 'SZ05', 181225, 12; 'SZ06', 190106, 11;...
    'SZ06', 190106, 12; 'SZ04', 190107, 11; 'SZ38', 190208, 11; 'SZ38', 190208, 12;...
    'SZ38', 190210, 11; 'SZ38', 190210, 12; 'SZ04', 190131, 11; 'SZ04', 190131, 12;...
    'SZ07', 190119, 11; 'SZ07', 190119, 12; 'SZ07', 190119, 13; 'SZ28', 190208, 11;...
    'SZ29', 190208, 11};

% Make actual loading cell
loadingcell_full = mkloadingcell(loadingcell,defaultpath);
n = size(loadingcell,1);

% buffer zone in seconds
tbuffer = 5;
buffer = ones(tbuffer * 2 + 1, 1);

%% Loop through and find epochs
% Initialize data matrix (w/wo intromission, ratios,
datamat_esc = nan(n, 4);
datamat_dig = nan(n, 4);
datamat_feed = nan(n,4);

for i = 1 : n
    % Load behavior things
    A = load (fullfile(loadingcell_full{i,1}, loadingcell_full{i,3}), 'A');
    A = A.A;
    
    % Sort behaviors chronologically
    [~,border] = sort(A(:,2),'ascend');
    A = A(border,:);
    nevents = size(A,1);
    
    % Remove zero as first event start
    A(1,2) = max(A(1,2), 1/60);
    
    % Find mounts, intromissions, and transfers
    mts = A(:,1) == 1;
    its = A(:,1) == 2;
    tfs = A(:,1) == 3;
    
    % Determine the number of epochs
    nepochs = any(mts) + any(tfs) + 1;
    
    % Dividers
    if nepochs > 1
        div1 = A(find(mts,1,'first'), 2);
        div1 = round(div1 * 60);
        if nepochs > 2
            div2 = A(find(tfs,1,'last'), 3);
            div2 = round(div2 * 60);
        end
    end
    
    % Make event vectors
    vec_mate = event2vec(A, 1, 60) + event2vec(A, 2, 60) + ...
        event2vec(A, 3, 60) + event2vec(A, 7, 60) + event2vec(A, 0, 60);
    vec_esc = event2vec(A, 4, 60);
    vec_dig = event2vec(A, 5, 60);
    vec_feed = event2vec(A, 6, 60);
    
    % Apply buffers
    vec_mate_b = imdilate(vec_mate, buffer) > 0;
    vec_esc_b = (vec_esc - vec_mate_b) > 0;
    vec_dig_b = (vec_dig - vec_mate_b) > 0;
    vec_feed_b = (vec_feed - vec_mate_b) > 0;
    
    % Fill in intromission data
    datamat_esc(i,1) = any(its);
    datamat_dig(i,1) = any(its);
    datamat_feed(i,1) = any(its);
    
    % Process data depending on how many epochs
    switch nepochs
        case 1
            % Only 1 epoch
            datamat_esc(i,2) = sum(vec_esc_b) / sum(vec_mate_b == 0);
            datamat_dig(i,2) = sum(vec_dig_b) / sum(vec_mate_b == 0);
            datamat_feed(i,2) = sum(vec_feed_b) / sum(vec_mate_b == 0);
        case 2
            % 1st epoch
            datamat_esc(i,2) = sum(vec_esc_b(1:div1-1)) / ...
                sum(vec_mate_b(1:div1-1) == 0);
            datamat_dig(i,2) = sum(vec_dig_b(1:div1-1)) / ...
                sum(vec_mate_b(1:div1-1) == 0);
            datamat_feed(i,2) = sum(vec_feed_b(1:div1-1)) / ...
                sum(vec_mate_b(1:div1-1) == 0);
            
            % 2nd epoch
            datamat_esc(i,3) = sum(vec_esc_b(div1:end)) / ...
                sum(vec_mate_b(div1:end) == 0);
            datamat_dig(i,3) = sum(vec_dig_b(div1:end)) / ...
                sum(vec_mate_b(div1:end) == 0);
            datamat_feed(i,3) = sum(vec_feed_b(div1:end)) / ...
                sum(vec_mate_b(div1:end) == 0);
        case 3
            % 1st epoch
            datamat_esc(i,2) = sum(vec_esc_b(1:div1-1)) / ...
                sum(vec_mate_b(1:div1-1) == 0);
            datamat_dig(i,2) = sum(vec_dig_b(1:div1-1)) / ...
                sum(vec_mate_b(1:div1-1) == 0);
            datamat_feed(i,2) = sum(vec_feed_b(1:div1-1)) / ...
                sum(vec_mate_b(1:div1-1) == 0);
            
            % 2nd epoch
            datamat_esc(i,3) = sum(vec_esc_b(div1:div2)) / ...
                sum(vec_mate_b(div1:div2) == 0);
            datamat_dig(i,3) = sum(vec_dig_b(div1:div2)) / ...
                sum(vec_mate_b(div1:div2) == 0);
            datamat_feed(i,3) = sum(vec_feed_b(div1:div2)) / ...
                sum(vec_mate_b(div1:div2) == 0);
            
            % 3rd epoch
            datamat_esc(i,4) = sum(vec_esc_b(div2+1 : end)) / ...
                sum(vec_mate_b(div2+1 : end) == 0);
            datamat_dig(i,4) = sum(vec_dig_b(div2+1 : end)) / ...
                sum(vec_mate_b(div2+1 : end) == 0);
            datamat_feed(i,4) = sum(vec_feed_b(div2+1 : end)) / ...
                sum(vec_mate_b(div2+1 : end) == 0);
    end
end

