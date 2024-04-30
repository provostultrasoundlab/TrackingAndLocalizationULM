clear all
clc
close all
%% DEFINE PATHS AND BUFFERS THAT WILL BE TREATED
% Fetch environnment variables (used on ComputeCanada) or use local config


% Path where the untreated data are
LocalConfig = dataLoader.LoadLocalConfig();
dataPath = [LocalConfig.dataPrefix2D, filesep, LocalConfig.datasetName2D]; 
disp(['Data path is : ', dataPath])
savePath = [LocalConfig.savePrefix2D, filesep, LocalConfig.datasetName2D];
mkdir(savePath);
disp(['Save path is : ', savePath])

% Path of processing parameters that will be used
cfg_processing_path = LocalConfig.pathConfig2D;
disp(['config path is : ', cfg_processing_path])

ParamProcessing = dataLoader.LoadSaveParams(cfg_processing_path,[savePath,'/cfg_processing.json']);

%%
load("path_IQ_post_SVD_data");
% iqSVdFiltered is the IQ post SVD
numFrame=size(iqSvdFiltered,3);
frameRate=1000;
%%
resultsTracking.(ParamProcessing.trackingMethod{1})  =SpatioTempTracker(iqSvdFiltered,ParamProcessing);
tracks = Tracks(resultsTracking,ParamProcessing,frameRate,numFrame);
Interpolator = interpolation.Interpolator(ParamProcessing,frameRate);
Velocitor = velocity.Velocitor(ParamProcessing);
tracks= Interpolator.interp_tracks(tracks);
tracks = Velocitor.velocity_tracks(tracks);
tracks.setCoordsPerFrame();

disp('Saving : ')
save([savePath, filesep, 'trackValid'], "tracks")