function [localConfig] = LoadLocalConfig()
%LOADLOCALCONFIG function that load the local config and return the
%corresponding structure
%   local config should be specified in an untracked file in the repo.
fid=fopen('local_config.json','r');
param_json = fscanf(fid,'%c');
fclose(fid);
localConfig = jsondecode(param_json);
if ~isfield(localConfig,'debug')
    localConfig.debug = 0;
end
end

