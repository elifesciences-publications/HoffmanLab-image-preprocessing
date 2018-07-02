%% Description
% Written by: Andy LaCroix, August 2013
% Modified by: Andy LaCroix 7/8/15
% Modified by: Andy LaCroix 10/25/17
%
% Wrapper script written to generate correction parameters (details below) for
% epifluorescence microscope based on images of fluorescent beads. For
% a detailed discussion of the methods presented below, go to:
%      LaCroix, Andrew S., et al. "Construction, imaging, and analysis of
%      FRET-based tension sensors in living cells." Methods in cell biology
%      125 (2015): 161-186.
%
%% Required sub-functions
%   Particle Tracking: feature2D.m, trackmem.m, (more sub-subfunctions in Particle Tracking Repository in Git)
%   Image Registration Measurement: dftregistration.m
%   Radial Distortion Correction: lensdistort.m
%   Shade Correction: shade_correct_gen.m
%   General: imwrite2tif.m, file_search.m
%
%% Inputs
%     folder      folder containing
%                 (1) image stacks ("Stacks" folder)   OR   previously measured parameters ("Parameters" folder)
%                 (2) darkfield images ("Darkfield" folder), and
%                 (3) shade images ("Shade" folder)
%
%     folder1     folder containing "Particle Tracking" Github repository
%                 functions (only required if registering stacks of bead
%                 images
%
%     channels    unique identifiers for each channel being registered
%                 (reference channel should be the first
%                 channel input). For each channel, we aquire three types
%                 of images that are used at different steps in the
%                 registration code:
%               (1) Multiple (at least nine) stacks of 21 images in
%                 each channel being registered (image 11 of reference
%                 channel is "in focus")
%               (2) Darkfield images (close all shutters on microscope,
%                 and take pictures in each channel). This will capture
%                 images of the thermal noise in the camera, it is
%                 important to take these images after the microscope is
%                 fully warmed up. These images will also highlight "hot"
%                 or "cold" pixels. Take at least 20 darkfield images.
%               (3) Shade images. Images of blank areas of your sample
%                 (containing no fluorescent beads). These images will
%                 capture differences in illumination intensity across
%                 images. These shading images vary channel-by-channel
%                 depending on the positioning of filters in filter wheels
%                 and/or cubes. Take at least 20 shade images.
%
%% Outputs
% PreParams    Matlab structure containing information unique to each imaging channel
%       PreParams.channels{i}.xshift    x-direction rigid transformation needed
%                                       to align channel to reference channel
%       PreParams.channels{i}.yshift    y-direction rigid transformation needed
%                                       to align channel to reference channel
%       PreParams.channels{i}.a1        Prefactor 1 in radial correction equation
%       PreParams.channels{i}.a2        Prefactor 2 in radial correction equation
%       PreParams.channels{i}.a3        Prefactor 3 in radial correction equation
%       PreParams.channels{i}.xcenter   Location of x centeroid of radial aberration
%       PreParams.channels{i}.ycenter   Location of y centroid of radial aberration
%       PreParams.channels{i}.dark      Darkfield image to subtract off every channel
%       PreParams.channels{i}.shade     Normalized shade image to correct uneven
%                                       illumination in each channel
%
% \w+reg_params.txt       file containing x-shift, y-shift, and proper focal
%                         plane (z-shift) data for each channel with respect
%                         to reference channel
%
% reg_slice_xxx.TIF       Extracted image slice from each image stack most
%                         "in focus", registered in the x-y plane based on
%                         calculated x_shift and y_shift
%
% \w+rad_params.txt       file containing radial distortion correction
%                         parameters (a1, a2, a3) for each channel with
%                         respect to the reference channel
%
% rad_reg_slice_xxx.TIF   radially corrected reg_slice_xxx.TIF images
%
% pre_shade_xxx.TIF       darkfield subtracted, registered, and radially
%                         corrected shade images
%
% bnorm_shade_xxx.TIF     median of shade image stack, median filtered,
%                         normalized to 1
%
%% Clean up workspace
clc;
clear;
close all;
addpath(genpath(fullfile(pwd,'Scripts')));
addpath(genpath(fullfile(pwd,'Support Functions')));
addpath(genpath(fullfile(pwd,'Particle Tracking')));

%% User Input Information
%%%%% ALL USERS %%%%%
params.beadname = 'YGbeads'; % Options:  'none'  'TSbeads'  'YGbeads'
params.channels = {'TVFRET','Teal'};
params.ref_channel = 'TVFRET'; % must match 1st channel in params.channels

%%%%% EXPERIENCED USERS %%%%%
params.bead_int_thresh = repmat(65000,[1,length(params.channels)]);
params.method = 'global'; % local (old) or global (newer better) methods to calculate x & y shifts at proper focal plane
params.radial_center = 'offcenter'; % centered (old) or offcenter (newer better) methods to determine the center of the radial distortion
params.nslices = 21; % must be odd number
params.stepsize = 100; % in nm (to convert steps to nm z-shifts)
params.beaddiameter = 500; % in nm
params.refslice = repmat((params.nslices+1)/2,[1,13]);

%%%%% ALWAYS ASK FOR THE PATH TO THE FOLDER TO BE ANALYZED %%%%%
params.folder = input('Type the full path to the folder that contains your "Darkfield", "Parameters", and "Shade" folders\n','s');
addpath(genpath(params.folder));

%%%%% OTHER AUTOMATED INPUT PARAMETERS %%%%%
params.num_channels = length(params.channels);

%% Set up PreParams structure that will eventually contain all registration information
PreParams = InitializePreParams(params);

%% 3D Image Registration
PreParams = XYZreg(params,PreParams);

%% Extract in focus images (reslice stack) and X-Y register
ResliceAndRegister(params,PreParams);

%% Particle tracking algorithms employed to correct for radial distortion (get k and ex params)
PreParams = RadialCorrectionCalc(params,PreParams);

%% Radially correct the already-registered images
RadialCorrect(params,PreParams);

%% Itteratively calculate X-Y and radial correction parameters
subfolders = {'RadiallyCorrectedImages1','RadiallyCorrectedImages2','RadiallyCorrectedImages3','RadiallyCorrectedImages4','RadiallyCorrectedImages5','RadiallyCorrectedImages6'};
PreParams = ItterativeRegistration(params,PreParams,subfolders);

%% Load dark images and calculate darkfield correction
PreParams = Darkfield(params,PreParams);

%% X-Y-Radial Correct shade images
ShadeCorrect(params,PreParams);

%% Calculate normalized shading image for each channel
PreParams = ShadeCorrectGen(params,PreParams);

%% Save out PreParams into folder and clean up workspace
save(fullfile(params.folder,'Parameters','PreParams.mat'),'-struct','PreParams');
rmpath(genpath(params.folder));