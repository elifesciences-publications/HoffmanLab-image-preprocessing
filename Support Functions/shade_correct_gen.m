function shade_correct_gen(bkgexp,folder)

% shading corrections
% sample/normbackground
% must do for each channel - donor only, acceptor only, experimental images

% Inputs:
% bkgexp - regular expression for the background (shading correction)
%   images
% sampexp - regular expression for the sample images to be corrected
% folder - folder containing files

% Outputs:
% updated image files

bfiles = file_search(bkgexp,folder);
a = imread(bfiles{1});
[r,c] = size(a);
bstack = zeros(r,c,length(bfiles));
means = zeros(1,length(bfiles));
for i = 1:length(bfiles)
    add_img = double(imread(bfiles{i}));
    bstack(:,:,i) = add_img;
    means(i) = nanmean(add_img(:));
end

% normalize to mean intensity
totmean = nanmean(means);
dmean = means - totmean;
for i = 1:length(bfiles)
    bstack(:,:,i) = bstack(:,:,i)-dmean(i);
end

% take median of image stack
bmed = nanmedian(bstack,3);
bmedf = nanmedfilt2(bmed,[9 9]); % increase to 11, 13, 15 to get smoother bnorm images
bmedff = imgaussfilt(bmedf,9); % increase to 11, 13, 15 to get smoother bnorm images
bmedffnorm = bmedff./max(max(bmedff));
imwrite2tif(bmedffnorm,[],fullfile(folder,'Shade',['bnorm_' bfiles{1}]),'single');

end