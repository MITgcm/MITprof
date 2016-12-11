function aviso_addinMITprof(ncfile)
% function aviso_addinMITprof(ncfile)
%   add MADT (Maps of Absolute Dynamic Topography) interpolated on profile
%   positions available in a MITprof netcdf file.
%   Use OpenDap, through the loaddap function.
%
%   fileIn: path (absolute or relative) to MITprof netcdf file
%   model is a string used to select the model to be loaded
%       'OCCA' : ECCOv4 grid + OCCA atlas
%       'SOSE59' : SOSE59 grid + atlas

gcmfaces_global; 

% process file name
[pathstr, name, ext] = fileparts(ncfile);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
if isempty(ext) | ~strcmp(ext,'.nc'), ext='.nc'; end
ncfile=[pathstr '/' name ext];

if isempty(which('loaddap')),
    error('loaddap toolbox must be installed');
end

% load profiles
nc=ncopen(ncfile,'write');
vars=ncvars(nc);
ncclose(nc);
if ismember('prof_madt_aviso',vars)
    M=MITprof_load(ncfile,{'prof_date','prof_lat','prof_lon','prof_madt_aviso'});
    madt=M.prof_madt_aviso;
else
    fillval=double(-9999);
    nc=ncopen(ncfile,'write');
    ncaddVar(nc,'prof_madt_aviso','double',{'iPROF'});
    ncaddAtt(nc,'prof_madt_aviso','long_name',['MADT AVISO']);
    ncaddAtt(nc,'prof_madt_aviso','units','m');
    ncaddAtt(nc,'prof_madt_aviso','missing_value',fillval);
    ncaddAtt(nc,'prof_madt_aviso','_FillValue',fillval);
    ncclose(nc);
    M=MITprof_load(ncfile,{'prof_date','prof_lat','prof_lon'});
    madt=M.prof_lat*NaN;
end

% load and write data
I=find(isnan(madt));
loc=[];

buffer=1000;
for kk=1:ceil(length(I)/buffer),
    
    if myenv.verbose;
        disp([num2str(kk) ' out of ' num2str(length(I)/buffer)]);
    end
    
    % extract data
    J=I((kk-1)*buffer+1:min([length(I),kk*buffer]));
    loc.lat=M.prof_lat(J);
    loc.lon=M.prof_lon(J);
    loc.time=M.prof_date(J);
    grid_aviso=aviso_get_grid;
    madt_temp=aviso_get_madt(loc,grid_aviso);
    
    % write fields
    madt(J)=madt_temp;
    M.prof_madt_aviso=madt;
    MITprof_write(ncfile,M,{'prof_madt_aviso'});
    
end

