%% Read in info from Params File
addpath(genpath(fullfile(pwd,'Support Functions')));
folder = input('Enter the full path of the folder that contains the BT data: ','s');
params_file = file_search('BT_Param\w+.txt',folder);
fid = fopen(fullfile(folder,params_file{1}));
while ~feof(fid)
    aline = fgetl(fid);
    eval(aline)
end
fclose(fid);

%% Preprocess images using PreParams.mat file in GoogleDrive (Protocols -> Analysis Protocols -> FRET)
rehash
if isempty(file_search('pre_\w+',folder))
    preprocess(PreParams_file,folder)
end

%% Calculate Bleedthroughs
rehash

[abt,dbt] = fret_bledth([prefix donor_pre '\w+\d+\w+' Achannel '.TIF'],...
    [prefix donor_pre '\w+\d+\w+' Dchannel '.TIF'],...
    [prefix donor_pre '\w+\d+\w+' FRETchannel '.TIF'],...
    [prefix acceptor_pre '\w+\d+\w+' Achannel '.TIF'],...
    [prefix acceptor_pre '\w+\d+\w+' Dchannel '.TIF'],...
    [prefix acceptor_pre '\w+\d+\w+' FRETchannel '.TIF'],...
    param);