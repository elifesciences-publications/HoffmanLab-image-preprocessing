function preprocess(parameters_file,folder,varargin)
% This function allows one to perform preprocessing steps that are required
% for any experiment. It will go through the potential imaging channels and
% will output perfectly overlayed images. The structure PreParams depends
% on your experimental conditions (magnification, temperature, live vs fixed,
% etc. and comes from the function PreParams_gen.m or from the pre-defined
% PreParams file that matches your experimental conditions.

% Brief overview of steps
% (1) X-Y Translational Registration
% (2) Radial Distortion Correction
% (3) Cropping to eliminate vignetting
% (4) Darkfield subtraction and shading correction (flatfielding)
% (5) Background subtraction

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Setup and Verify Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

i_p = inputParser;
i_p.addRequired('parameters_file',@(x)exist(x,'file') == 2);
i_p.addRequired('folder',@(x)exist(x,'dir') == 7);

i_p.addParamValue('status_messages',false,@(x)islogical(x)); %#ok<NVREPL>

i_p.parse(parameters_file,folder);

PreParams = load(parameters_file);

n = nargin;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Main Program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
count = 0;
for channel = fieldnames(PreParams)'
    count = count+1;
    channel = channel{1};  %#ok<FXSET>
    imgNames = file_search(['.*w\d+.*' channel '.*.TIF$'],folder);
    if ~(isempty(imgNames))
        xshift = PreParams.(channel).xshift;
        yshift = PreParams.(channel).yshift;
        xcenter = PreParams.(channel).xcenter;
        ycenter = PreParams.(channel).ycenter;
        a1 = PreParams.(channel).a1;
        a2 = PreParams.(channel).a2;
        a3 = PreParams.(channel).a3;
        dark = PreParams.(channel).dark;
        shade = PreParams.(channel).shade;
        
        if (i_p.Results.status_messages)
            fprintf('Starting on channel %s.\n',channel);
        end
        % Evan - moved these outside loop to implement parfor 5/24/17
        params.bin = 1;
        params.nozero = 0;
        for k = 1:length(imgNames)
            %Load images
            img = single(imread(fullfile(folder,imgNames{k})));
            %Darkfield subtraction before registration
            if all(size(img) == size(dark))
                
                % Darkfield correction
                img = img - dark;
                
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
                img = asymcrop(img,dx,dy);
                
                % Crop after radial correction
                crop = [round(0.0246*sz(1)) round(0.0246*sz(1)) round(0.9509*sz(1)) round(0.9509*sz(1))]; % Crops 2048x2048 image to 1948x1948
                img = imcrop(img,crop); % Crop other image
                
                %Avg shade corrections both previously registered, radially corrected and cropped
                img = img./shade;
                
                %Background subtraction
                if n ==2
                    img = bs_ff(img,params);
                else
                    img = bs_ff(img,varargin{1}(count),params);
                end
                
                %Write out as 32bit TIFs
                imwrite2tif(img,[],fullfile(folder,['pre_' imgNames{k}]),'single')
                if (i_p.Results.status_messages && any(k == round(linspace(1,length(imgNames),5))))
                    fprintf('Done with image %d/%d\n',k,length(imgNames));
                end
            end
        end
    end
end

end