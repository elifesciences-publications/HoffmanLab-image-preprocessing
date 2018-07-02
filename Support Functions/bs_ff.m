function imgo = bs_ff(imgo,varargin)
% Background subtract and/or flatfield the images. If background image is
% included then it is subtracted from the image. Additionally, the maximum
% of the histogram is subtracted. Alternatively subtracts the mode of
% images if no background images are supplied

%--------------------------------------------------------------------------

% Created 9/5 by Katheryn Rothenberg
% Updated 9/12 by Wes Maloney - Translated original body of function
% Updated 9/12 by Katheryn Rothenberg - Logical indexing vs find function

%--------------------------------------------------------------------------

%INPUTS:
% imgo - the image to be processed (REQUIRED)
% bavg - the background image to subtract (optional)

% params will be a structure containing a field for each of the following
% parameters:
% bit - specifies bit of the image
% nozero - turns off zeroing all images

%--------------------------------------------------------------------------

% setting up initial variables to match those in the IDL code
nps = nargin-1;
nozero = varargin{nps}.nozero;
bin = varargin{nps}.bin;

if nozero
    if nps == 2
        imgo=imgo-varargin{1};
    else
        data=mode(floor(imgo(imgo >= 0)./bin))*bin;
        mx=max(data);
        bkg=floor(data(data == mx));
        imgo=imgo-bkg(1);
    end
else
    if nps == 2
        imgo = (imgo-varargin{1}).*((imgo-varargin{1})>0);
    else
        data=mode(floor(imgo(imgo >= 0)./bin))*bin;
        mx=max(data);
        bkg=floor(data(data == mx));
        imgo = (imgo-bkg).*((imgo-bkg)>0);
    end
end


end