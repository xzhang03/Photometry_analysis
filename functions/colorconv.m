function [ outputvec ] = colorconv( inputstring, alpha )
%colorconv converts a string of hex triplet (e.g. ed2224) to a 1x3 vector 
%of the color.
%   [ outputvec ] = colorconv( inputstring )

outputvec = zeros(1,3);

for i = 1:3

    outputvec(i) = hex2dec(inputstring(i*2-1:i*2))/255;
    
    outputvec(i) = 1 - (1 - outputvec(i)) * alpha;
end

end

