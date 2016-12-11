function []=insitu_cost(doComp,varargin);
%object:        computes or displays cost function statistics
%input:         doComp states whether to compute & save (1) or load & display (0)
%optional must take the following form {'name',param1,param2,...} Active ones are
%               {'dirData',dirData} is the data subdirectory name ('profiles/output/' by default)
%               {'listData',data1,data2,...} where data1 e.g. is 'argo_indian.nc'
%               {'listVar',var1,var2} where var1 and var2 are 'T' and 'S'
%               {'years',year0,year1} to limit computation to [year0 year1] interval
%               {'dirMat',dirMat} where dirMat is the output subdirectory ('mat/' by default)
%               {'suffMat',suffMat} is the mat file suffix ('all' by default)
%               {'dirTex',dirTex} where dirTex is the tex directory ('tex/' by default)
%               {'nameTex',nameTex} is the tex file name ('myPlots' by default)
%               {'addToTex',addToTex} states whether (1) or not (0 default) to 
%                        augment an ongoing tex file (see write2tex.m, dirTex)
%
%example:         insitu_cost('./',1,{'listData','argo_in*'});

gcmfaces_global; 
global myparms; 

listVar={'T','S'}; 
listBas={'atlExt','pacExt','indExt','arct'};
if sum([90 1170]~=mygrid.ioSize)>0; listBas={}; end;
listBasTxt=''; for bb=1:length(listBas); listBasTxt=[listBasTxt ' ' listBas{bb} '*']; end;
%shorter test case: listData={'argo_in*'}; listVar={'T'};
dirData='/profiles/output/';
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
       warning('inputCheck:insitu_cost',...
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
  listData=dir([dirMat 'profiles/output/*.nc'])
  listData={listData(:).name};
  for ff=1:length(listData); listData{ff}=[listData{ff}(1:end-3) '*']; end;
end;

if doComp;

%time limits:
date0=datenum(year0,1,1); date1=datenum(year1,12,31);

for vv=1:length(listVar);
    varCur=listVar{vv};
   
    %get the cost square root:
    [MITprof]=MITprof_stats_load([dirData],listData,varCur);
    if ~isfield(MITprof,'prof_point');
      loc_tile=gcmfaces_loc_tile(90,90,MITprof.prof_lon,MITprof.prof_lat);
      MITprof.prof_point=loc_tile.point;
    end;
    %mask out values that are not in year range:
    ii=find(MITprof.prof_date<date0|MITprof.prof_date>date1);
    MITprof.prof(ii,:)=NaN;
    
    %mean and median:
    costCur=[nanmean(MITprof.prof(:).^2) nanmedian(MITprof.prof(:).^2)];
    fprintf('mean cost for %s: %0.3g (median: %0.3g) \n',varCur,costCur);
    eval(['costAve' varCur '.mean=costCur(1);']);
    eval(['costAve' varCur '.median=costCur(2);']);
    
    %depth/time mean cost:
    tmp_date=(MITprof.prof_date-date0)/365;
%    [x,y,z,n]=MITprof_stats(MITprof.prof_depth,MITprof.prof_depth,...
    [x,y,z,n]=MITprof_stats(MITprof.prof_depth,[0:200:1000 1500:500:6000],...
        tmp_date,[0:1/4:1+(year1-year0)],'mean',MITprof.prof.^2);
    z(n==0)=NaN; n(n==0)=NaN;
    eval(['depthTimeCost' varCur '.x=x;']); eval(['depthTimeCost' varCur '.y=y;']);
    eval(['depthTimeCost' varCur '.z=z;']); eval(['depthTimeCost' varCur '.n=n;']);
    
    %latitudinal distribution:
    [x,y,z,n]=MITprof_stats(MITprof.prof_lat,[-90:5:90],MITprof.prof,[-5:0.25:5]);
    z(n==0)=NaN; n(n==0)=NaN;
    eval(['misfitDistrib' varCur '.x=x;']); eval(['misfitDistrib' varCur '.y=y;']);
    eval(['misfitDistrib' varCur '.z=z;']); eval(['misfitDistrib' varCur '.n=n;']);

    %upper ocean temporal distribution
    for bb=1:length(listBas); 
    for ll=1:3;
      bbb=listBas{bb};
      if ll==1;     Lmin=-90; Lmax=-25; txt=[bbb '_90S25S_misDis' varCur];
      elseif ll==2; Lmin=-25; Lmax=25; txt=[bbb '_25S25N_misDis' varCur];
      elseif ll==3; Lmin=25; Lmax=90; txt=[bbb '_25N90N_misDis' varCur];
      end;
      msk=v4_basin(bbb);
      msk(mygrid.YC<Lmin|mygrid.YC>Lmax)=0;
      %
      msk=convert2array(msk);
      MITprof.prof_msk=msk(MITprof.prof_point);     
      MITprofSub=MITprof_subset(MITprof,'msk',1,'depth',[0 700]);      
      %
      tmp_date=(MITprofSub.prof_date-date0)/365;
      [x,y,z,n]=MITprof_stats(tmp_date,[0:1/4:1+(year1-year0)],MITprofSub.prof,[-5:0.25:5]);
      z(n==0)=NaN; n(n==0)=NaN;
      eval([txt '.x=x;']); eval([txt '.y=y;']);
      eval([txt '.z=z;']); eval([txt '.n=n;']);
    end;
    end;

end;

if ~isdir([dirMat 'cost/']); mkdir([dirMat 'cost/']); end;
eval(['save ' dirMat 'cost/insitu_cost' suffMat '.mat costAve* misfitDistrib* depthTimeCost* year* ' ...
      'listData listVar listBas ' listBasTxt ';']);

else;%display result

if isdir([dirMat 'cost/']); dirMat=[dirMat 'cost/']; end;

eval(['load ' dirMat 'insitu_cost' suffMat '.mat;']);

figureL;

for vv=1:length(listVar);
    varCur=listVar{vv};

    eval(['costCur=[costAve' varCur '.mean costAve' varCur '.median];']);

    eval(['x=depthTimeCost' varCur '.x;']); eval(['y=depthTimeCost' varCur '.y;']);
    eval(['z=depthTimeCost' varCur '.z;']); eval(['n=depthTimeCost' varCur '.n;']);
    z(n<1e2)=NaN; y=y+year0-1;
    subplot(2,length(listVar),vv); depthStretchPlot('pcolor',{y,x,z},[0:200:1000 1500:500:6000],[0 1000 4000]);
    caxis([0 8]); shading flat; colorbar; ylabel('depth (in m)');
    title(sprintf('mean cost for %s: %0.3g (median: %0.3g)',varCur,costCur));

    %latitudinal distribution:
    eval(['x=misfitDistrib' varCur '.x;']); eval(['y=misfitDistrib' varCur '.y;']);
    eval(['z=misfitDistrib' varCur '.z;']); eval(['n=misfitDistrib' varCur '.n;']);
    tmp1=(nansum(n,2)>1e4)*ones(1,size(n,2)); z(tmp1==0)=NaN;
    subplot(2,length(listVar),vv+length(listVar)); contourf(x,y,z,[0:0.05:0.5]); grid on;
    caxis([0 0.5]); colorbar; ylabel('normalized misfit'); xlabel('latitude'); title('pdf');

end;

myCaption={'Cost function (top) for in situ profiles, as a function of depth and time. ',...
        'Distribution of normalized misfits (bottom) as a function of latitude. For T (left) and S (right).'};
if addToTex; write2tex([dirTex '/' nameTex '.tex'],2,myCaption,gcf); end;

if ~isempty(listBas);

ii=0;
ii=ii+1; listPanels(ii).bas='atlExt'; listPanels(ii).ll=3;
ii=ii+1; listPanels(ii).bas='pacExt'; listPanels(ii).ll=3;
ii=ii+1; listPanels(ii).bas='arct'; listPanels(ii).ll=3;
ii=ii+1; listPanels(ii).bas='atlExt'; listPanels(ii).ll=2;
ii=ii+1; listPanels(ii).bas='pacExt'; listPanels(ii).ll=2;
ii=ii+1; listPanels(ii).bas='indExt'; listPanels(ii).ll=2;
ii=ii+1; listPanels(ii).bas='atlExt'; listPanels(ii).ll=1;
ii=ii+1; listPanels(ii).bas='pacExt'; listPanels(ii).ll=1;
ii=ii+1; listPanels(ii).bas='indExt'; listPanels(ii).ll=1;

for vv=1:length(listVar);
  varCur=listVar{vv};
  figureL;
  for ii=1:9;
      bbb=listPanels(ii).bas; ll=listPanels(ii).ll;
      if ll==1;     Lmin=-90; Lmax=-25; txt=[bbb '_90S25S_misDis' varCur];
      elseif ll==2; Lmin=-25; Lmax=25; txt=[bbb '_25S25N_misDis' varCur];
      elseif ll==3; Lmin=25; Lmax=90; txt=[bbb '_25N90N_misDis' varCur];
      end;

    eval(['x=' txt '.x;']); eval(['y=' txt '.y;']);
    eval(['z=' txt '.z;']); eval(['n=' txt '.n;']);
    x=x+year0-1;
    tmp1=(nansum(n,2)>1e4)*ones(1,size(n,2)); z(tmp1==0)=NaN;
    subplot(3,3,ii); contourf(x,y,z,[0:0.05:0.5]); grid on;
    caxis([0 0.5]); colorbar; title(txt,'Interpreter','none');
    %title([txt ', normalized misfit pdf'],'Interpreter','none');
    if mod(ii,3)==1; ylabel('normalized misfit'); end;
    %if ii<=6; set(gca,'XTick',[]); end;
  end;

myCaption={'Distribution of normalized misfits per basin (panel) as ',...
        'a function of latitude, for ',varCur};
if addToTex; write2tex([dirTex '/' nameTex '.tex'],2,myCaption,gcf); end;

end;

end;

end;


