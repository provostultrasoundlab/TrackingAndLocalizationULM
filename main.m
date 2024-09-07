clear all
clc
close all
%% DEFINE PATHS AND BUFFERS THAT WILL BE TREATED IN THE LOCAL_CONFIG.JSON FILE
LocalConfig = dataLoader.LoadLocalConfig();
dataPath = LocalConfig.datasetPath; 
disp(['Data path is : ', dataPath])
savePath = LocalConfig.savePath;
mkdir(savePath);
disp(['Save path is : ', savePath])

% Path of processing parameters that will be used
cfg_processing_path = LocalConfig.pathConfig2D;
disp(['config path is : ', cfg_processing_path])

ParamProcessing = dataLoader.LoadSaveParams(cfg_processing_path,[savePath,'/cfg_processing.json']);

%%
iqSVDFilesListing = dir([dataPath, filesep, 'iqPostSVD*']);
nBuffer = length(iqSVDFilesListing); 
%%
for iBuffer = 1:nBuffer
    disp(['Buffer ', num2str(iBuffer), ' / ', num2str(nBuffer)])
    iqSVDFile = [dataPath, filesep, iqSVDFilesListing(iBuffer).name];
    fileContent = load(iqSVDFile);
    iqSvdFiltered = gather(fileContent.iqSvdFiltered); %% Complex array
    info = fileContent.info;
    frameRate=info.frameRate;
    numFrame=size(iqSvdFiltered,3);
    tic
    resultsTracking.(ParamProcessing.trackingMethod{1})  =SpatioTempTracker(iqSvdFiltered,ParamProcessing);
    tracks = Tracks(resultsTracking,ParamProcessing,frameRate,numFrame);
    time_tracking = toc;
    disp(['The processing time for the TAL is ',num2str(time_tracking),' s'])
    save(sprintf('%s%s%s_%d.mat', savePath, filesep, 'tracks_buffer_', iBuffer), "tracks","info")
end

