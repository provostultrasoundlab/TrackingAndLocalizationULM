classdef Interpolator < handle
    properties
        interp_info
    end
    methods
        function obj = Interpolator(varargin)
            % Constructor method
            p = inputParser;
            addRequired(p, 'ParamProcessing')
            addRequired(p, 'frameRate')
            p.parse(varargin{:});
            ParamProcessing = p.Results.ParamProcessing;
            frameRate = p.Results.frameRate;
            obj.interp_info.frameRate=frameRate;
            obj.interp_info.interp_method = ParamProcessing.interpolationMethod;
            obj.interp_info.interpFactor= ParamProcessing.optInterpolation.interpFactor;
            if isfield(ParamProcessing.optInterpolation, 'smoothFactor')
                obj.interp_info.smoothFactor = ParamProcessing.optInterpolation.smoothFactor;
            end
            
            if isfield(ParamProcessing.optInterpolation, 'splineFrequency')
                obj.interp_info.splineFrequency = ParamProcessing.optInterpolation.splineFrequency;
            end
        end
        function [tracks] = interp_tracks(obj,tracks)
            if isfield(obj.interp_info, 'smoothFactor')
                tracks.tracks_info.smoothFactor = obj.interp_info.smoothFactor;
            end
            if isfield(obj.interp_info, 'splineFrequency')
                tracks.tracks_info.splineFrequency = obj.interp_info.splineFrequency;
            end
            if strcmp(tracks.tracks_info.interp_method{1}, 'spline')
                tracks = obj.spline_interpolation(tracks);
            elseif strcmp(tracks.tracks_info.interp_method{1}, 'makima')
                tracks = obj.makima_interpolation(tracks);         
            end
        end 
        
    end
    methods (Static)
        % spline_interpolation - Performs spline interpolation on tracks data.
        function tracks = spline_interpolation(tracks) 
            for imethod =1:tracks.tracks_info.N_tracking_method
                tracks_method = tracks.tracks_raw.(tracks.tracks_info.nameMethod{imethod});
                tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod}) = cell(length(tracks_method),1);
                tracks.equation_interp.(tracks.tracks_info.nameMethod{imethod}) = cell(length(tracks_method),1);
                for itrack = 1:size(tracks_method,1)
                    track = tracks_method{itrack};
                    track = fillmissing(track,"makima",1); % Complete nan position by interpolation
                    pos = track.*[1 1 1,1/tracks.tracks_info.frameRate];
                    T_interp = min(pos(:,4)):1/(tracks.tracks_info.interpFactor*...
                        tracks.tracks_info.frameRate):max(pos(:,4)); % New time vector (s) for interpolation 
                    p = (tracks.tracks_info.splineFrequency^4)/(1+tracks.tracks_info.splineFrequency^4); % is the smoothing parameters that depends on the cut-off frequency
                    Spline = csaps(pos(:,4)', [pos(:,1)';pos(:,3)'],p);
                    val = fnval(Spline,T_interp');
                    tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod}){itrack}= [val(1,:)',...
                        zeros(size(val,2),1),val(2,:)', T_interp']; 
                    tracks.equation_interp.(tracks.tracks_info.nameMethod{imethod}){itrack} = Spline;              
                end
            end
        end
        % makima_interpolation - Performs makima interpolation on tracks data.
        function tracks = makima_interpolation(tracks)
            for imethod =1:tracks.tracks_info.N_tracking_method
                tracks_method = tracks.tracks_raw.(tracks.tracks_info.nameMethod{imethod});
                tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod}) = cell(length(tracks_method),1);
                tracks.equation_interp.(tracks.tracks_info.nameMethod{imethod}) = cell(length(tracks_method),1);
                for itrack = 1:size(tracks_method,1)
                    track = tracks_method{itrack};
                    track = fillmissing(track,"makima",1); % Complete nan position by interpolation
                    pos = track.*[1 1 1,1/tracks.tracks_info.frameRate];
                    T_interp = min(pos(:,4)):1/(tracks.tracks_info.interpFactor*tracks.tracks_info.frameRate):max(pos(:,4)); % New time vector (s) for interpolation 
                    Fx = griddedInterpolant(track(:,4)/(tracks.tracks_info.frameRate), track(:, 1), 'makima', 'none');
                    Fy = griddedInterpolant(track(:,4)/(tracks.tracks_info.frameRate), track(:, 2), 'makima', 'none');
                    Fz = griddedInterpolant(track(:,4)/(tracks.tracks_info.frameRate), track(:, 3), 'makima', 'none');
                    x = Fx(T_interp)';
                    y = Fy(T_interp)';
                    z = Fz(T_interp)';
                    tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod}){itrack}= [x,...
                        y,z, T_interp'];   
                    tracks.equation_interp.(tracks.tracks_info.nameMethod{imethod}){itrack} = {Fx,Fy,Fz};
                end
            end
        end
        

    end

end
