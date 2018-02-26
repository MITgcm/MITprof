
doLoad=1;
method=1;

if doLoad==1;

%1) load argo itself
%-------------------
dirArgo='processed_depth/';
suff='_feb2018';

%list files
listArgo={}; nmArgo='*nc'; sbdrArgo=dir(dirArgo);
    for ii=1:length(sbdrArgo);
      if length(sbdrArgo(ii).name)==4;
      tmp1=dir([dirArgo sbdrArgo(ii).name '/' nmArgo]);
      if ~isempty(tmp1);
        nn=length(listArgo);
        for kk=1:length(tmp1);
          nn=nn+1;
          listArgo{nn}=[sbdrArgo(ii).name '/' tmp1(kk).name];
        end;
      end;
      end;%if length(sbdrArgo(ii).name)==4;
    end;
%concatenate
for iArgo=1:length(listArgo);
    fileArgo=listArgo{iArgo}
    argoTmp=MITprof_load([dirArgo fileArgo]);
    if iArgo==1; argo=argoTmp; else; argo=MITprof_concat(argo,argoTmp); end;
end;

clear argoTmp;

end;%if doLoad

if method==1;
%2) split by years (with limit on global np)
%-----------------

%note: the # of profiles per tile does not seem like a limiting factor

%map_tile=gcmfaces_loc_tile(30,30);
%tmp1=convert2array(map_tile);
%prof_tile=tmp1(argo.prof_point);
%num_tile=hist(prof_tile,[1:max(prof_tile)]);

YY=[2016:2017];
num_year=hist(argo.prof_YYYYMMDD,YY*1e4);

num_max=350000; 
num_set=[]; YY_set={};
num_tmp=0; YY_tmp=[];
for yy=YY;
  num_tmp=num_tmp+num_year(yy-YY(1)+1);
  YY_tmp=[YY_tmp;yy];
  if num_tmp>=num_max;
    YY_set={YY_set{:},YY_tmp(1:end-1)};
    num_tmp=num_tmp-num_year(yy-YY(1)+1);
    num_set=[num_set num_tmp];
    YY_tmp=yy;
    num_tmp=num_year(yy-YY(1)+1);
  end;
end;
YY_set={YY_set{:},YY_tmp};
num_set=[num_set num_tmp];

prof_set=NaN*argo.prof_lon;
for ii=1:length(YY_set);
  t0=1e4*YY_set{ii}(1);
  t1=1e4*(YY_set{ii}(end)+1);
  prof_set(argo.prof_YYYYMMDD>=t0&argo.prof_YYYYMMDD<t1)=ii;
end;
argo.prof_set=prof_set;


%3) write to disk
%-----------------------
for ii=1:length(YY_set);
  nameTmp=['argo' suff '_set' num2str(ii) '.nc']
  argoTmp=MITprof_subset(argo,'set',ii);
  argoTmp=rmfield(argoTmp,'prof_set');
  %
  [tmp1,jj]=sort(argoTmp.prof_date);
  tmp2=fieldnames(argoTmp);
  argoTmp2=[];
  argoTmp2.np=argoTmp.np; argoTmp2.nr=argoTmp.nr;
  argoTmp2.nd=argoTmp.nd; argoTmp2.list_descr=argoTmp.list_descr;
  argoTmp2.prof_depth=argoTmp.prof_depth;
  for kk=1:length(tmp2);
    tmp3=getfield(argoTmp,tmp2{kk});
    if length(tmp3)==argoTmp.np;
      tmp3=tmp3(jj,:);
      argoTmp2=setfield(argoTmp2,tmp2{kk},tmp3);
    end;
  end;
  %
  keyboard;
  MITprof_write([dirArgo nameTmp],argoTmp2);
end;

end;

if method==-1;
%2) split up instruments
%-----------------------

%sum of the # of profiles to each instrument
instN=zeros(argo.nd,1);
for ii=1:argo.nd;
instN(ii)=sum(strcmp(argo.prof_descr,argo.list_descr{ii}));
end;
cumN=cumsum(instN);
%last instrument of each group
II=[]; NN=1.e5;
while NN<cumN(end);
II=[II;max(find(cumN<=NN))]; NN=NN+1.e5;
end;
II=[II;argo.nd];
%map to a prof_msk variable
prof_msk=NaN*ones(argo.np,1);
for ii=1:argo.nd;
kk=find(strcmp(argo.prof_descr,argo.list_descr{ii}));
nn=length(find(II<=ii))+1;
prof_msk(kk)=nn;
end;
argo.prof_msk=prof_msk;

%3) write to disk
%-----------------------
for ii=1:length(II);
argoTmp=MITprof_subset(argo,'msk',ii);
nameTmp=[dirArgo 'argo' suff '_set' num2str(ii) '.nc'];
MITprof_write(nameTmp,argoTmp);
end;

end;%if method==-1;

