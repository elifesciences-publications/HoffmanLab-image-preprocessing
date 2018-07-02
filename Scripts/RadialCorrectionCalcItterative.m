function [PreParams,rd] = RadialCorrectionCalcItterative(params,PreParams,nameI1,nameI2,sfolder,n,c)
rehash

% Simplify inputs
folder = params.folder;
subfolder = fullfile(folder,sfolder);
channel = params.channels{c};

% Set up places to save data
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
    I1 = imread(fullfile(subfolder,nameI1{k}));
    I2 = imread(fullfile(subfolder,nameI2{k}));
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
        I1 = I1 - 3*mode(mode(I1));
        I2 = I2 - 3*mode(mode(I2));
    end
    
    % Perform Particle Tracking
    lambda = 1; %length scale of noise to be filtered out; typically 1 pixel
    if params.beaddiameter == 100
        w = 8;
    elseif params.beaddiameter == 500
        w = 10;
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
    
    % Force the origin to the original origin of the radial aberration
    xcenter(k) = PreParams.(params.channels{c}).xcenter;
    ycenter(k) = PreParams.(params.channels{c}).ycenter;
    
    % Save xcenter and ycenter to k_out
    k_out(k,1) = xcenter(k);
    k_out(k,2) = ycenter(k);
    clear I1 I2 rw1 rw2 rw3 rw4 crx1 crx2 cry1 cry2 crxy x y dmag dmags Lia
end

% Save out particle tracking data
pdata_out(1,:) = [];
save(fullfile(params.folder,'Parameters',[params.ref_channel '_' params.channels{c} '_visualize_radial_shifts' num2str(n) '.txt']),'-ascii','pdata_out');
clear pdata ucix lcix uciy lciy exrowsx exrowsy exrows

xcenter = mean(xcenter);
ycenter = mean(ycenter);

%% STEP 2: Shift x1, y1, x2, y2 to consensus center and
% calculate radial distortion parameters
for k = 1:length(nameI1)
    % Shift x1, y1, x2, y2 to consensus center of radial distortion
    x1{k} = x1{k}-xcenter;
    x2{k} = x2{k}-xcenter;
    y1{k} = y1{k}-ycenter;
    y2{k} = y2{k}-ycenter;
    
    % Convert to polar coordinates and normalize to R
    [~,r1] = cart2pol(x1{k},y1{k});
    [~,r2] = cart2pol(x2{k},y2{k});
    dx = abs(xcenter-imgc);
    dy = abs(ycenter-imgc);
    d = 2*max(dx,dy);
    R = sqrt(2)*(imgc+d);
    r1 = r1./R; % Normalize to maximum distance from center
    r2 = r2./R; % Normalize to maximum distance from center
    
    % Use non linear tool to find parameters for curve fit
    x_in = r2;
    y_in = r1-r2;
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
    saveas(gcf, fullfile(subfolder,['radial_' num2str(k)]), 'png')
    hold off
    close
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    k_out(k,3:5) = -kp;
    clear kp pdata
end
a1 = mean(k_out(:,3));
a2 = mean(k_out(:,4));
a3 = mean(k_out(:,5));


% Add original k_out dataset to original and save out
% full k_out1 dataset
k_out1_name = file_search(['\w+' channel '\w+rad_params' num2str(n-1) '.txt'],fullfile(params.folder,'Parameters'));
k_out1 = load(fullfile(params.folder,'Parameters',k_out1_name{1}));
k_out = double(k_out);

k_out1(:,3) = k_out1(:,3) + k_out(:,3); % sum a1
k_out1(:,4) = k_out1(:,4) + k_out(:,4); % sum a2
k_out1(:,5) = k_out1(:,5) + k_out(:,5); % sum a3

PreParams.(params.channels{c}).a1 = mean(k_out1(:,3));
PreParams.(params.channels{c}).a2 = mean(k_out1(:,4));
PreParams.(params.channels{c}).a3 = mean(k_out1(:,5));

save(fullfile(params.folder,'Parameters',[params.ref_channel '_' params.channels{c} '_rad_params' num2str(n) '.txt']),'k_out1','-ascii');

% For local use
rd = [xcenter,ycenter,a1,a2,a3];
clear k_out k_out1 r1 r2 r3 r4
end

