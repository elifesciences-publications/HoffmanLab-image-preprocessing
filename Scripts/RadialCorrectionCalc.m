function PreParams = RadialCorrectionCalc(params,PreParams)
% Calculates radial distortion parameters k and ex
rehash
if isempty(file_search('\w+rad_params1.txt',params.folder))
    mkdir(fullfile(params.folder,'RadialCorrection1'));
    addpath(genpath(params.folder));
    rehash
    for i = 2:params.num_channels
        nameI1 = file_search(['reg1\w+' params.ref_channel '\w+.TIF'],fullfile(params.folder,'ReslicedImages'));
        nameI2 = file_search(['reg1\w+' params.channels{i} '\w+.TIF'],fullfile(params.folder,'ReslicedImages'));
        pdata_out = ones(1,5);
        k_out = zeros([length(nameI1),5]);
        xcenter = zeros([length(nameI1),1]);
        ycenter = zeros([length(nameI1),1]);
        x1 = cell([1,length(nameI1)]);
        x2 = cell([1,length(nameI1)]);
        y1 = cell([1,length(nameI1)]);
        y2 = cell([1,length(nameI1)]);
        
        %% STEP 1: Find a consensus centroid of the radial distortion
        for k = 1:length(nameI1)
            % Load raw images
            I1 = imread(nameI1{k});
            I2 = imread(nameI2{k});
            [sizeimg,~] = size(I1);
            imgc = sizeimg./2;
            
            % Background subtract images before particle tracking
            if params.beaddiameter == 100 && strcmpi(params.beadname,'TSbeads')
                I1 = I1 - 1.5*mode(mode(I1));
                I2 = I2 - 2*mode(mode(I2));
                for h = 1:20
                    I1 = imnoise(I1,'gaussian',0.000001,0.00000002);
                    I2 = imnoise(I2,'gaussian',0.000001,0.00000002);
                end
            else
