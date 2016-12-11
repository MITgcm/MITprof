function []=profiles_prep_mygrid(fileData,dirIn,dirOut,ni,nj);
%[]=profiles_prep_mygrid(fileData,dirIn,dirOut,ni,nj);
%
%object:    add interpolation information for use by MITgcm/pkg/profiles
%
%input:     fileData is the name of the MITprof file to augment
%           dirIn is the corresponding direcroty name
%           dirOut is the directory name for the new (augmented) file
%           ni,nj is the MITgcm tile size
%
%output:    (none -- a file will be created)
%
%example:
% fileData='argo_indian.nc';
% dirIn='processed/';
% dirOut='mygrid/';
% ni=30; nj=30;
% profiles_prep_mygrid(fileData,dirIn,dirOut,ni,nj);

if strcmp(dirIn,dirOut);
    error('dirOut must differ from dirIn (to avoid loosing the original file)');
end;

gcmfaces_global;
if isempty(mygrid); grid_load; end;

fprintf(['grid being used:' mygrid.dirGrid '\n']);

%load dataset:
%-------------

p=MITprof_load([dirIn fileData]);

method='interp';
%method='bindata';

if strcmp(method,'interp');

%triangulate data and get grid locations:
%----------------------------------------

[interp,corners]=gcmfaces_interp_coeffs(p.prof_lon,p.prof_lat);

%prepare output fields:
%----------------------

list_in={'XC11','YC11','XCNINJ','YCNINJ'};
list_out={'XC11','YC11','XCNINJ','YCNINJ'};
for iF=1:length(list_out);
    eval(['p.prof_interp_' list_out{iF} '=corners.' list_in{iF} ';']);
end;

list_in={'i','j','XC','YC','w'};
list_out={'i','j','lon','lat','weights'};
for iF=1:length(list_out);
    eval(['p.prof_interp_' list_out{iF} '=interp.' list_in{iF} ';']);
end;

elseif strcmp(method,'bindata');

%triangulate data and get grid locations:
%----------------------------------------

loc_tile=gcmfaces_loc_tile(ni,nj,p.prof_lon,p.prof_lat);
list_in={'XC11','YC11','XCNINJ','YCNINJ','iTile','jTile','XC','YC'};
list_out={'XC11','YC11','XCNINJ','YCNINJ','i','j','lon','lat'};
for iF=1:length(list_out);
    eval(['p.prof_interp_' list_out{iF} '=loc_tile.' list_in{iF} ';']);
end;

%prepare output fields:
%----------------------

%use 1 as weight since we do nearest neighbor interp
p.prof_interp_weights=ones(size(loc_tile.XC)); list_out={list_out{:},'weights'};

else;
  error('unknown method')
end;

%write to file:
%--------------

test0=dir([dirOut fileData]);
if ~isempty(test0);
    test1=input(['\n\n !! ' dirOut fileData '\n !! already exists. Type 1 to erase it and proceed or 0 to stop.\n\n']);
    if test1;
        system(['rm -f ' dirOut fileData]);
    else;
        return;
    end;
end;

MITprof_write([dirOut fileData],p);


