function [xr,yr] = spline_p_k(x,y)

% FIRST MAKE SURE THEY ARE ROW VECTORS
[r,c] = size(x);
if c ==1
    x = x';
end
[r,c] = size(y);
if c ==1
    y = y';
end

n = length(x);
if n ~= length(y)
    disp('X and Y must have same number of points')
end

dx = x - circshift(x,[0 1]);
dy = y - circshift(y,[0 1]);
dx(1) = 0;
dy(1) = 0;

t = sqrt(dx.^2 + dy.^2);
ni = n-1;

% Default interval = approx 8 points per interval...
interval = sum(t)./(8*ni);
r = ceil(t./interval);
nr = sum(r);

tt = zeros(1,nr);
j = 1;

for int = 1:ni
    il = int+1;
    nn = r(il);
    tt(j:j+nn-1) = t(il)./nn * [1:nn] + t(int);
    t(il) = t(il) + t(int);
    j = j + nn;
end
tt(nr) = t(int);

xr = spl_interp_k(t',x',spl_init_k(t,x)',tt')';
yr = spl_interp_k(t',y',spl_init_k(t,y)',tt')';
end