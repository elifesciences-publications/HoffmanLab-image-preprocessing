function I = asympad(img,dx,dy,sizeimg)
% Pads an image with zeros in order to shift the centroid of the image in x
% and y directions +dx and +dy pixels, respectively.

if dx==0 && dy==0
    I = img;
elseif abs(dx) > abs(dy)
    if dx>0
        padx1 = zeros([sizeimg,2*abs(dx)]);
        pady1 = zeros([abs(dx)+dy,sizeimg+2*abs(dx)]);
        pady2 = zeros([abs(dx)-dy,sizeimg+2*abs(dx)]);
        I = horzcat(padx1,img);
        I = vertcat(pady1,I,pady2);
    else
        padx2 = zeros([sizeimg,2*abs(dx)]);
        pady1 = zeros([abs(dx)+dy,sizeimg+2*abs(dx)]);
        pady2 = zeros([abs(dx)-dy,sizeimg+2*abs(dx)]);
        I = horzcat(img,padx2);
        I = vertcat(pady1,I,pady2);
    end
else
    if dy>0
        pady1 = zeros([2*abs(dy),sizeimg]);
        padx1 = zeros([sizeimg+2*abs(dy),abs(dy)+dx]);
        padx2 = zeros([sizeimg+2*abs(dy),abs(dy)-dx]);
        I = vertcat(pady1,img);
        I = horzcat(padx1,I,padx2);
    else
        pady2 = zeros([2*abs(dy),sizeimg]);
        padx1 = zeros([sizeimg+2*abs(dy),abs(dy)+dx]);
        padx2 = zeros([sizeimg+2*abs(dy),abs(dy)-dx]);
        I = vertcat(img,pady2);
        I = horzcat(padx1,I,padx2);
    end
end
end

