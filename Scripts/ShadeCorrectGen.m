function PreParams = ShadeCorrectGen(params,PreParams)
% Generate shade correct bnorm with corrected images
rehash
if isempty(file_search('bnorm\w+.TIF',params.folder))
    for i = 1:params.num_channels
        shade_correct_gen(['pre_\w+' params.channels{i} '.TIF'],params.folder)
        rehash
        bnorm_name = file_search(['bnorm\w+' params.channels{i}],fullfile(params.folder,'Shade'));
        bnorm = single(imread(bnorm_name{1}));
        PreParams.(params.channels{i}).shade = bnorm;
    end
else
    for i = 1:params.num_channels
        bnorm_name = file_search(['bnorm\w+' params.channels{i}],fullfile(params.folder,'Shade'));
        bnorm = single(imread(bnorm_name{1}));
        PreParams.(params.channels{i}).shade = bnorm;
    end
end

end

