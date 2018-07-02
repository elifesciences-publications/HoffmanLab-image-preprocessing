function ResliceAndRegister(params,PreParams)

% Simplify some input parameters
refslice = params.refslice;

% Extracts optimally focused images and X-Y registers them
% Before moving onto radial correction
if isempty(file_search('reg1\w+.TIF',params.folder)) && not(strcmpi(params.beadname,'none'))
    mkdir(fullfile(params.folder,'ReslicedImages'));
    addpath(fullfile(params.folder,'ReslicedImages'));
    for i = 2:params.num_channels
        refname = file_search([params.beadname '\w+' params.ref_channel '.TIF'],fullfile(params.folder,'Stacks')); % reference image
        imgname = file_search([params.beadname '\w+' params.channels{i} '.TIF'],fullfile(params.folder,'Stacks')); % going to load stack of comparison images
        refNumStacks = length(refname);
        slice = PreParams.(params.channels{i}).InFocusSlice;
        xshift = PreParams.(params.channels{i}).xshift;
        yshift = PreParams.(params.channels{i}).yshift;
        for k = 1:refNumStacks % number of image stacks
            %Load images
            refinfo = imfinfo(refname{k});
            imginfo = imfinfo(imgname{k});
            refImage = single(imread(refname{k},refslice(k),'Info',refinfo)); % Extract "in focus" reference image
            img = single(imread(imgname{k},slice(k),'Info',imginfo)); % Extract appropriate other image
            % Register and crop to eliminate edge pixels
            sz = size(img);
            [y,x] = ndgrid(1:sz(1),1:sz(2));
            img = interp2(x,y,img,x-xshift,y-yshift); % register the other image to the FRET channel
            crop = [round(0.0246*sz(1)) round(0.0246*sz(1)) round(0.9509*sz(1)) round(0.9509*sz(1))]; % Crops 2048x2048 image to 1948x1948
            refImage = imcrop(refImage,crop); % Crop FRET image
            img = imcrop(img,crop); % Crop other image
            %Write to tif
            imwrite2tif(refImage,[],fullfile(params.folder,'ReslicedImages',['reg1_' refname{k}(1:end-4) '_slice' num2str(refslice(k)) '.TIF']),'uint16');
            imwrite2tif(img,[],fullfile(params.folder,'ReslicedImages',['reg1_' imgname{k}(1:end-4) '_slice' num2str(slice(k)) '.TIF']),'uint16');
        end
        clear fretImage otherImage
    end
end
end

