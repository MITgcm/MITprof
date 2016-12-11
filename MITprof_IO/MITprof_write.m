function []=MITprof_write(fileOut,MITprof,varargin);
%function: 	MITprof_write
%object:	write data in a MITprof netcdf file
%author:	Gael Forget (gforget@mit.edu)
%date:		Nov 5th, 2010
%
%usage:	   []=MITprof_write(fileOut,MITprof, [list_vars] ); 
%
%inputs:	fileOut		data file name (absolute/relative path)
%                         .nc suffix is added if not already present
%           MITprof     struct containing profile data
%           list_vars	variable list (optional)
%
% Format description of MITprof struct input variable:
%   list of fields always available:
%       prof_depth      [nDepth x 1]
%       prof_descr      {nProf x 1} --> will be converted into a char array
%       prof_date       [nProf x 1]
%       prof_YYYYMMDD   [nProf x 1]
%       prof_HHMMSS     [nProf x 1]
%       prof_lon        [nProf x 1]
%       prof_lat        [nProf x 1]
%       prof_basin      [nProf x 1]
%       prof_point      [nProf x 1]
%
%   other fields generally available of size [nProf x nLev] :
%       prof_T, prof_Tflag, prof_Terr, prof_Tweight, prof_Testim
%       prof_S, prof_Sflag, prof_Serr, prof_Sweight, prof_Sestim
%
% if list_vars is not specified, every variables with a name starting 
%       with 'prof_', except prof_depth, will be saved in the MITprof
%       netcdf file. An error will occur if the program try to save a
%       variable that is not initialized in the MITprof netcdf file.
%
% if list_vars is specified, only variables present in the list will be
%       saved.
%
% NaN are auomatically replaced by missing_value attribute (or _FillValue).
% the file fileOut will be created using MITprof_create if needed.
%



% check that file exists and add prefix and suffix if necessary
[pathstr, name, ext] = fileparts(fileOut);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
if isempty(ext) | ~strcmp(ext,'.nc'), ext='.nc'; end
fileOut=[pathstr '/' name ext];

% build the list of variables that must be loaded
if nargin>2,
    list_vars=varargin{1};
else
    list1=fieldnames(MITprof); list_vars={};
    I=strfind(list1,'prof_');
    for kk=1:length(I),
        if I{kk}==1,
            list_vars{end+1}=list1{kk};
        end
    end
end

% stop if there are no profile in MITprof
nProf=length(MITprof.prof_lon);
if nProf==0, return, end

% create the file if needed
if ~exist(fileOut,'file'),
    prof_depth=MITprof.prof_depth;
    MITprof_create(fileOut,MITprof,list_vars);
end

% prof_descr: convert back from cell 2 array format
if isfield(MITprof,'prof_descr')
    ncload(fileOut,'prof_descr'); nb_char=size(prof_descr,2);
    prof_descr=char(MITprof.prof_descr);
    if size(prof_descr,2)<nb_char,
        prof_descr(:,size(prof_descr,2)+1:nb_char)=' ';
    elseif size(prof_descr,2)>nb_char
        disp('some profile descriptive strings have been shortened');
        prof_descr=prof_descr(:,1:nb_char);
    end
    MITprof.prof_descr=prof_descr;
end

% write to file:
nc=ncopen(fileOut,'write');
vars=ncvars(nc);
list_vars=intersect(vars,list_vars);
for ii=1:length(list_vars);
    varname=list_vars{ii};
    data=getfield(MITprof,varname);
    spval=ncgetFillVal(nc,varname);
    if isnumeric(data)
        if isempty(spval), 
            warning(['no FillVal for ' varname ': use of -9999 default value']);
            spval=double(-9999);
        end
        data(isnan(data))=spval;
        MITprof=setfield(MITprof,varname,data);
    end
    ncputvar(nc,varname,data);
end
ncclose(nc);



