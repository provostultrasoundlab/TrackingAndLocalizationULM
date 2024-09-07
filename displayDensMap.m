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

trackFilesListing = dir([savePath, filesep, 'tracks*']);
nTracks = length(trackFilesListing); 
currentFile = [trackFilesListing(1).folder, filesep, trackFilesListing(1).name];
fileContent = load(currentFile);
info = fileContent.info;
tracks1 = fileContent.tracks;
availableTrackingMethods = tracks1.tracks_info.nameMethod;

Resolution_maps_Lambda_over = 30;
resSuperloc = info.wavelength/Resolution_maps_Lambda_over;

Interpolator = interpolation.Interpolator(ParamProcessing,info.frameRate);
Velocitor = velocity.Velocitor(ParamProcessing);    

xbins = (info.xMin:resSuperloc:info.xMax);
zbins = (info.zMin:resSuperloc:info.zMax);

densMapTracksSum_up = zeros(size(zbins,2),size(xbins,2));
densMapTracksSum_down = zeros(size(zbins,2),size(xbins,2));

%%

% Loop over all the buffer (tracks files in the dataset)
for iTrack = 1:nTracks
    iTrack
    currentFile = [trackFilesListing(iTrack).folder, filesep, ...
    trackFilesListing(iTrack).name];
    fileContent = load(currentFile);
    tracks = fileContent.tracks;
    %%
    tracks= Interpolator.interp_tracks(tracks);
    tracks = Velocitor.velocity_tracks(tracks);
    tracks.pixelToMeters(info);
    tracks.UpDown();
    % take only the tracks from the corresponding tracking method
    
    sub_track_up = cell2mat(tracks.tracks_interp_up.(availableTrackingMethods{1}));
    sub_track_down = cell2mat(tracks.tracks_interp_down.(availableTrackingMethods{1}));
    % Calculate density map
    densMapTracksSum_up = densMapTracksSum_up + lib.DensityMappingND(sub_track_up,xbins,zbins);
    densMapTracksSum_down = densMapTracksSum_down + lib.DensityMappingND(sub_track_down,xbins,zbins);
end

densMapTracksSum_down(densMapTracksSum_down<densMapTracksSum_up)=0;
densMapTracksSum_up(densMapTracksSum_up<densMapTracksSum_down)=0;
densMapTracks = densMapTracksSum_down+ densMapTracksSum_up;

IUpDown = (densMapTracksSum_up).^(1/3) - (densMapTracksSum_down).^(1/3);
%%
mkdir([savePath, filesep,'Dens&VelMap/'])
save([savePath, filesep,'Dens&VelMap/UpDown'], "IUpDown");
%%
caxisDens = [0 7]; % caxis density
caxisDensUpDown = [-6 6]; % caxis density
Overlay = (densMapTracks).^(1/3);
Im_density = lib.MergeImageBounds(Overlay, 'gray', caxisDens,...
    IUpDown,lib.blueRed, caxisDensUpDown,1);
%%
figure(1);clf;
imagesc(Im_density);axis image; title('Map of Density')
mkdir([savePath, filesep,'Images/'])
imwrite(Im_density,[savePath, filesep,'Images/DensMap_signed_range_',int2str(caxisDensUpDown(1)),'_',int2str(caxisDensUpDown(2)),'.png']);
imwrite(Im_density,[savePath, filesep,'Images/DensMap_signed_range_',int2str(caxisDensUpDown(1)),'_',int2str(caxisDensUpDown(2)),'.tiff']);
