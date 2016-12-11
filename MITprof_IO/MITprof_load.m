function [MITprof]=MITprof_load(fileIn,varargin);
%function: 	MITprof_load
%object:	read netcdf data files in the "MIT format"
%author:	Gael Forget (gforget@mit.edu)
%date:		june 21th, 2006
%
%usage:		[MITprof]=MITprof_load(fileIn);
%               ---> loads full data set
%           [MITprof]=MITprof_load(fileIn,list_vars);
%               ---> loads only the files listed in list_vars cell
%               array (e.g. list_vars={'prof_T','prof_Tweight'})
%               plus the one dimensional information (prof_lon etc.)
%
%note:		this does the same as MITprof_read, but
%   		- replaces missing values with NaN
%   		- adds a couple fields: np, nr, nd, list_descr
%   		- replaces prof_descr with a cell form
%
%inputs:	fileIn		data file name
%           list_vars   variables list (optional)
%
%outputs:	MITprof	structure containing the various fields/vectors



% check that file exists and add prefix and suffix if necessary
[pathstr, name, ext] = fileparts(fileIn);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
if isempty(ext) | ~strcmp(ext,'.nc'), ext='.nc'; end
fileIn=[pathstr '/' name ext];
if ~exist(fileIn,'file'), error([fileIn ' : file not found']); end

% load data using the low-level function MITprof_read
[MITprof]=MITprof_read(fileIn,varargin{:});

% replace missing_values with NaNs
fldNames=fieldnames(MITprof);
fldNames=setdiff(fldNames,{'prof_depth','depth'}); % no NaNs in prof_depth
fldNames=setdiff(fldNames,{'prof_date','prof_YYYYMMDD','prof_HHMMSS'});
if size(fldNames,2)==1; fldNames=fldNames'; end;

for ii=1:length(fldNames);
    fld=getfield(MITprof,fldNames{ii});
    if ~isempty(fld)
        f = ncopen(fileIn, 'nowrite');
        varname=fldNames{ii};
        spval=ncgetFillVal(f,varname);
        if ~isempty(spval);
            fld(fld==spval)=NaN;
            MITprof=setfield(MITprof,fldNames{ii},fld);
        end;
        ncclose(f);
    end
end;

% missing values for prof_date
if isfield(MITprof,'prof_date'),
    MITprof.prof_date( isnan(MITprof.prof_YYYYMMDD) )=NaN;
end

%quick fix when date/lon/lat is NaN:
%-----------------------------------
ii=find(isnan(MITprof.prof_lon.*MITprof.prof_YYYYMMDD.*MITprof.prof_HHMMSS.*MITprof.prof_lat));
MITprof.prof_lon(ii)=0; MITprof.prof_lat(ii)=-90; MITprof.prof_YYYYMMDD(ii)=19000101; MITprof.prof_HHMMSS(ii)=000000;

%convert prof_descr into a cell array:
%----------------------------------
if isfield(MITprof,'prof_descr')
    MITprof.prof_descr=cellstr(MITprof.prof_descr);
    MITprof.list_descr=unique(MITprof.prof_descr);
    MITprof.nd=length(MITprof.list_descr);
end

%add a couple things:
%--------------------
MITprof.np=length(MITprof.prof_lon);
MITprof.nr=length(MITprof.prof_depth);

