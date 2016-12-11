
doLoad=1;
doGrid=1;
doPlot=1;

gcmfaces_global;%global variables and paths

%load insitu data (in MITprof format)
%------------------------------------

if doLoad;
dirIn='release1/MITprof/';
%load ctd data set (0-9000m)
ctd=MITprof_load([dirIn 'ctd_feb2013_model.nc']);
%load argo data subsets (rectricted to 0-2000m)
argo1=MITprof_load([dirIn 'argo_feb2013_1992_to_2007_model.nc']);
argo2=MITprof_load([dirIn 'argo_feb2013_2008_to_2010_model.nc']);
argo3=MITprof_load([dirIn 'argo_feb2013_2011_to_2012_model.nc']);
%concatenate (requires same vertical grid)
argo=MITprof_concat(argo1,argo2);
argo=MITprof_concat(argo,argo3);
end;

%define global grids (gcmfaces format)
%------------------------------------

if doGrid;
%ECCO grid (lat-lon-cap) should be in memory at this stage
mygrid_llc90=mygrid;

%define lat-lon grid
lon=[-179:2:179]; lat=[-89:2:89];
[lat,lon] = meshgrid([-89:2:89],[-179:2:179]);
%prepare mygrid for lat-lon with no mask
mygrid_latlon.nFaces=1;
mygrid_latlon.XC=gcmfaces({lon}); mygrid_latlon.YC=gcmfaces({lat});
mygrid_latlon.dirGrid='none';
mygrid_latlon.fileFormat='straight';
mygrid_latlon.ioSize=size(lon);
end;

%plot number of observations and mean date
%-----------------------------------------
if doPlot==1;

mygrid=mygrid_latlon;
global mytri; mytri=[]; gcmfaces_bindata;

figureL;
[tim,nobs]=gcmfaces_bindata(argo.prof_lon,argo.prof_lat,argo.prof_date);
tim0=datenum(1992,1,1); tim=1992+(tim./nobs-tim0)/365; tim(nobs==0)=NaN;
%
subplot(2,2,1); qwckplot(log10(nobs));
caxis([0 3]); colorbar('horiz'); title('argo log10(#obs)');
%
subplot(2,2,2); qwckplot(tim);
caxis([1992 2012]); colorbar('horiz'); title('argo mean date');
%
[tim,nobs]=gcmfaces_bindata(ctd.prof_lon,ctd.prof_lat,ctd.prof_date);
tim0=datenum(1992,1,1); tim=1992+(tim./nobs-tim0)/365; tim(nobs==0)=NaN;
%
subplot(2,2,3); qwckplot(log10(nobs)); 
caxis([0 3]); colorbar('horiz'); title('ctd log10(#obs)');
%
subplot(2,2,4); qwckplot(tim);
caxis([1992 2012]); colorbar('horiz'); title('ctd mean date');

end;%if doPlot==1;



%plot individual cruise / instrument tracks (as defined by descr flag)
%--------------------------------------------------------------------
if doPlot==2;

mygrid=mygrid_llc90;
global mytri; mytri=[]; gcmfaces_bindata;

%prof=MITprof_subset(ctd,'lat',[-70 -60],'lon',[-120 -90]);
prof=MITprof_subset(ctd,'lat',[-70 -60]);
list0=prof.list_descr;
list1='rgbmc';    

figureL; m_map_gcmfaces(mygrid.Depth,3); colormap('gray');
%for k=1:length(list0);
for k=length(list1):length(list1):length(list0);
  list1=circshift(list1,[0 -1]);
  prof=MITprof_subset(ctd,'descr',list0{k}); 
  jj=mod(k,length(list1)); if jj==0; jj=length(list1); end; 
  [tmp1,II]=sort(prof.prof_date);
  l=prof.prof_lon(II); L=prof.prof_lat(II);
  m_map_gcmfaces({'plot',l,L,[list1(jj) '.-']},3,{'doHold',1});
  pause(0.1); hold on; 
end;

end;%if doPlot==2;



%compile yearly, box averaged, anomaly from ecco
%-----------------------------------------------
if doPlot==3;

yearly_anom_argo=NaN*zeros(3,20);
yearly_anom_ctd=NaN*zeros(3,20);

%box definition:
l=[-180 180]; L=[-80 -50]; D=[100 200];
%l=[-120 -90]; L=[-80 -50]; D=[100 200];

for yy=1992:2011;
  d=[datenum(yy,0,0) datenum(yy+1,0,0)];
  %
  prof=MITprof_subset(ctd,'lon',l,'lat',L,'depth',D,'date',d);
  anom=prof.prof_T(:)-prof.prof_Testim(:); anom=anom(find(~isnan(anom)));
  if length(anom)>0;
    yearly_anom_ctd(1,yy-1991)=length(anom);
    yearly_anom_ctd(2,yy-1991)=mean(anom);
    yearly_anom_ctd(3,yy-1991)=median(anom);
  end;
  %
  prof=MITprof_subset(argo,'lon',l,'lat',L,'depth',D,'date',d);
  anom=prof.prof_T(:)-prof.prof_Testim(:); anom=anom(find(~isnan(anom)));
  if length(anom)>0;
    yearly_anom_argo(1,yy-1991)=length(anom);
    yearly_anom_argo(2,yy-1991)=mean(anom);
    yearly_anom_argo(3,yy-1991)=median(anom);
  end;
end;

figureL;
subplot(2,1,1);
plot(log10(yearly_anom_ctd(1,:)),'.-'); hold on;
plot(log10(yearly_anom_argo(1,:)),'r.-'); 
title('log10(#obs) for ctd (b) and argo (r)');
subplot(2,1,2);
plot(yearly_anom_ctd(2,:),'.-'); hold on;
plot(yearly_anom_argo(2,:),'r.-'); 
plot(yearly_anom_ctd(3,:),'c.-'); hold on;
plot(yearly_anom_argo(3,:),'m.-');       
title('mean/median anomaly for ctd (b/c) and argo (r/m)');

end;%if doPlot==3;

