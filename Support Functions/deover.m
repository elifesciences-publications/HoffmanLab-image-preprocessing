function [a,b,c] = deover(a,b,c,bit)
% Identifies over-exposed pixels. If any of the images has an over-exposed
% pixel, the pixel is set to -1 in all images (will be removed in bs_ff).
% This is done to avoid confusion with pixels that may actually be zero.

oc = 2^bit-1;
w = find( a >= oc | b >=oc | c >=oc);
if min(w)>=0
    a(w) = -1;
    b(w) = -1;
    c(w) = -1;
end

end