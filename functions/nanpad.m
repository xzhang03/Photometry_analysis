function datacell = nanpad(datacell, l, truncate, dim)
% nanpad(inputcell, l, truncate, dim)
if nargin < 4
    if size(datacell{1},1) >= size(datacell{1},2)
        dim = 1;
    else
        dim = 2;
    end
    if nargin < 3
        truncate = false; % Default no truncate
    end
end

% Padding entries in a cell to vectors of the same length    
for i = 1 : length(datacell)
    % Current length
    lcurr = size(datacell{i}, dim);
    
    if lcurr > l
        if truncate
            if dim == 1
                datacell{i} = datacell{i}(1:l, :);
            elseif dim == 2
                datacell{i} = datacell{i}(:, 1:l);
            end
        end
    elseif lcurr < l
        if dim == 1
            % Pad dim 1
            w = size(datacell{i},2);
            datacell{i} = vertcat(datacell{i}, nan(l-lcurr,w));
        elseif dim == 2
            % Pad dim 2
            w = size(datacell{i},1);
            datacell{i} = horzcat(datacell{i}, nan(w, l-lcurr));
        end
    end
end

end