%                 I1 = I1 - 3*mode(mode(I1));
%                 I2 = I2 - 3*mode(mode(I2));
                I1(I1<3*mode(mode(I1)))=0;
                I2(I2<3*mode(mode(I2)))=0;
            end
            
            % Perform Particle Tracking
            lambda = 1; %length scale of noise to be filtered out; typically 1 pixel
            if params.beaddiameter == 100
                w = 8;
            elseif params.beaddiameter == 500
                w = 12;
            end
            f1 = feature2D(I1,lambda,w);
            f2 = feature2D(I2,lambda,w);
            f1(:,6) = 1;
            f2(:,6) = 2;
            f1(:,7) = 1;
            f2(:,7) = 2;
            out = vertcat(f1,f2);
            
            [lub] = trackmem(out,5,2,2,0);
            x1{k} = lub(1:2:end,1);
            y1{k} = lub(1:2:end,2);
            x2{k} = lub(2:2:end,1);
            y2{k} = lub(2:2:end,2);
            
                        %%%%%%%%%%%% FOR DEBUGGING: Visualize Particles %%%%%%%%%%%%
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        figure('Position',[50 250 1800 550])
                        subplot(1,3,1)
                        imagesc(I1)
                        hold on
                        scatter(x1{k},y1{k},'wx')
                        title('Reference Channel');
                        subplot(1,3,2)
                        imagesc(I2)
                        hold on
                        scatter(x2{k},y2{k},'wx');
                        title('Other Channel');
                        subplot(1,3,3)
                        imagesc(zeros(1948));
                        hold on
                        scatter(x1{k},y1{k},'kx')
                        scatter(x2{k},y2{k},'bo')
                        legend({'Ref','Other'});
                        title('Visualize Shifts')
                        close
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Save x and y shifts data to text file
            pdata = zeros([length(x1{k}),5]);
            pdata(:,1) = x1{k};
            pdata(:,2) = y1{k};
            pdata(:,3) = sqrt((x1{k}-x2{k}).^2+(y1{k}-y2{k}).^2); % distance formula
            pdata(:,4) = 0;
            rw1 = x1{k}>x2{k} & y1{k}>y2{k}; % quadrant 1
            rw2 = x1{k}>x2{k} & y1{k}<y2{k}; % quadrant 2
            rw3 = x1{k}<x2{k} & y1{k}>y2{k}; % quadrant 3
            rw4 = x1{k}<x2{k} & y1{k}<y2{k}; % quadrant 4
            pdata(rw1,4)=1;
            pdata(rw2,4)=2;
            pdata(rw3,4)=3;
            pdata(rw4,4)=4;
            pdata(:,5) = k;
            
            pdata_out = vertcat(pdata_out,pdata);
            
            %%%%%% FOR DEBUGGING: Make sure particle tracker isn't %%%%%%%
            %%%%%% favoring particles at the center or edges of image %%%%
            figure
            subplot(2,2,1)
            hist(mod(x1{k},1));
            title('x1');
            subplot(2,2,2)
            hist(mod(x2{k},1));
            title('x2');
            subplot(2,2,3)
            hist(mod(y1{k},1));
            title('y1');
            subplot(2,2,4)
            hist(mod(y2{k},1));
            title('y2');
            saveas(gcf, fullfile(params.folder,'RadialCorrection1',['mod_' params.channels{i} '_' num2str(k)]), 'png')
            close
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Set or measure the origin of the radial aberration
            if strcmpi(params.radial_center,'centered') % SET to center
                xcenter(k) = PreParams.(params.channels{1}).xcenter;
                ycenter(k) = PreParams.(params.channels{1}).ycenter;
            elseif strcmpi(params.radial_center,'offcenter') % MEASURE the origin of the radial aberration
                cropedge = 400;
                crx1 = pdata(:,1)>cropedge;
                crx2 = pdata(:,1)<sizeimg-cropedge;
                cry1 = pdata(:,2)>cropedge;
                cry2 = pdata(:,2)<sizeimg-cropedge;
                crxy = crx1 & crx2 & cry1 & cry2;
                x = pdata(crxy,1);
                y = pdata(crxy,2);
                dmag = pdata(crxy,3);
                dmags = sort(dmag);
                [Lia,~] = ismember(dmag,dmags(1:5));
                
                
                %%%%%%%%%% FOR DEBUGGING: Visualize minima %%%%%%%%%%%%%%
                scatter(x(Lia),sizeimg-y(Lia),'MarkerEdgeColor',[0 0 1],'Marker','o')
                hold on
                [Lia,~] = ismember(dmag,dmags(6:10));
                scatter(x(Lia),sizeimg-y(Lia),'MarkerEdgeColor',[0 0.75 0],'Marker','o')
                [Lia,~] = ismember(dmag,dmags(11:15));
                scatter(x(Lia),sizeimg-y(Lia),'MarkerEdgeColor',[1 0.5 0.25],'Marker','o')
                [Lia,~] = ismember(dmag,dmags(16:20));
                scatter(x(Lia),sizeimg-y(Lia),'MarkerEdgeColor',[1 0 0],'Marker','o')
                legend({'1 thru 5','6 thru 10','11 thru 15','16 thru 20'});
                axis([0 sizeimg 0 sizeimg]);
                saveas(gcf, fullfile(params.folder,'RadialCorrection1',['center_of_RD_' params.channels{i} '_' num2str(k)]), 'png')
                close
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                
                [Lia,~] = ismember(dmag,dmags(1:5));
                xcenter(k) = mean(x(Lia));
                ycenter(k) = mean(y(Lia));
            end
            % Save xcenter and ycenter to k_out
            k_out(k,1) = xcenter(k);
            k_out(k,2) = ycenter(k);
            clear I1 I2 rw1 rw2 rw3 rw4 crx1 crx2 cry1 cry2 crxy x y dmag dmags Lia
        end
        
        
        
        
        % Exclude outliers in xcenter and ycenter calculations
        ucix = mean(xcenter)+2*std(xcenter);
        lcix = mean(xcenter)-2*std(xcenter);
        uciy = mean(ycenter)+2*std(ycenter);
        lciy = mean(ycenter)-2*std(ycenter);
        exrowsx = xcenter>ucix | xcenter<lcix;
        exrowsy = ycenter>uciy | ycenter<lciy;
        exrows = exrowsx & exrowsy;
        if ~isempty(nonzeros(exrows))
            xcenter(exrows) = [];
            ycenter(exrows) = [];
            k_out(exrows,1:2) = NaN;
            disp([num2str(length(nonzeros(exrows))) ' outlier images detected in estimating origin of radial distortion!']);
        end
        
        
        % Save average consensus xcenter and ycenter to PreParams
        PreParams.(params.channels{i}).xcenter = round(mean(xcenter));
        PreParams.(params.channels{i}).ycenter = round(mean(ycenter));
        
        % Save out particle tracking data
        pdata_out(1,:) = [];
        save(fullfile(params.folder,'Parameters',[params.ref_channel '_' params.channels{i} '_visualize_radial_shifts1.txt']),'-ascii','pdata_out');
        clear pdata ucix lcix uciy lciy exrowsx exrowsy exrows
        
        
        
        
        
        %% STEP 2: Shift x1, y1, x2, y3 to consensus center and
        % calculate radial distortion parameters
        for k = 1:length(nameI1)
            % Shift x1, y1, x2, y2 to consensus center of radial distortion
            x1{k} = x1{k}-PreParams.(params.channels{i}).xcenter;
            x2{k} = x2{k}-PreParams.(params.channels{i}).xcenter;
            y1{k} = y1{k}-PreParams.(params.channels{i}).ycenter;
            y2{k} = y2{k}-PreParams.(params.channels{i}).ycenter;
            
            % Convert to polar coordinates and normalize to R
            [~,r1] = cart2pol(x1{k},y1{k});
            [~,r2] = cart2pol(x2{k},y2{k});
            dx = abs(PreParams.(params.channels{i}).xcenter-imgc);
            dy = abs(PreParams.(params.channels{i}).ycenter-imgc);
            d = 2*max(dx,dy);
            R = sqrt(2)*(imgc+d);
            %             R = sqrt(2)*imgc; % distance from center of image to corner in final image that will be corrected with padded zeros
            r1 = r1./R; % Normalize to maximum distance from center
            r2 = r2./R; % Normalize to maximum distance from center
            
            %             % Optional exclusion of corner outliers
            %             w = find(r1>0.8);
            %             r1(w)=[];
            %             r2(w)=[];
            
            %             %%%%% FOR DEBUGGING: Scatter plot to fit curves to where %%%%%
            %             %%%%% y = s-x = TVFRET location - FWCy5 location (r1-r2) %%%%%
            %             %%%%% x = r = location of distorted FWCy5 channel (r2) %%%%%%%
            %             scatter(r2,(r1-r2));
            %             axis([0 0.8 -.002 0.002]);
            %             xlabel('Particle Radial Position (normalized)');
            %             ylabel('Relative Particle Position (R_{REFERENCE} - R_{OTHER})');
            %             saveas(gcf, fullfile(params.folder,'RadialCorrection1',['points_' params.channels{i} '_' num2str(k)]), 'png')
            %             close
            %             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Use non linear tool to find parameters for curve fit
            x_in = r2;
            y_in = r1-r2;
            %             F = @(k,r)k(1).*r.^k(2); %Equation used to radially correct images, fittype = 5
            %             k0 = [1 1];
            F = @(k,r)k(1).*r.^1+k(2).*r.^2+k(3).*r.^3; % 3rd order polynomial
            k0 = [1 1 1];
            [kp,~,~,~,~] = lsqcurvefit(F,k0,x_in,y_in); % use different value for k
            
            %%%% FOR DEBUGGING: Visualize radial correction curve fit %%%%
            scatter(x_in,y_in);
            hold on
            x_in = sort(x_in);
            plot(x_in,F(kp,x_in),'LineWidth',1.5,'Color','k');
            axis([0 1 -.002 0.002]);
            xlabel('Particle Radial Position (normalized)');
            ylabel('Relative Particle Position (R_{REFERENCE} - R_{OTHER})');
            legend({'Data','Fit'});
            saveas(gcf, fullfile(params.folder,'RadialCorrection1',['radial_' params.channels{i} '_' num2str(k)]), 'png')
            hold off
            close
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            k_out(k,3:5) = -kp;
            clear kp pdata
        end
        PreParams.(params.channels{i}).a1 = mean(k_out(:,3));
        PreParams.(params.channels{i}).a2 = mean(k_out(:,4));
        PreParams.(params.channels{i}).a3 = mean(k_out(:,5));
        save(fullfile(params.folder,'Parameters',[params.ref_channel '_' params.channels{i} '_rad_params1.txt']),'-ascii','k_out');
        
        clear k_out r1 r2 r3 r4
    end
else % Load txt file if prefactor params were previously calculated
    if exist(fullfile(params.folder,'Parameters'),'dir')~=7
        mkdir(fullfile(params.folder,'Parameters'));
        error('Move reg_params.txt and rad_params.txt files to "Parameters" folder');
    end
    addpath(fullfile(params.folder,'Parameters'));
    for i = 2:params.num_channels
        RADdataName = file_search(['\w+' params.channels{i} '\w+rad_params1.txt'],fullfile(params.folder,'Parameters'));
        RADdata = load(RADdataName{1});
        PreParams.(params.channels{i}).xcenter = round(nanmean(RADdata(:,1)));
        PreParams.(params.channels{i}).ycenter = round(nanmean(RADdata(:,2)));
        PreParams.(params.channels{i}).a1 = mean(RADdata(:,3));
        PreParams.(params.channels{i}).a2 = mean(RADdata(:,4));
        PreParams.(params.channels{i}).a3 = mean(RADdata(:,5));
    end
end

end

