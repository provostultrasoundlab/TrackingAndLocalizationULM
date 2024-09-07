function [DensMap] = DensityMappingND(track,xbins,ybins,zbins)
%DensityMappingND : calculates density map from superresolved microbubbles
% positions, for a single frame. track x y z positions will be interpolled
% to fit into the xbins ybins zbins final map, and accumulated.
% Careful : xbins, ybins, zbins should be chosen relatively to track x, y, z
% positions (in pixels or in mm or in um), overwise they'll be out of the reconstruction grid
% INPUTS :
%       track : superresolved microbubbles positions
%       xbins : reconstruction map (x)
%       ybins : reconstruction map (y)
%       zbins : reconstruction map (z)
% OUTPUT :
%       DensMap : 2D or 3D static density map for ONE frame

track = reshape(track,[],size(track,ndims(track)));
X = track(:,1);
Y = track(:,2);
Z = track(:,3);

if nargin >3 % 3D
    
    xNumBins = numel(xbins);
    yNumBins = numel(ybins);
    zNumBins = numel(zbins);
    
    % Map X/Y values to bin indices
    Xi = round( interp1(xbins, 1:xNumBins, X, 'pchip', 'extrap') );
    Yi = round( interp1(ybins, 1:yNumBins, Y, 'pchip', 'extrap') );
    Zi = round( interp1(zbins, 1:zNumBins, Z, 'pchip', 'extrap') );
    
    % Limit indices to the range [1,numBins]
    id = (Xi>1).*(Yi>1).*(Zi>1).*...
        (Xi<xNumBins).*(Yi<yNumBins).*(Zi<zNumBins);
    Xi = Xi(id>0);
    Yi = Yi(id>0);
    Zi = Zi(id>0);
    
    % Count number of elements in each bin
    DensMap = accumarray([Zi(:) Xi(:) Yi(:)], 1, [zNumBins xNumBins yNumBins]);

else % 2D
   
    xNumBins = numel(xbins);
    zNumBins = numel(ybins);
    
    % Map X/Y values to bin indices
    Xi = round( interp1(xbins, 1:xNumBins, X, 'pchip', 'extrap') );
    Zi = round( interp1(ybins, 1:zNumBins, Z, 'pchip', 'extrap') );
    
    % Limit indices to the range [1,numBins]
    id = (Xi>1).*(Zi>1).*...
        (Xi<xNumBins).*(Zi<zNumBins);
    Xi = Xi(id>0);
    Zi = Zi(id>0);
    
    % Count number of elements in each bin
    DensMap = accumarray([Zi(:) Xi(:)], 1, [zNumBins xNumBins]);
end
end