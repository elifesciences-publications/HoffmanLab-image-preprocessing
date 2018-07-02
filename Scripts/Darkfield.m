function [PreParams] = Darkfield(params,PreParams)
%Load dark images and calculate darkfield correction

rehash
if isempty(file_search('dark_mean\w+.TIF',params.folder))
    mkdir(fullfile(params.folder,'Darkfield'));
    addpath(fullfile(params.folder,'Darkfield'));
    for i = 1:params.num_channels
        darkName = file_search(['dark_\w+' params.channels{i} '.TIF'],params.folder);
        a = imread(darkName{1});
        [r,c] = size(a);
        dark = zeros(r,c);
        for k = 1:length(darkName)
            dark = dark + single(imread(darkName{k}));
        end
        dark_mean = dark./length(darkName);
        PreParams.(params.channels{i}).dark = dark_mean;
        imwrite2tif(dark_mean,[],fullfile(params.folder,'Darkfield',['dark_mean_' params.channels{i} '.TIF']),'uint16');
    end
else
    if exist(fullfile(params.folder,'Darkfield'),'dir')~=7
        mkdir(fullfile(params.folder,'Darkfield'));
        error('Move dark_mean images to "Darkfield" folder');
    end
    addpath(fullfile(params.folder,'Darkfield'));
    for i = 1:params.num_channels
        dark_mean_Name = file_search(['dark_mean\w+' params.channels{i} '.TIF'],fullfile(params.folder,'Darkfield'));
        dark_mean = single(imread(dark_mean_Name{1}));
        PreParams.(params.channels{i}).dark = dark_mean;
    end
end

end

