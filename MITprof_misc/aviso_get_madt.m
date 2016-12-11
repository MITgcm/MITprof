function [madt]=aviso_get_madt(loc,grid_aviso)
% function [madt]=aviso_get_madt(loc,grid)
%  extract madt value (mapped absolute dynamic topography) at 1 location
%  linear interpolation in space and time at each location.
%
%  loc is a structure with three array of size (N,1) :
%   loc.lat : latitude [deg_north]
%   loc.lon : longitude [deg_east]
%   loc.time : date in Matlab julian date format
%
%  grid is the structure returned by aviso_get_grid
%
%  madt is the output array [unit: m], of size (N,1).
%

N=length(loc.lat);
madt=NaN*zeros(N,1);

loc.lon(loc.lon<0)=loc.lon(loc.lon<0)+360;

Itime=interp1(grid_aviso.time,(1:grid_aviso.Ntime)'-1,loc.time);
Ilon=interp1(grid_aviso.NbLongitudes,(1:grid_aviso.Nlon)'-1,loc.lon);
Ilat=interp1(grid_aviso.NbLatitudes,(1:grid_aviso.Nlat)'-1,loc.lat);

[X,Y,T]=meshgrid([0 1],[0 1],[0 1]);

for kk=1:N,
    
    if isnan(Itime(kk)*Ilon(kk)*Ilat(kk)), continue, end
    it=floor(Itime(kk));
    il=floor(Ilon(kk));
    iL=floor(Ilat(kk));
    URL=sprintf('http://opendap.aviso.oceanobs.com/thredds/dodsC/dataset-duacs-dt-ref-global-merged-madt-h?Grid_0001[%d:%d][%d:%d][%d:%d]',...
        it,it+1,il,il+1,iL,iL+1);
    a=loaddap(URL);data=a.Grid_0001;   % data.Grid_0001 : lon x lat x time
    if any(data.Grid_0001(:)>1e10), continue, end
    madt(kk)=interp3(X,Y,T,data.Grid_0001/100,Ilon(kk)-il,Ilat(kk)-iL,Itime(kk)-it);
    
end
