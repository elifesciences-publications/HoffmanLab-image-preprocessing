% function CorrectShade(params,xshift,yshift,k_param,ex_param,xcenter_param,ycenter_param,dark_mean)
function ShadeCorrect(params,PreParams)
% Load shade images and correct them like the other images thusfar
rehash

if isempty(file_search('pre_shade\w+.TIF',params.folder)) && isempty(file_search('bnorm\w+.TIF',params.folder))
    if exist(fullfile(params.folder,'Shade'),'dir')~=7
        mkdir(fullfile(params.folder,'Shade'));
        error('Move shade or bnorm images to "Shade" folder');
    end
    addpath(fullfile(params.folder,'Shade'));
    if isempty(file_search('bnorm\w+.TIF',params.folder))
        for i = 1:params.num_channels
            % Simplify correction parameter names
            xshift = PreParams.(params.channels{i}).xshift;
            yshift = PreParams.(params.channels{i}).yshift;
            xcenter = PreParams.(params.channels{i}).xcenter;
            ycenter = PreParams.(params.channels{i}).ycenter;
            a1 = PreParams.(params.channels{i}).a1;
            a2 = PreParams.(params.channels{i}).a2;
            a3 = PreParams.(params.channels{i}).a3;
            dark_mean = PreParams.(params.channels{i}).dark;
            
            % Get shade image names
            shadeImgNames = file_search(['shade\w+' params.channels{i} '.TIF'],fullfile(params.folder,'Shade'));
            if isempty(shadeImgNames)
                shadeImgNames = file_search(['Shade\w+' params.channels{i} '.TIF'],fullfile(params.folder,'Shade'));
            end
            
            % Read in, correct, and save out new shade images
            for k = 1:length(shadeImgNames)
                img = single(imread(shadeImgNames{k}));
                img(img>=params.bead_int_thresh(i)) = NaN;
                img = img - dark_mean;
                
                
                % Register and crop to eliminate edge pixels
                sz = size(img);
                [y,x] = ndgrid(1:sz(1),1:sz(2));
                img = interp2(x,y,img,x-xshift,y-yshift); % register the other image to the FRET channel
                
                %Radial Correction (now assumes centroid of radial
                %distortion to be anywhere throughout the image)
                [sizeimg,~] = size(img);
                imgc = sizeimg./2;
                dx = imgc-(xcenter+50); % needs to shift +50 pix on each side since these aren't cropped yet
                dy = imgc-(ycenter+50); % needs to shift +50 pix on each side since these aren't cropped yet
                img = asympad(img,dx,dy,sizeimg);
                img = lensdistort(img,[],[],a1,a2,a3,'ftype',6,'bordertype','fit');
                img = asymcrop(img,dx,dy,sizeimg);
                
                % Crop after radial correction
                crop = [round(0.0246*sz(1)) round(0.0246*sz(1)) round(0.9509*sz(1)) round(0.9509*sz(1))]; % Crops 2048x2048 image to 1948x1948
                img = imcrop(img,crop); % Crop other image
                
                % Write out corrected shade image
                imwrite2tif(img,[],fullfile(params.folder,'Shade',['pre_' shadeImgNames{k}]),'single');
            end
        end
    end
end

end

