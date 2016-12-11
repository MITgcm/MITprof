%function: 	MITprof_read
%object:	read netcdf data files in the "MIT format". Low-level function.
%                use MITprof_load instead to load data from a MITprof
%                netcdf file.
%author:	Gael Forget (gforget@mit.edu)
%date:		june 21th, 2006
%
%usage:	   [MITprof]=MITprof_read(fileIn); 
%		---> loads full data set
%          [MITprof]=MITprof_read(fileIn,list_vars); 
%               ---> loads only the files listed in list_vars cell
%               array (e.g. list_vars={'prof_T','prof_Tweight'}) 
%               plus the one dimensional information (prof_lon etc.)
%
%inputs:	fileIn          data file name
%           list_vars       variables list (optional)
%               if no list_vars is provided, all fields are loaded.
%
%outputs:	MITprof	structure containing the various fields/vectors

function [MITprof]=MITprof_read(fileIn,varargin);


% check that file exists, and open it
if ~exist(fileIn,'file'), error([fileIn ' : file not found']); end

% open netcdf
nc=ncopen(fileIn);
MITprof=[];

% build the list of variable to load
if nargin>1; list_vars=varargin{1};
else, list_vars=ncvars(nc); end
if isempty(list_vars), return, end
%list_vars=[{'prof_lon','prof_lat'} list_vars];
%if ismember('prof_date',list_vars), list_vars=[{'prof_YYYYMMDD','prof_HHMMSS'} list_vars]; end
[list,m]=unique(list_vars);
list_vars=list_vars(sort(m));

% is there only one profile?
one_profile=0;
data=ncgetvar(nc,'prof_lon');
if length(data)==1, one_profile=1; end

% load fields into MITprof struct
for ii=1:length(list_vars),
    data=ncgetvar(nc,list_vars{ii});
    if size(data,1)==1 & ~one_profile,
        data=reshape(data,length(data),1);
    end
    MITprof=setfield(MITprof,list_vars{ii},data);
end

% load depth vector separately (either in prof_depth or depth variable)
if ismember('prof_depth', list_vars)
    data=ncgetvar(nc,'prof_depth');
elseif ismember('depth', list_vars)
    data=ncgetvar(nc,'depth');
end
data=reshape(data,length(data),1);
MITprof=setfield(MITprof,'prof_depth',data);

% add field prof_date if not already in the nc file
if ismember('prof_date',list_vars) & ~isfield(MITprof,'prof_date');
    MITprof.prof_date=datenum(num2str(MITprof.prof_YYYYMMDD*1e6+MITprof.prof_HHMMSS),'yyyymmddHHMMSS');
end;

% add prof_YYYYMMDD and prof_HHMMSS if possible
if isfield(MITprof,'prof_date') & ~isfield(MITprof,'prof_YYYYMMDD');
    tmp1=datevec(MITprof.prof_date);
    MITprof.prof_YYYYMMDD=tmp1(:,1)*1e4+tmp1(:,2)*1e2+tmp1(:,3);
    MITprof.prof_HHMMSS=tmp1(:,4)*1e4+tmp1(:,5)*1e2+tmp1(:,6);
end;

% close file
ncclose(nc);

%make sure that lon is -180+180:
%-------------------------------
tmp_lon=MITprof.prof_lon;
tmp_lon(find(tmp_lon>180))=tmp_lon(find(tmp_lon>180))-360;
MITprof.prof_lon=tmp_lon;

%get rid of empty variables:
%---------------------------
fldNames=fieldnames(MITprof);
for iFld=1:length(fldNames);
    eval(['test0=isempty(MITprof.' fldNames{iFld} ');']);
    if test0; MITprof=rmfield(MITprof,fldNames{iFld}); end;
end;
