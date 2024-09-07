function cmap = blueRed()
    c = {'#c0ffff','#00ffff','#0000ff','#000000','#ff0000','#ffff00','#ffffbf'};
    cmap = zeros(length(c),3);
    for i = 1:length(c)
        cmap(i, :) = [hex2dec(string(c{i}(2:3)))/255, hex2dec(string(c{i}(4:5)))/255, hex2dec(string(c{i}(6:7)))/255];
    end
    % Interpolate between these values to create the colormap
    numColors = 256;  % The number of colors in the colormap
    cmap = interp1(1:size(cmap,1), cmap, linspace(1,size(cmap,1),numColors), 'pchip');
end
