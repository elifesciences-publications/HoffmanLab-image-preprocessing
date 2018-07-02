function I = asymcrop(img,dx,dy)
% Pads an image with zeros in order to shift the centroid of the image in x
% and y directions +dx and +dy pixels, respectively.

if dx==0 && dy==0
    I = img;
elseif abs(dx) > abs(dy)
    if dx>0
        I = img;
        I(1:(abs(dx)+dy),:) = [];
        I((end-(abs(dx)-dy)+1):end,:) = [];
        I(:,1:2*abs(dx)) = [];
    else
        I = img;
        I(1:(abs(dx)+dy),:) = [];
        I((end-(abs(dx)-dy)+1):end,:) = [];
        I(:,(end-(2*abs(dx))+1):end) = [];
    end
else
    if dy>0
        I = img;
        I(:,1:(abs(dy)+dx)) = [];
        I(:,(end-(abs(dy)-dx)+1):end) = [];
        I(1:(2*abs(dy)),:) = [];
    else
        I = img;
        I(:,1:(abs(dy)+dx)) = [];
        I(:,(end-(abs(dy)-dx)+1):end) = [];
        I((end-(2*abs(dy))+1):end,:) = [];
    end
end
end

