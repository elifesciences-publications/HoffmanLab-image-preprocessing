function PreParams = ItterativeRegistration(params,PreParams,subfolder)
rehash
for n = 2:length(subfolder)
    if isempty(file_search(['\w+reg_params' num2str(n) '.txt'],params.folder))
        mkdir(fullfile(params.folder,subfolder{n}));
    end
end
addpath(genpath(params.folder));
for c = 2:length(params.channels)
    for n = 2:length(subfolder)
        if isempty(file_search(['\w+' params.channels{c} '\w+reg_params' num2str(n) '.txt'],params.folder))
            %% Calculate xshiftn and yshiftn
            refnames = file_search(['rad\w+' params.ref_channel '\w+.TIF'],fullfile(params.folder,subfolder{n-1}));
            imgnames = file_search(['rad\w+' params.channels{c} '\w+.TIF'],fullfile(params.folder,subfolder{n-1}));
            zdata = zeros(length(refnames),4);
            for i = 1:length(refnames)
                ref = single(imread(fullfile(params.folder,subfolder{n-1},refnames{i})));
                Rref = fft2(ref);
                img = single(imread(fullfile(params.folder,subfolder{n-1},imgnames{i})));
                Rimg = fft2(img);
                [zdata(i,1:4),~] = dftregistration(Rref,Rimg,100);
            end
            
            if strcmpi(params.method,'local')
                ref_col = 8;
            elseif strcmpi(params.method,'global')
                ref_col = 9;
            end
            
            % Add original zdataset to original and save out
            % full zdata_out1 dataset
            zdata_out1_name = file_search(['\w+' params.channels{c} '\w+reg_params' num2str(n-1) '.txt'],fullfile(params.folder,'Parameters'));
            zdata_out1 = load(fullfile(params.folder,'Parameters',zdata_out1_name{1}));
            rows = find(zdata_out1(:,ref_col)==1);
            for j = 1:length(rows)
                zdata_out1(rows(j),3) = zdata_out1(rows(j),3) + zdata(j,3);
                zdata_out1(rows(j),4) = zdata_out1(rows(j),4) + zdata(j,4);
            end
            save(fullfile(params.folder,'Parameters',[params.ref_channel '_' params.channels{c} '_reg_params' num2str(n) '.txt']),'zdata_out1','-ascii');
            
            % Save optimized x and y shifts to PreParams file
            PreParams.(params.channels{c}).xshift = mean(zdata_out1(rows,4));
            PreParams.(params.channels{c}).yshift = mean(zdata_out1(rows,3));
            
            % relative shifts to use for finer manipulations of images
            xshift_local = mean(zdata(:,4));
            yshift_local = mean(zdata(:,3));
            clear ref Rref img Rimg zdata rows zdata_out zdata_out1
            
            %% Register based on mean of latest xshift and yshift
            for i = 1:length(imgnames)
                img = single(imread(fullfile(params.folder,subfolder{n-1},imgnames{i})));
                ref = single(imread(fullfile(params.folder,subfolder{n-1},refnames{i})));
                sz = size(img);
                [y,x] = ndgrid(1:sz(1),1:sz(2));
                img_reg = interp2(x,y,img,x-xshift_local,y-yshift_local);
                img_reg = single(img_reg);
                imwrite2tif(ref,[],fullfile(params.folder,subfolder{n},['reg' num2str(n) refnames{i}(10:end)]),'uint16')
                imwrite2tif(img_reg,[],fullfile(params.folder,subfolder{n},['reg' num2str(n) imgnames{i}(10:end)]),'uint16')
            end
            clear img img_reg sz x y imgnames refnames
            
            %% Calculate radial correction
            refnames = file_search(['reg\w+' params.ref_channel '\w+.TIF'],fullfile(params.folder,subfolder{n}));
            imgnames = file_search(['reg\w+' params.channels{c} '\w+.TIF'],fullfile(params.folder,subfolder{n}));
            [PreParams,rdata] = RadialCorrectionCalcItterative(params,PreParams,refnames,imgnames,subfolder{n},n,c);
            
            %% Radially correct based on latest a1, a2, a3
            xcenter = mean(rdata(:,1));
            ycenter = mean(rdata(:,2));
            a1 = mean(rdata(:,3));
            a2 = mean(rdata(:,4));
            a3 = mean(rdata(:,5));
            for i = 1:length(refnames)
                %Load images
                img = single(imread(fullfile(params.folder,subfolder{n},imgnames{i})));
                ref = single(imread(fullfile(params.folder,subfolder{n},refnames{i})));
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
                imwrite2tif(ref,[],fullfile(params.folder,subfolder{n},['rad' num2str(n) '_' refnames{i}]),'uint16');
                imwrite2tif(img,[],fullfile(params.folder,subfolder{n},['rad' num2str(n) '_' imgnames{i}]),'uint16');
                clear ref img dx dy padx pady
            end
        else % Load txt file if prefactor params were previously calculated
            XYdataName = file_search(['\w+' params.channels{c} '\w+reg_params' num2str(n) '.txt'],fullfile(params.folder,'Parameters'));
            XYdata = load(XYdataName{1});
            if strcmpi(params.method,'local')
                ref_col = 8;
            elseif strcmpi(params.method,'global')
                ref_col = 9;
            end
            rows = find(XYdata(:,ref_col)==1);
            PreParams.(params.channels{c}).xshift = mean(XYdata(rows,4));
            PreParams.(params.channels{c}).yshift = mean(XYdata(rows,3));
%             PreParams.(params.channels{c}).InFocusSlice = refslice+round(mean(XYdata(rows,7))./params.stepsize);
            
            RADdataName = file_search(['\w+' params.channels{c} '\w+rad_params' num2str(n) '.txt'],fullfile(params.folder,'Parameters'));
            RADdata = load(RADdataName{1});
            PreParams.(params.channels{c}).xcenter = round(nanmean(RADdata(:,1)));
            PreParams.(params.channels{c}).ycenter = round(nanmean(RADdata(:,2)));
            PreParams.(params.channels{c}).a1 = mean(RADdata(:,3));
            PreParams.(params.channels{c}).a2 = mean(RADdata(:,4));
            PreParams.(params.channels{c}).a3 = mean(RADdata(:,5));
        end
    end
end
end