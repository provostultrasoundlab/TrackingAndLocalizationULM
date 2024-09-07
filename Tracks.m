classdef Tracks < handle
    properties
        tracks_raw
        tracks_info
        tracks_interp
        equation_interp
        coordsPerFrame_raw
        coordsPerFrame_interp
        tracks_interp_up
        tracks_interp_down
    end
    methods
        function obj = Tracks(varargin)
            % Constructor method
            p = inputParser;
            addRequired(p, 'resultsTracking')
            addRequired(p, 'ParamProcessing')
            addRequired(p, 'frameRate')
            addRequired(p,'numFrame')
            p.parse(varargin{:});
            ParamProcessing = p.Results.ParamProcessing;
            frameRate = p.Results.frameRate;
            obj.tracks_info.frameRate=frameRate;
            obj.tracks_info.N_tracking_method = size(p.Results.ParamProcessing.trackingMethod,1);
            obj.tracks_info.interp_method = ParamProcessing.interpolationMethod;
            obj.tracks_info.interpFactor= ParamProcessing.optInterpolation.interpFactor;
            obj.tracks_info.numFrame = p.Results.numFrame;
            if isfield(ParamProcessing.optInterpolation, 'smoothFactor')
                obj.tracks_info.smoothFactor = ParamProcessing.optInterpolation.smoothFactor;
            end

            if isfield(ParamProcessing.optInterpolation, 'splineFrequency')
                obj.tracks_info.splineFrequency = ParamProcessing.optInterpolation.splineFrequency;
            end
            for imethod = 1:obj.tracks_info.N_tracking_method
                obj.tracks_info.nameMethod{imethod} = ParamProcessing.trackingMethod{imethod};
                try
                    obj.tracks_raw.(obj.tracks_info.nameMethod{imethod}) = ...
                    p.Results.resultsTracking.(obj.tracks_info.nameMethod{imethod});
                catch
                    obj.tracks_raw.(obj.tracks_info.nameMethod{imethod}) = ...
                    p.Results.resultsTracking;
                end
                obj.tracks_info.N_track{imethod} = size(obj.tracks_raw.(obj.tracks_info.nameMethod{imethod}),1);
            end
        end



        function obj  = setCoordsPerFrame(obj)
            for imethod = 1:obj.tracks_info.N_tracking_method
                tracks_raw_method = obj.tracks_raw.(obj.tracks_info.nameMethod{imethod});
                tracks_interp_method = obj.tracks_interp.(obj.tracks_info.nameMethod{imethod});
                obj.coordsPerFrame_raw.(obj.tracks_info.nameMethod{imethod}) = cell(obj.tracks_info.numFrame,1);
                obj.coordsPerFrame_interp.(obj.tracks_info.nameMethod{imethod}) = cell(obj.tracks_info.numFrame,1);
                obj.coordsPerFrame_interp.(obj.tracks_info.nameMethod{imethod}) = cell(obj.tracks_info.numFrame,1);
                for itracks = 1:size(tracks_raw_method,1)
                    track_raw_itracks = tracks_raw_method{itracks};
                    track_interp_itracks = tracks_interp_method{itracks};
                    time_interp_frame = floor(track_interp_itracks(:,4)*obj.tracks_info.frameRate) ;
                    for pos_itracks = 1:size(track_raw_itracks,1)
                        frame_pos_itracks = track_raw_itracks(pos_itracks,4);
                        if isnan(frame_pos_itracks)
                            continue
                        end
                        obj.coordsPerFrame_raw.(obj.tracks_info.nameMethod{imethod}){frame_pos_itracks,1}(end+1,:)...
                            = track_raw_itracks(pos_itracks,:);
                        ind_frame_start = find(time_interp_frame==frame_pos_itracks);
                        obj.coordsPerFrame_interp.(obj.tracks_info.nameMethod{imethod}){frame_pos_itracks}(end+[1:length(ind_frame_start)],:) = ...
                        track_interp_itracks(ind_frame_start,:);
                    end
                end
                obj.coordsPerFrame_raw.(obj.tracks_info.nameMethod{imethod})  = cellfun(@(x) obj.frame_to_seconds(x,obj.tracks_info.frameRate),...
                    obj.coordsPerFrame_raw.(obj.tracks_info.nameMethod{imethod}),'UniformOutput',false);
            end
        end
        function obj = pixelToMeters(obj,bf)
            size_px_grid = [bf.resBfGrid, bf.resBfGrid, bf.resBfGrid, 1,...
                bf.resBfGrid, bf.resBfGrid,bf.resBfGrid];
            origin_grid = [bf.xMin, bf.yMin, bf.zMin, zeros(1,size(size_px_grid,2)-3)];
            for imethod = 1:obj.tracks_info.N_tracking_method
                %% Tracks
                obj.tracks_raw.(obj.tracks_info.nameMethod{imethod}) = cellfun(@(x) x.*size_px_grid(1:4),...
                    obj.tracks_raw.(obj.tracks_info.nameMethod{imethod}),'UniformOutput',false );
                obj.tracks_raw.(obj.tracks_info.nameMethod{imethod}) = cellfun(@(x) x+origin_grid(1:4),...
                    obj.tracks_raw.(obj.tracks_info.nameMethod{imethod}),'UniformOutput',false );
                if isfield(obj.tracks_interp, obj.tracks_info.nameMethod{imethod})
                    obj.tracks_interp.(obj.tracks_info.nameMethod{imethod}) = cellfun(@(x) x.*size_px_grid,...
                        obj.tracks_interp.(obj.tracks_info.nameMethod{imethod}),'UniformOutput',false );
                    obj.tracks_interp.(obj.tracks_info.nameMethod{imethod}) = cellfun(@(x) x+origin_grid,...
                        obj.tracks_interp.(obj.tracks_info.nameMethod{imethod}),'UniformOutput',false );
                end

                if isfield(obj.coordsPerFrame_raw, obj.tracks_info.nameMethod{imethod})
                    obj.coordsPerFrame_raw.(obj.tracks_info.nameMethod{imethod}) = cellfun(@(x) obj.pxToMetersConditionNotEmpty(x,size_px_grid(1:4)),...
                        obj.coordsPerFrame_raw.(obj.tracks_info.nameMethod{imethod}),'UniformOutput',false );
                    obj.coordsPerFrame_raw.(obj.tracks_info.nameMethod{imethod}) = cellfun(@(x) obj.originConditionNotEmpty(x,origin_grid(1:4)),...
                        obj.coordsPerFrame_raw.(obj.tracks_info.nameMethod{imethod}),'UniformOutput',false );
                end

                if isfield(obj.coordsPerFrame_interp, obj.tracks_info.nameMethod{imethod})
                    obj.coordsPerFrame_interp.(obj.tracks_info.nameMethod{imethod}) = cellfun(@(x) obj.pxToMetersConditionNotEmpty(x,size_px_grid),...
                        obj.coordsPerFrame_interp.(obj.tracks_info.nameMethod{imethod}),'UniformOutput',false );
                    obj.coordsPerFrame_interp.(obj.tracks_info.nameMethod{imethod}) = cellfun(@(x) obj.originConditionNotEmpty(x,origin_grid),...
                        obj.coordsPerFrame_interp.(obj.tracks_info.nameMethod{imethod}),'UniformOutput',false );
                end
            end
        end
        function obj = UpDown(obj)
            for imethod = 1:obj.tracks_info.N_tracking_method
                tracks_interp = obj.tracks_interp.(obj.tracks_info.nameMethod{imethod}) ;
                
                tracks_interp_up = cellfun(@(x) obj.upDownTracks(x,'up'),tracks_interp,"UniformOutput",false);
                tracks_interp_down = cellfun(@(x) obj.upDownTracks(x,'down'),tracks_interp,"UniformOutput",false);
                tracks_interp_up = tracks_interp_up(~cellfun(@isempty, tracks_interp_up));
                tracks_interp_down = tracks_interp_down(~cellfun(@isempty, tracks_interp_down));
                obj.tracks_interp_up.(obj.tracks_info.nameMethod{imethod}) = tracks_interp_up;
                obj.tracks_interp_down.(obj.tracks_info.nameMethod{imethod}) = tracks_interp_down;
            end
        end
    end
    methods (Static)
        function res = frame_to_seconds(x,frameRate)
            if ~isempty(x)
                res = [x(:,1:3) , x(:,4)./frameRate];
            else
                res=[];
            end
        end
        function res = pxToMetersConditionNotEmpty(x,size_px_grid)
            if ~isempty(x)
                % Perform the operation only if x is not empty
                res = x .* size_px_grid;
            else
                % If x is empty, return an empty array
                res = [];
            end
        end
        function res = originConditionNotEmpty(x,origin_grid)
            if ~isempty(x)
                % Perform the operation only if x is not empty
                res = x +origin_grid;
            else
                % If x is empty, return an empty array
                res = [];
            end
        end
        function res = upDownTracks(matrix,method)
            dist_cum_z = sum(diff(matrix(:,3)));
            if dist_cum_z >= 0
                if strcmp(method,'down')
                    res  = matrix;
                else 
                    res=[];
                end
            else 
                if strcmp(method,'up')
                    res  = matrix;
                else 
                    res=[];
                end
            end
        end
    end
end