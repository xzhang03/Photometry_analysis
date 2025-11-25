function y = logifun(x, x0, k, k2)
if nargin < 4
    y = 1./(1 + exp(-k*(x-x0)));
else
    y1 = 1./(1 + exp(-k*(x-x0)));
    y2 = 1./(1 + exp(-k2*(x-x0)));
    l = length(x);
    w1 = l : -1 : 1;
    w2 = 1 : 1 : l;
    if size(x,2)== 1
        w1 = w1';
        w2 = w2';
    end
    y = (y1 .* w1 + y2 .* w2) ./ (w1 + w2);
    
end

figure
plot(x,y)

end