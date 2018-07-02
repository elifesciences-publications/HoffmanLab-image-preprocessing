function y = spl_interp_k(xa,ya,y2a,x)

[r,c] = size(xa);
if c ~=1
    xa = xa';
end
[r,c] = size(ya);
if c ~=1
    ya = ya';
end
[r,c] = size(x);
if c ~=1
    x = x';
end
[r,c] = size(y2a);
if c ~=1
    y2a = y2a';
end

n = length(xa);
[~, klo] = histc(x,xa);
klo(klo < 1) = 1;
klo(klo > (n-1)) = n-1;

khi = klo + 1;

% klo and khi now bracket the input value of x

if min(xa(khi)-xa(klo)) == 0
    disp('SPLINT - X inputs must be distinct')
end

h = xa(khi) - xa(klo);
a = (xa(khi)-x)./h;
b = (x-xa(klo))./h;

y = a.*ya(klo) + b.*ya(khi) + ((a.^3-a).*y2a(klo) + (b.^3-b).*y2a(khi)).*(h.^2)./6;