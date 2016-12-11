%function: 	MITprof_addVar
%
%usage:	   []=MITprof_addVar(filenc,varname,xtype,dimlist,varvalue); 
%		---> add a variable in a MITprof netcdf file
%
%inputs:	filenc		MITprof netcdf file name
%           varname,xtype,dimlist,varvalue:  variable information

function []=MITprof_addVar(filenc,varname,xtype,dimlist,varvalue);


% check that file exists and add prefix and suffix if necessary
[pathstr, name, ext] = fileparts(filenc);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
if isempty(ext) | ~strcmp(ext,'.nc'), ext='.nc'; end
filenc=[pathstr '/' name ext];
if ~exist(filenc,'file'), error([filenc ' : file not found']); end

%open file:
nc=ncopen(filenc,'write');

%add variable:
vars=ncvars(nc);
if isempty(find(ismember(vars,varname)))
    ncaddVar(nc,varname,xtype,dimlist);
end

%write data
ncputvar(nc,varname,varvalue);

%close file:
ncclose(nc);


