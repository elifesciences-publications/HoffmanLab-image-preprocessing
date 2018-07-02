function y2 = spl_init_k(x,y,varargin)

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
y2 = zeros(1,n);
u = zeros(1,n);

if nargin == 2
    y2(1) = 0;
    u(1) = 0;
else
    y2(1) = -0.5;
    u(1) = (3./(x(2)-x(1))) .* ((y(2)-y(1))./(x(2)-x(1)) - varargin{1});
end

psig_old = (x-circshift(x,[0 -1]))./(circshift(x,[0 1])-circshift(x,[0 -1]));
psig = psig_old;
for ii = 2:n-1
    psig(ii) = (x(ii)-x(ii-1))./(x(ii+1)-x(ii-1));
end

pu = ((circshift(y,[0 -1])-y)./(circshift(x,[0 -1])-x)-(y-circshift(y,[0 1]))./(x-circshift(x,[0 1])))./(circshift(x,[0 -1])-circshift(x,[0 1]));

for i = 2:n-1
    p = psig(i).*y2(i-1)+2;
    y2(i) = (psig(i)-1)./p;
    u(i) = (6.*pu(i)-psig(i).*u(i-1))./p;
end

if nargin == 2
    qn = 0;
    un = 0;
else
    qn = 0.5;
    dx = x(n)-x(n-1);
    un = (3./dx).*(varargin{2}-(y(n-1)-y(n-2))./dx);
end

y2(n) = (un-qn*u(n-1))./(qn*y2(n-1)+1);

for k = n-1:-1:1
    y2(k) = y2(k).*y2(k+1)+u(k);
end
end