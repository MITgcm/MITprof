
%load time mean atlas to be turned into MITprof

dirGrid='grid/';
gcmfaces_global; grid_load(dirGrid,6,'compact');

dirAtlas='./';
T=read2memory([dirAtlas 'some_T_atlas.bin'],[32 192 50 12]);                                                  
S=read2memory([dirAtlas 'some_S_atlas.bin'],[32 192 50 12]);
T=mean(T,4); S=mean(S,4);
T=reshape(T,[32*192 50]); 
S=reshape(S,[32*192 50]);

lon=convert2gcmfaces(mygrid.XC); lon=reshape(lon,[32*192 1]);
lat=convert2gcmfaces(mygrid.YC); lat=reshape(lat,[32*192 1]);
msk=convert2gcmfaces(mygrid.mskC); msk=reshape(msk,[32*192 50]);
T=T.*msk; S=S.*msk;

ii=find(~isnan(msk(:,1))); T=T(ii,:);  S=S(ii,:); 
lon=lon(ii); lat=lat(ii); msk=msk(ii,:); 
descr='some time mean atlas';

%load sample data set

dirSample='./';
MITprof=MITprof_load([dirSample 'argo_indian.nc']);

%replace everything in it

MITprof=rmfield(MITprof,{'prof_basin','prof_point','prof_Terr','prof_Serr','prof_Tflag','prof_Sflag'});

MITprof.np=length(lon);
MITprof.nr=length(mygrid.RC);
MITprof.nd=length(descr);

MITprof.prof_depth=-mygrid.RC+1*(rand(MITprof.nr,1)-0.5);

MITprof.prof_date=datenum([1948 1 1 16 0 0])+6/24*(rand(MITprof.np,1)-0.5);
fprintf('sort by time and tile in a second version\n');
tmp1=datestr(MITprof.prof_date,30);
MITprof.prof_YYYYMMDD=str2num(tmp1(:,1:8));
MITprof.prof_HHMMSS=str2num(tmp1(:,10:15));

MITprof.prof_lon=lon+1*(rand(MITprof.np,1)-0.5);
MITprof.prof_lat=lat+1*(rand(MITprof.np,1)-0.5);

MITprof.prof_descr=repmat({descr},[MITprof.np 1]);
MITprof.list_descr={descr};

MITprof.prof_T=T; MITprof.prof_Testim=T;
MITprof.prof_S=S; MITprof.prof_Sestim=S;

tmp1=ones(MITprof.np,1)*nanstd(T,1);
MITprof.prof_Tweight=1./tmp1./tmp1;
MITprof.prof_Tweight(isnan(T))=0;

tmp1=ones(MITprof.np,1)*nanstd(S,1);
MITprof.prof_Sweight=1./tmp1./tmp1;
MITprof.prof_Sweight(isnan(S))=0;

%write to new file

file_out='some_TS_atlas.nc';
mkdir step1;
MITprof_write(['step1/' file_out],MITprof);

%add grid information
mkdir step2;
profiles_prep_mygrid(file_out,'step1/','step2/',16,16);

%second version that is sorted in time

[tmp1,ii]=sort(MITprof.prof_date);

MITprof.prof_date=MITprof.prof_date(ii);
MITprof.prof_YYYYMMDD=MITprof.prof_YYYYMMDD(ii);
MITprof.prof_HHMMSS=MITprof.prof_HHMMSS(ii);
MITprof.prof_lon=MITprof.prof_lon(ii);
MITprof.prof_lat=MITprof.prof_lat(ii);

MITprof.prof_T=MITprof.prof_T(ii,:);
MITprof.prof_Tweight=MITprof.prof_Tweight(ii,:);
MITprof.prof_Testim=MITprof.prof_Testim(ii,:);

MITprof.prof_S=MITprof.prof_S(ii,:);
MITprof.prof_Sweight=MITprof.prof_Sweight(ii,:);
MITprof.prof_Sestim=MITprof.prof_Sestim(ii,:);

file_out='some_TS_atlas.sortedInTime.nc';
MITprof_write(['step1/' file_out],MITprof);
profiles_prep_mygrid(file_out,'step1/','step2/',16,16);

