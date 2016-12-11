function grid_aviso=aviso_get_grid
% function [grid_aviso]=aviso_get_grid
%  load grid using loaddap interface to opendap website:
%  http://opendap.aviso.oceanobs.com/thredds/dodsC/dataset-duacs-dt-ref-global-merged-madt-h
%
% output: grid_aviso is a structure
%   grid_aviso.NbLatitudes : latitudes
%   grid_aviso.NbLongitudes : longitudes
%   grid_aviso.time : time (matlab julian day)
%   grid_aviso.Nlat : number of latitudes
%   grid_aviso.Nlon : number of longitudes
%   grid_aviso.Ntime : number of time samples

URL='http://opendap.aviso.oceanobs.com/thredds/dodsC/dataset-duacs-dt-ref-global-merged-madt-h?NbLatitudes[0:1:914],NbLongitudes[0:1:1079],time[0:1:911]';
grid_aviso=loaddap(URL);
if isempty(grid_aviso), error('access problem to aviso data with opendap'); end

grid_aviso.time=grid_aviso.time/24+datenum([1950 01 01 0 0 0]);
grid_aviso.Nlat=length(grid_aviso.NbLatitudes);
grid_aviso.Nlon=length(grid_aviso.NbLongitudes);
grid_aviso.Ntime=length(grid_aviso.time);
