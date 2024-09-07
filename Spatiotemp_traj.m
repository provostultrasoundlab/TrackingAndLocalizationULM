classdef Spatiotemp_traj < handle
    properties
        segs
        sub_segs
        tracks
        N_track
        Tmax
        minSizeTrack
        coordsPerFrame
    end
    methods
        function obj = Spatiotemp_traj(varargin)
            p = inputParser;
            addRequired(p, 'segs')
            addRequired(p, 'minSizeTrack')
            addRequired(p, 'numFrame')
            
            p.parse(varargin{:});

            obj.segs = p.Results.segs;
            obj.minSizeTrack = p.Results.minSizeTrack;
            obj.N_track = length(obj.segs);
            obj.coordsPerFrame =  cell(p.Results.numFrame,1);
        end

        % [DEPRECIATED]
        function obj = sort_tracks(obj)
            obj.segs = cellfun(@(x) sortrows(x,3),obj.segs,'UniformOutput',false);
        end

        % This function removes duplicate locations from the segments in obj.segs
        % based on a given mask. It calculates the weighted average of the x and y
        % coordinates for each unique z value in the segment, using the mask to
        % weight the values. It then removes any duplicate locations from the
        % segment.
        function obj = remove_duplicate_locations(obj, mask)
            % checksum
            if obj.N_track == 1
                error('number of segments insufficient')
            end
            
            pop = ones(obj.N_track,1);
            for idx = 1:obj.N_track
                bb_seg = obj.segs{idx};

                % checksum
                if length(bb_seg) < 2
                    continue
                end

                udx = unique(bb_seg(:,3));
                tmp = zeros(length(udx),3);
                for u = 1:length(udx)
                    tidx = find(bb_seg(:,3) == udx(u));
                    weights = zeros(length(tidx),1);
                    for t = 1:length(tidx)
                        weights(t) = mask(bb_seg(tidx(t),2), ...
                                          bb_seg(tidx(t),1), ...
                                          bb_seg(tidx(t),3));
                    end
                    tmp(u,:) = [sum(bb_seg(tidx,1:2).*weights,1)./sum(weights) udx(u)];
                end
                obj.segs{idx} = tmp(~any(isnan(tmp),2),:);
                if isempty(obj.segs{idx})
                    pop(idx) = 0;
                end
            end

            % pop empty cells
            obj.segs = {obj.segs{find(pop)}}';
            obj.N_track = length(obj.segs);

        end

        function obj = correct_timeline(obj)
            obj.segs = cellfun(@(x) x(find((x(:,3) - x(1,3)) >= 0),:), obj.segs, 'UniformOutput', false);
        end

        function obj = rm_nan_extremity(obj)
            for ii = 1:obj.N_track
                % Remove the nan at the begining of the vector
                while isnan(obj.sub_segs{ii}(1,1))
                    obj.sub_segs{ii}(1,:) = [];
                end
                % Remove the nan at the end of the vector
                while isnan(obj.sub_segs{ii}(end,1))
                    obj.sub_segs{ii}(end,:) = [];
                end
            end
        end

        function obj = px2subpx(obj,varargin)
            p = inputParser;
            addRequired(p, 'IQ');
            addRequired(p, 'opt');
            p.parse(varargin{:});
            
            IQ = p.Results.IQ;
            opt = p.Results.opt;
            
            % create a temporary cell array already populated with nans
            t_segs = cellfun(@(x) x*nan, obj.segs, 'UniformOutput', false);

            % calculate boundaries
            IQsize = size(IQ);
            half_size_ROI = round(opt.size_ROI/2);
            vectfwhm = -1 * half_size_ROI:half_size_ROI; % assuming symmetric ROI
            Ens = linspace(-1,1,opt.sizeEns)' .* (opt.sizeEns - 1) / 2;
            bounds = [[half_size_ROI       , IQsize(2) - half_size_ROI]; ...
                      [half_size_ROI       , IQsize(1) - half_size_ROI]; ...
                      [floor(opt.sizeEns/2), IQsize(3) - ceil(opt.sizeEns/2)]];

            switch opt.method

                case 'RadialSymmetry'
                    for idt = 1:obj.N_track
                        for idb = 1:length(obj.segs{idt})
                            coords = round(obj.segs{idt}(idb,:))';

                            if all(coords > bounds(:,1) & coords < bounds(:,2))
                                
                                % if within bounds, grab chunk
                                IntensityROI = mean(IQ(coords(2) + vectfwhm, ...
                                    coords(1) + vectfwhm, ...
                                    round(coords(3) + Ens)),3);

                                % calculate radial symmetry
                                [Xc, Zc, sigma] = obj.LocRadialSym(IntensityROI);
                                sub_px = coords + [Zc Xc 0]';

                                % if sub pixel guess is large, skip
                                if abs(Zc) > half_size_ROI || abs(Xc) > half_size_ROI
                                    continue
                                end
                                
                                % otherwise, overwrite
                                t_segs{idt}(idb,:) = sub_px;
                            end
                        end
                    end
                otherwise
                    error('localization method not recognized');
            end
            nan_cells = find(cellfun(@(x) any(~isnan(x(:))),t_segs));
            obj.sub_segs = {t_segs{nan_cells}}';
            obj.N_track = length(obj.sub_segs);
        end

        function obj = spline_interp_and_derivate(obj,varargin)
            p = inputParser;
            addRequired(p, 'opt');
            p.parse(varargin{:});

            opt = p.Results.opt;

            temp_seg = cell(obj.N_track,1);

            res_interp = round(1/opt.interp_factor,2); % interpolation factor
            for idx = 1:obj.N_track % for loop on the tracks

                track = obj.sub_segs{idx};
                track = fillmissing(track,"linear",1); % Complete nan position by interpolation
                pos = track.*[opt.factor_interp_mask opt.factor_interp_mask 1/opt.PRF];

                % spline interpolation
                T_interp = min(pos(:,3)):res_interp/opt.PRF:max(pos(:,3)); % New time vector (s) for interpolation by 10 res_interp=1/10;
                %p=1-10^(-6);
                p = (opt.frequency_spline^4)/(1+opt.frequency_spline^4); % is the smoothing parameters that depends on the cut-off frequency
                Spline = csaps(pos(:,3)', [pos(:,1)';pos(:,2)'],p); % return a function of the intial time with two dimensions (Z and X)
                DSpline = fnder(Spline); % derivative of the function
                val = fnval(Spline,T_interp'); % Evaluation at the new time vector
                Dval = fnval(DSpline,T_interp'); % idem for the derivative

                % replace subpixel segment with result
                temp_seg{idx}(:,1) = val(1,:) ; %Z_pos (px)
                temp_seg{idx}(:,2) = val(2,:) ; %X_pos (px)
                temp_seg{idx}(:,3) = T_interp ; % time (sec)
                temp_seg{idx}(:,4) = Dval(1,:) ;% vz (px/sec)
                temp_seg{idx}(:,5) = Dval(2,:) ;% vx (px/sec)
            end
            % overwrite sub_segs
            obj.sub_segs = temp_seg;
        end

        function obj = cell2table(obj)

            % preallocate array
            n = cellfun(@(x) length(x),obj.sub_segs);
            total_n = sum(n);
            temp = zeros(total_n,9);

            Borne = 0;
            for idx = 1:obj.N_track % ForLoop on tracks
                coords = obj.sub_segs{idx};
                vec = (1 + Borne : n(idx) + Borne);
                temp(vec, 1)    = coords(:,1); %(px)
                temp(vec, 3)    = coords(:,2); %(px)
                temp(vec, 4)    = coords(:,3); % (time (s))
                temp(vec, 5)    = obj.sub_segs{idx}(:,4); % px/s
                temp(vec, 7)    = obj.sub_segs{idx}(:,5); % px/s
                temp(vec, 9)    = idx;
                Borne           = Borne + n(idx);
            end
            obj.tracks = temp;
        end

        function obj = prune_segments(obj, varargin)
            p = inputParser;
            addOptional(p,'segment','segs');
            p.parse(varargin{:});
            segment = p.Results.segment;

            switch segment
                case 'segs'
                    [obj.segs, obj.N_track, obj.Tmax] = obj.prune(obj, obj.segs);
                case 'sub_segs'
                    [obj.sub_segs, obj.N_track, obj.Tmax] = obj.prune(obj, obj.sub_segs);
            end

        end
        function obj= format_output(obj)
            % Input : sub_segs : (x,z,frame)
            % Output : tracks : (x,0,z,frame)
            insertColumn = @(x) [x(:, 1), zeros(size(x, 1), 1), x(:, 2:end)];

            % Apply the function to each cell using cellfun
            obj.tracks = cellfun(insertColumn, obj.sub_segs, 'UniformOutput', false);

        end

        function obj= tracks_to_coordsPerFrame(obj)
            for itracks = 1:size(obj.tracks,1)
                track_itracks = obj.tracks{itracks};
                for pos_itracks = 1:size(track_itracks,1)
                    frame_pos_itracks = track_itracks(pos_itracks,4);
                    if isnan(frame_pos_itracks)
                        continue
                    end
                    obj.coordsPerFrame{frame_pos_itracks}(end+1,:) = track_itracks(pos_itracks,1:3);
                end
            end
        end

    end


    methods (Static)
        function [Zc,Xc,sigma] = LocRadialSym(Iin)
            [Zc,Xc] = lib.localizeRadialSymmetry(Iin);
            %% This function will calculate the Gaussian width of the presupposed peak in the intensity, which we set as an estimate of the width of the microbubble
            [Nx,Nz] = size(Iin);
            Isub = Iin - mean(Iin(:));
            [px,pz] = meshgrid(1:Nx,1:Nz);
            zoffset = pz - Zc+(Nz)/2.0;%BH xoffset = px - xc;
            xoffset = px - Xc+(Nx)/2.0;%BH yoffset = py - yc;
            r2 = zoffset.*zoffset + xoffset.*xoffset;
            sigma = sqrt(sum(sum(Isub.*r2))/sum(Isub(:)))/2;  % second moment is 2*Gaussian width        end
        end

        function [segs, N, Tmax] = prune(obj, segs)
            idx = cellfun(@(x) sum(~isnan(x(:,1)))>=obj.minSizeTrack,segs);
            segs = cell(segs(find(idx)));
            N = length(segs);
            Tmax = max(cellfun(@(x) length(x),segs));
        end

    end
end