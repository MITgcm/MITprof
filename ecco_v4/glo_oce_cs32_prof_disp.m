
dirGrid='./';
gcmfaces_global; grid_load(dirGrid,6,'compact');

test0=isempty(dir('profiles/output/some_TS_atlas.sortedInTime.nc'));
if test0;
  cd profiles
  mkdir input
  mkdir output
  copyfile ../*nc input/.
  MITprof_gcm2nc('./',{'some_TS_atlas.sortedInTime'});
  cd ..
end;

MITprof=MITprof_load('profiles/output/some_TS_atlas.sortedInTime_model.nc');

%quick and dirty plot of profiles locations
figureL;
ii=find(~isnan(MITprof.prof_T(:,1)));
plot(MITprof.prof_lon(ii),MITprof.prof_lat(ii),'b.');
hold on;
ii=find(~isnan(MITprof.prof_Testim(:,1)));
plot(MITprof.prof_lon(ii),MITprof.prof_lat(ii),'ro');

%quick and dirty plot of model data
figureL;
qwckplot(mygrid.Depth.*mygrid.mskC(:,:,1));
title('quickplotting');

%plot of both using m_map
figureL; m_map_gcmfaces(mygrid.Depth,0,{'myCaxis',[0 1e4]},{'myCmap','pink'});
ii=find(~isnan(MITprof.prof_T(:,1).*MITprof.prof_Testim(:,1)));
m_map_gcmfaces({'plot',MITprof.prof_lon(ii),MITprof.prof_lat(ii),'g.'},0,{'doHold',1});



