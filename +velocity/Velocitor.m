classdef Velocitor < handle
    properties
        velocity_info
    end
    methods
        function obj = Velocitor(varargin)
            % Constructor method
            p = inputParser;
            addRequired(p, 'ParamProcessing')
            p.parse(varargin{:});
            ParamProcessing = p.Results.ParamProcessing;
            if isfield(ParamProcessing, 'interpolationMethod')
                obj.velocity_info.interpolationMethod = ParamProcessing.interpolationMethod;
            end
        end
        function tracks = velocity_tracks(obj,tracks)
            if strcmp(obj.velocity_info.interpolationMethod{1}, 'spline')
                tracks = obj.spline_derivation(tracks);
            elseif strcmp(obj.velocity_info.interpolationMethod{1}, 'makima')
                tracks = obj.makima_derivation(tracks);         
            end
        end
    end
    methods (Static)
        function tracks = spline_derivation(tracks) 
            for imethod =1:tracks.tracks_info.N_tracking_method
                tracks_method = tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod});
                equation_method = tracks.equation_interp.(tracks.tracks_info.nameMethod{imethod});
                for itrack = 1:size(tracks_method,1)
                    track = tracks_method{itrack};
                    T_interp = track(:,4);
                    Spline = equation_method{itrack};
                    DSpline = fnder(Spline); % derivative of the function
                    Dval = fnval(DSpline,T_interp'); % Evaluation derivative at each time point
                    tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod}){itrack} =...
                     [tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod}){itrack},...
                     Dval(1,:)',zeros(size(Dval,2),1),Dval(2,:)'];         
                end
            end
        end
        function tracks = makima_derivation(tracks)
            for imethod =1:tracks.tracks_info.N_tracking_method
                tracks_method = tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod});
                tracks_raw_method = tracks.tracks_raw.(tracks.tracks_info.nameMethod{imethod});
                equation_method = tracks.equation_interp.(tracks.tracks_info.nameMethod{imethod});
                for itrack = 1:size(tracks_method,1)
                    track = tracks_method{itrack};
                    track_raw = tracks_raw_method{itrack};
                    track_raw = fillmissing(track_raw,"makima",1); 
                    equation = equation_method{itrack};
                    T_raw = track_raw(:,4)./tracks.tracks_info.frameRate;
                    T_interp = track(:,4);
                    [Fx, Fy, Fz]  = equation{:};
                    gx = gradient(Fx(T_raw))/(1/tracks.tracks_info.frameRate);
                    gy = gradient(Fy(T_raw))/(1/tracks.tracks_info.frameRate);
                    gz = gradient(Fz(T_raw))/(1/tracks.tracks_info.frameRate);
                    Gx = griddedInterpolant(T_raw, gx, 'makima', 'none');
                    Gy = griddedInterpolant(T_raw, gy, 'makima', 'none');
                    Gz = griddedInterpolant(T_raw, gz, 'makima', 'none');
                    vx = Gx(T_interp);
                    vy = Gy(T_interp);
                    vz = Gz(T_interp);

                    tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod}){itrack} =...
                     [tracks.tracks_interp.(tracks.tracks_info.nameMethod{imethod}){itrack},...
                     vx,vy,vz];         
                end
            end
        end
    end

end
