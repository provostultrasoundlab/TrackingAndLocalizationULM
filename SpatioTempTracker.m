function [tracks] = SpatioTempTracker(varargin)
    % Alexis LECONTE 2024
    % Article reference : https://ieeexplore.ieee.org/document/10669597 
    % SpatioTempTracker - 1 - Enhance the microbubble signals in the absolute value of the IQ post SVD data (Hessian and Jerman function)
    % SpatioTempTracker - 2 - Segment the microbubbles trajectories with a centerline algorithm (pixelic centerline)
    % SpatioTempTracker - 3 - Localize the microbubbles with a radial symetry algorithm (sub-wavelength localization) from the centerline detected positions.
    %   ----- INPUTS --------
    % iqSvdFiltered : The absolute value of the IQ post SVD
    % ParamULM : structure containing various parameters for the tracking algorithm
    %   optTracking:
    %       options_Spatiotemp : options for the Hessian and Jerman function
    %           sigmas : pixel size of the PSF
    %           tau : importance of the noise (0 takes nothing, 1 takes all)
    %           epsilon : small perturbation to avoid linking spatiotemporal trajectories in space
    %       minSizeTrack : minimum number of frames for a track to be considered
    %   size_ROI : size of the ROI for localization
    %   ----- OUTPUTS --------
    % tracks : cells of tracks where the postions are sub_pixelics 
    %          tracks{itrack} : matrix of the positions of the MBs in a tracks (x,y,z,frame)
    
    % ------- WARNING ------
    % !!! make sure the pixels grid is ISOMETRIC !!
    %% Updated in 13/06/2025
        %% Add path
        addpath(genpath(pwd)) 
        %% Initialisation param and data 
        narginchk(2,2);
        abs_iq                         = abs(varargin{1});
        ParamULM                       = varargin{2};
        options_Spatiotemp             = ParamULM.optTracking.options_Spatiotemp;
        minSizeTrack                   = ParamULM.optTracking.minSizeTrack;
        numFrame                       = size(abs_iq,3);
        try LocParam.method = ParamULM.Method_Localization;
        catch
            disp('Default Method of localization is radial symmetry')
            LocParam.method =  'RadialSymmetry';
        end
    
        try LocParam.size_ROI = ParamULM.size_ROI;
        catch
            warning('Default size_ROI for radial Symmetry used : 30 for lambda over 4 beamforming')
            LocParam.size_ROI = 30;
        end
        % Set LocParam.debug to ParamULM.debug if available; otherwise, default to false.
        try LocParam.debug = ParamULM.debug;
        catch
            LocParam.debug = false;
        end
        LocParam.sizeEns              = 3;
        %% Hessian and Jerman function
        Vfiltered=lib.trajectories_filter(abs_iq,options_Spatiotemp);
        
        %% Threshold on the Hessian
        threshold  = 0.05;
        ind  = abs(Vfiltered)< threshold;
        % Binary mask
        Vfiltered(ind)=0; 
        clear ind 
        %% Interpolation of the mask
        factor_interp_mask = 0.5; % This interpolation can be remvoed. It just permits to increase the condifence of localization without increasing the cost
        sz_Vfiltered = size(Vfiltered);
        Vfiltered_grid = griddedInterpolant({1:sz_Vfiltered(1),1:sz_Vfiltered(2),1:sz_Vfiltered(3)},Vfiltered);
        Vfiltered = Vfiltered_grid({1:factor_interp_mask:sz_Vfiltered(1),1:factor_interp_mask:sz_Vfiltered(2),1:sz_Vfiltered(3)});
        Spatio_temp_Hessian_mask = Vfiltered;
        Vfiltered = abs(Vfiltered)>0; % Binary mask
        %% Interpolation IQ
        sz_iq = size(abs_iq);
        iq_grid = griddedInterpolant({1:sz_iq(1),1:sz_iq(2),1:sz_iq(3)},abs_iq);
        abs_iq_interp = iq_grid({1:factor_interp_mask:sz_iq(1),1:factor_interp_mask:sz_iq(2),1:sz_iq(3)});
    
        %% Centerline 
        disp('Centerline') 
        % smoothing span needs to be set to 0 to keep exact pixel values
        smoothing_span = 0;
        % minSizeTrack is used here to remove small splitting branches fron the
        % centerline
        segs = Matlab3DThinning(Vfiltered, minSizeTrack, ...
            smoothing_span);
        clear Vfiltered Vfiltered_grid 
        
        obj_segs = Spatiotemp_traj(segs,minSizeTrack,numFrame);
    
        % This code removes any tracks smaller than min_size_track
        fprintf('Removing of the tracks smaller than min_size_track %d\n', minSizeTrack);
        obj_segs.prune_segments(); 
        
        %% In each track, we sort the detection along time (avoid bugs) : make the code more robust
        obj_segs.correct_timeline();
    
        %% We remove the double localization for one bubble in the same frame
        obj_segs.remove_duplicate_locations(Spatio_temp_Hessian_mask);
        %% We remove the small vessels after all the modifications
        obj_segs.prune_segments(); 
        
        %% Cells of tracks where the postions are sub_pixelics : Classic Localization algorithm
        obj_segs.px2subpx(abs_iq_interp,LocParam);
        %% We put the localizations on the initial beamforming grid
        obj_segs.sub_segs=cellfun(@(x) [x(:,[1,2])*factor_interp_mask,x(:,3)],obj_segs.sub_segs,'UniformOutput',false);
        %% Remove the potential nan at the extremity of the tracks
        obj_segs.rm_nan_extremity();
        
        obj_segs.prune_segments('segment','sub_segs');
        
        obj_segs.format_output();
    
        tracks = obj_segs.tracks;
    end
    