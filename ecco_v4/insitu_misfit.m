function []=insitu_misfit(doComp,varargin);
%object:        computes or displays cost function statistics
%input:         doComp states whether to compute & save (1) or load & display (0)
%optional must take the following form {'name',param1,param2,...} Active ones are
%               {'dirData',dirData} is the data directory name ('mat/profiles/output/' by default)
%               {'listData',data1,data2,...} where data1 e.g. is 'argo_indian.nc'
%               {'listVar',var1,var2} where var1 and var2 are 'T' and 'S'
%               {'years',year0,year1} to limit computation to [year0 year1] interval
%               {'dirMat',dirMat} where dirMat is the output directory ('mat/' by default)
%               {'suffMat',suffMat} is the mat file suffix ('all' by default)
%               {'dirTex',dirTex} where dirTex is the tex directory ('tex/' by default)
%               {'nameTex',nameTex} is the tex file name ('myPlots' by default)
%               {'addToTex',addToTex} states whether (1) or not (0 default) to 
%                       augment an ongoing tex file (see write2tex.m, dirTex)
%
%example:        insitu_misfit('./',1,{'listData','argo_in*'});

vecDepth=[[75 125];[250 350];[900 1100]];
vecCaxis=[[3 3 1];[0.5 0.5 0.2]];
%if nargin>6; vecCaxis=varargin{1}; else; vecCaxis=[]; end;

gcmfaces_global;
global myparms;

listVar={'T','S'}; 
%shorter test case: listData={'argo_in*'}; listVar={'T'};
dirData='mat/profiles/output/';
dirMat='mat/'; suffMat='_all';
dirTex='tex/'; addToTex=0; nameTex='myPlots';
%set more optional paramaters to user defined values
for ii=1:nargin-1;
   if strcmp(varargin{ii}{1},'listData'); listData={varargin{ii}{2:end}};
   elseif strcmp(varargin{ii}{1},'listVar'); listVar={varargin{ii}{2:end}};
   elseif strcmp(varargin{ii}{1},'years'); year0=varargin{ii}{2}; year1=varargin{ii}{3};
   elseif strcmp(varargin{ii}{1},'dirMat'); dirMat=varargin{ii}{2};
   elseif strcmp(varargin{ii}{1},'suffMat'); suffMat=['_' varargin{ii}{2}];
   elseif strcmp(varargin{ii}{1},'dirTex'); dirTex=varargin{ii}{2};
   elseif strcmp(varargin{ii}{1},'addToTex'); addToTex=varargin{ii}{2};
   elseif strcmp(varargin{ii}{1},'nameTex'); nameTex=varargin{ii}{2};
   elseif strcmp(varargin{ii}{1},'dirData'); dirData=varargin{ii}{2};
   else;
       warning('inputCheck:insitu_misfit',...
           ['unknown option ''' varargin{ii}{1} ''' was ignored']);
   end;
end;

if isempty(myparms)|isempty(mygrid);
  load([dirMat 'diags_grid_parms.mat']);
end;

if isempty(whos('year0'));
  year0=myparms.yearInAve(1); year1=myparms.yearInAve(2);
end;

if isempty(whos('listData'));
  listData=dir([dirMat 'profiles/output/*.nc']);
  listData={listData(:).name};
  for ff=1:length(listData); listData{ff}=[listData{ff}(1:end-3) '*']; end;
end;

if doComp;

%initialize delaunay triangulation:
gcmfaces_bindata;
%time limits:
date0=datenum(year0,1,1); date1=datenum(year1,12,31);
%number of levels:
nk=size(vecDepth,1);

for vv=1:length(listVar);
    varCur=listVar{vv};
    %get the misfits (here not normalized):
    [MITprof]=MITprof_stats_load(dirData,listData,varCur,1);
    %mask out values that are not in year range:
    ii=find(MITprof.prof_date<date0|MITprof.prof_date>date1);
    MITprof.prof(ii,:)=NaN;
    %misfit maps:
    for kkk=1:size(vecDepth,1);
        kk=find(MITprof.prof_depth>=vecDepth(kkk,1)&MITprof.prof_depth<=vecDepth(kkk,2));
        lon=MITprof.prof_lon; lat=MITprof.prof_lat; obs=nanmean(MITprof.prof(:,kk),2);
        ii=find(~isnan(obs)); lon=lon(ii); lat=lat(ii); obs=obs(ii);
        misfit_map=gcmfaces_bindata(lon,lat,obs);
        eval(['misfit_map_' varCur num2str(kkk) '=misfit_map;']);
    end;
end;

if ~isdir([dirMat 'cost/']); mkdir([dirMat 'cost/']); end;
eval(['save ' dirMat 'cost/insitu_misfit' suffMat '.mat misfit_map_* vecDepth  year* listData listVar;']);

else;

if isdir([dirMat 'cost/']); dirMat=[dirMat 'cost/']; end;

eval(['load ' dirMat 'insitu_misfit' suffMat '.mat;']);

nk=size(vecDepth,1);
figureL; 
for vv=1:length(listVar);
    varCur=listVar{vv};
    for kkk=1:size(vecDepth,1);
        eval(['misfit_map=misfit_map_' varCur num2str(kkk) ';']); 
        dep=mean(vecDepth(kkk,:));

        if isempty(vecCaxis); cc=3*sqrt(nanmean(misfit_map.^2)); else; cc=vecCaxis(vv,kkk); end;
        subplot(nk,length(listVar),vv+(kkk-1)*length(listVar));
        m_map_gcmfaces(misfit_map,1,{'myCaxis',[-1 1]*cc},{'myShading','flat'});
        title(sprintf('%s misfits at %dm   (%d to %d)',varCur,dep,year0,year1));
    end;
end;

myCaption={'Time mean misfit (model-data) for in situ profiles, ',...
         'at various depths (rows), for T (left; in K) and S (right; in psu).'};
if addToTex; write2tex([dirTex '/' nameTex '.tex'],2,myCaption,gcf); end;

end;



