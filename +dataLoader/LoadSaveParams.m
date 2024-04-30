function [params] = LoadSaveParams(paramPath, savePath)
% LOADSAVEPARAMS Function that loads a json file as a structure and save it
% somewhere else, specified by the savePath
fid=fopen(paramPath,'r');
param_json = fscanf(fid,'%c');
fclose(fid);
params = jsondecode(param_json);
fid=fopen(savePath,'w');
fprintf(fid, param_json);
fclose(fid);

end

