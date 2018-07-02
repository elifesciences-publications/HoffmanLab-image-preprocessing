function PreParams = InitializePreParams(params)
% Function designed to preallocate space for PreParams

for i = 1:length(params.channels)
    PreParams.(params.channels{i}).xshift = [];
    PreParams.(params.channels{i}).yshift = [];
    PreParams.(params.channels{i}).InFocusSlice = [];
    PreParams.(params.channels{i}).xcenter = [];
    PreParams.(params.channels{i}).ycenter = [];
    PreParams.(params.channels{i}).a1 = [];
    PreParams.(params.channels{i}).a2 = [];
    PreParams.(params.channels{i}).a3 = [];
    PreParams.(params.channels{i}).dark = [];
    PreParams.(params.channels{i}).shade = [];
end

% Preallocate reference channel x, y, z, k, ex, xcenter, ycenter parameters
PreParams.(params.channels{1}).xshift = 0;
PreParams.(params.channels{1}).yshift = 0;
PreParams.(params.channels{1}).InFocusSlice = round((params.nslices+1)/2); % should be img 11 for a 21 images stack
PreParams.(params.channels{1}).xcenter = 1948/2;
PreParams.(params.channels{1}).ycenter = 1948/2;
PreParams.(params.channels{1}).a1 = 0;
PreParams.(params.channels{1}).a2 = 0;
PreParams.(params.channels{1}).a3 = 0;
end

