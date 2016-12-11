function model_addinMITprof(ncfile,model,varargin)
% function model_addinMITprof(ncfile,model)
%   add hydrographic profiles from a model interpolated on profile
%   positions available in a MITprof netcdf file.
%
%   fileIn: path (absolute or relative) to MITprof netcdf file
%   model is a string used to select the model to be loaded
%       'OCCA' : ECCOv4 grid + OCCA atlas
%       'SOSE59' : SOSE59 grid + atlas

% process file name
[pathstr, name, ext] = fileparts(ncfile);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
if isempty(ext) | ~strcmp(ext,'.nc'), ext='.nc'; end
ncfile=[pathstr '/' name ext];

% load profiles
M=MITprof_load(ncfile);

% interpolate model
M=model_interp(M,model);

% add fields
fillval=double(-9999);
T=getfield(M,['prof_T_' model])'; T(isnan(T))=fillval;
MITprof_addVar(ncfile,['prof_T_' model],'double',{'iDEPTH','iPROF'},T);
S=getfield(M,['prof_S_' model])'; S(isnan(S))=fillval;
MITprof_addVar(ncfile,['prof_S_' model],'double',{'iDEPTH','iPROF'},S);

% add attributes
nc=ncopen(ncfile,'write');
ncaddAtt(nc,['prof_T_' model],'long_name',['pot. temp. model ' model]);
ncaddAtt(nc,['prof_T_' model],'units','degree C');
ncaddAtt(nc,['prof_T_' model],'missing_value',fillval);
ncaddAtt(nc,['prof_T_' model],'_FillValue',fillval);
ncaddAtt(nc,['prof_S_' model],'long_name',['salinity model ' model]);
ncaddAtt(nc,['prof_S_' model],'units','psu');
ncaddAtt(nc,['prof_S_' model],'missing_value',fillval);
ncaddAtt(nc,['prof_S_' model],'_FillValue',fillval);
ncclose(nc);
