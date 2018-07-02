function RadialCorrect(params,PreParams)
% Radially correct already X-Y registered images
% Just to output images and make sure they are preprocessed correctly
rehash
if isempty(file_search('rad1_reg1\w+.TIF',params.folder)) && not(strcmpi(params.beadname,'none'))
    mkdir(fullfile(params.folder,'RadiallyCorrectedImages1'));
    addpath(fullfile(params.folder,'RadiallyCorrectedImages1'));
    rehash
    for i = 2:params.num_channels
        xcenter = PreParams.(params.channels{i}).xcenter;
        ycenter = PreParams.(params.channels{i}).ycenter;
        a1 = PreParams.(params.channels{i}).a1;
        a2 = PreParams.(params.channels{i}).a2;
        a3 = PreParams.(params.channels{i}).a3;
        
        refname = file_search(['reg1\w+beads\w+' params.ref_channel '\w+.TIF'],params.folder); % reference image
        imgname = file_search(['reg1\w+beads\w+' params.channels{i} '\w+.TIF'],params.folder); % going to load stack of comparison images
        refNumImgs = length(refname);
        for k = 1:refNumImgs % number of image stacks
            %Load images
            img = single(imread(imgname{k}));
            refImage = single(imread(refname{k}));
            [sizeimg,~] = size(img);
            imgc = sizeimg./2;
            
            % Pad each image asymmetrically to shift radial distortion
            % centroid to the center of the newly padded image
            dx = imgc-xcenter;
            dy = imgc-ycenter;
            img = asympad(img,dx,dy,sizeimg);
            
            % run lensdistort
            img = lensdistort(img,[],[],a1,a2,a3,'ftype',6,'bordertype','fit');
            
            % Crop back down asymmetrically to restore proper image size
            img = asymcrop(img,dx,dy,sizeimg);
            
            %Write to 32bit .TIF
            if i == 2 % only on round 1
                imwrite2tif(refImage,[],fullfile(params.folder,'RadiallyCorrectedImages1',['rad1_' refname{k}]),'uint16');
            end
            imwrite2tif(img,[],fullfile(params.folder,'RadiallyCorrectedImages1',['rad1_' imgname{k}]),'uint16');
            clear refImage img dx dy padx pady
        end
        clear xcenter ycenter a1 a2 a3
    end
end

end

