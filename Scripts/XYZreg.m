function PreParams = XYZreg(params,PreParams)
%Performs 3D Image Registration using dftregistration.m

%%%% INPUTS %%%
% params: input parameters
% empty PreParams structure (to be filled in)

%%%% OUTPUTS %%%
% PreParams structure updated with the following parameters for each
% channel:
% x_shift
% y_shift
% reg_params1.txt

% Simplify some input parameters
nslices = params.nslices;
refslice = params.refslice;

%% 3D Image Registration
if isempty(file_search('\w+_reg_params1.txt',params.folder))
    %% Create folder to save images to
    mkdir(fullfile(params.folder,'XYZregistration'));
    mkdir(fullfile(params.folder,'Parameters'));
    addpath(genpath(params.folder));
    for i = 2:params.num_channels
        refname = file_search([params.beadname '\w+' params.ref_channel '.TIF'],fullfile(params.folder,'Stacks')); % reference image
        imgname = file_search([params.beadname '\w+' params.channels{i} '.TIF'],fullfile(params.folder,'Stacks')); % going to load stack of comparison images
        refNumStacks = length(refname);
        zdata_out = ones(1,8);
        for k = 1:refNumStacks % number of image stacks
            refinfo = imfinfo(refname{k});
            imginfo = imfinfo(imgname{k});
            refImage = single(imread(refname{k},refslice(k),'Info',refinfo)); % Extract "in focus" reference image
            refbkg = mean(quantile(refImage,0.98));
            disp(['Background for Reference Image' num2str(k)  ': ' num2str(refbkg)]);
            refImage = refImage - refbkg;
            refImage(refImage<0) = 0;
            refImage = fft2(refImage);
            NumImgs = length(imginfo);
            for j = 1:NumImgs % number of images in each stack
                img = single(imread(imgname{k},j,'Info',imginfo));
                bkg = mean(quantile(img,0.98));
                disp(['Background for ' params.channels{i} ' Image' num2str(k)  ', slice' num2str(j) ': ' num2str(bkg)]);
                img = img - bkg;
                img(img<0) = 0;
                img = fft2(img);
                [zdata(j,1:4),~] = dftregistration(refImage,img,100);
                zdata(j,5) = j; % Col5 = slice
                clear img
            end
            clear refImage refImageUsed refbkg bkg
            
            % Calculate optimal z-plane for single image stack
            zdata(:,6) = k; % Col6 = image stack
            x = zdata(:,5); % slice
            y = zdata(:,1); % RMSE
            sp = spline(x,y);
            [minval, minsite] = fnmin(sp);
            img_slices(k) = minsite;
            zdata(:,7) = (minsite-refslice(k))*params.stepsize; % Col7 = z offset (nm)
            
            % Col8 = location of local minimum RMSE
            % Need to know which slice could be used (if params.method =
            % 'local') in subsequent x-y shift calculations
            l_row = round(minsite);
            zdata(:,8) = 0;
            zdata(l_row,8) = 1;
            zdata_out = vertcat(zdata_out,zdata);
            
            %%%%%% FOR DEBUGGING: Plot to make sure spline worked
            hold on
            xx = 0:.25:nslices;
            yy = spline(x,y,xx);
            plot(x,y,'o',xx,yy);
            scatter(minsite,minval);
            xlabel('Image Slice');
            ylabel('RMSE From Ref Image');
            axis([0 nslices+1 0.1 1.15]);
            saveas(gcf, fullfile(params.folder,'XYZregistration',['Zopt_' params.channels{i} '_' num2str(k)]), 'png')
            hold off
            close
            %%%%%%
        end
        
        % Extract average best z-plane for the whole dataset
        img_slice = round(mean(zdata_out(:,7))./params.stepsize);
        img_slice = refslice + img_slice;
        PreParams.(params.channels{i}).InFocusSlice = img_slice;
        
        % Save out full_zdataset
        zdata_out(:,9) = 0;
        for k = 1:length(img_slice)
            rows = zdata_out(:,6)==k;
            g_rows = zdata_out(:,5)==img_slice(k);
            grows = rows&g_rows;
            zdata_out(grows,9)=1;
        end
        zdata_out(1,:) = [];
        zdata_out = double(zdata_out);
        save(fullfile(params.folder,'Parameters',[params.ref_channel '_' params.channels{i} '_reg_params1.txt']),'zdata_out','-ascii');
        clear newrows
        
        if strcmpi(params.method,'local')
            ref_col = 8;
        elseif strcmpi(params.method,'global')
            ref_col = 9;
        end
        
        % Average optimal x-shifts, and y-shifts for the specified z-plane
        % calculated above and save them to PreParams
        rows = find(zdata_out(:,ref_col)==1);
        PreParams.(params.channels{i}).xshift = mean(zdata_out(rows,4));
        PreParams.(params.channels{i}).yshift = mean(zdata_out(rows,3));
    end
else % Load txt file if x and y shifts were previously calculated
    if exist(fullfile(params.folder,'Parameters'),'dir')~=7
        mkdir(fullfile(params.folder,'Parameters'));
        error('Move reg_params1.txt and rad_params1.txt files files to "Parameters" folder');
    end
    addpath(fullfile(params.folder,'Parameters'));
    for i = 2:params.num_channels
        XYdataName = file_search(['\w+' params.channels{i} '\w+reg_params1.txt'],fullfile(params.folder,'Parameters'));
        XYdata = load(XYdataName{1});
        if strcmpi(params.method,'local')
            ref_col = 8;
        elseif strcmpi(params.method,'global')
            ref_col = 9;
        end
        rows = find(XYdata(:,ref_col)==1);
        PreParams.(params.channels{i}).xshift = mean(XYdata(rows,4));
        PreParams.(params.channels{i}).yshift = mean(XYdata(rows,3));
        PreParams.(params.channels{i}).InFocusSlice = refslice+round(mean(XYdata(rows,7))./params.stepsize);
    end
end
end

