
doPart1=0;
doDisplay=1;
doPlatformCheck=1;

if doPart1;
    
    %load paths and grid:
    %--------------------
    gcmfaces_global; grid_load;
    
    %load data set:
    %--------------
    
    dirData='/Users/gforget/mywork/projects_inprogress/ecco_v4/costs/insitu/nc/';
%     dirData='/Users/gforget/mywork/projects_inprogress/ecco_v4/costs/insitu/iter3/';
%     fileData='seals_MITprof_latest.nc';
%     fileData='argo_pacific_MITprof_latest.nc';
    fileData='argo_atlantic_MITprof_latest.nc';
%     fileData='argo_indian_MITprof_latest.nc';

    
    MITprof=MITprof_load([dirData fileData]);
    
    %assign nameData:
    %----------------
    
    ii=strfind(fileData,'_MITprof_latest.nc');
    if ~isempty(ii);
        nameData=fileData(1:ii-1);
    else;
        ii=strfind(fileData,'_MITprof.nc');
        if ~isempty(ii);
            nameData=fileData(1:ii-1);
        else;
            ii=strfind(fileData,'.nc');
            nameData=fileData(1:ii-1);
        end;
    end;
    
    eval(['MITprof_' nameData '=MITprof;']);
    
    %get platforms list:
    %-------------------
    
    prof_descrInd={}; prof_countInd=[];
    prof_lonInd=[]; prof_latInd=[]; prof_dateInd=[];
    
    npInd=0;
    for pp=1:MITprof.np;
        test0=isempty(find(strcmp(prof_descrInd,MITprof.prof_descr{pp})));
        if test0;
            %MITprof.prof_descr{pp}
            npInd=npInd+1; prof_descrInd{npInd}=MITprof.prof_descr{pp};
            test1=find(strcmp(prof_descrInd{npInd},MITprof.prof_descr));
            prof_countInd=[prof_countInd length(test1)];
            prof_lonInd=[prof_lonInd median(MITprof.prof_lon(test1))];
            prof_latInd=[prof_latInd median(MITprof.prof_lat(test1))];
            prof_dateInd=[prof_dateInd median(MITprof.prof_date(test1))];
        end;
    end;
    
    [prof_countInd,ii]=sort(prof_countInd,'descend');
    prof_descrInd=prof_descrInd(ii); prof_lonInd=prof_lonInd(ii);
    prof_latInd=prof_latInd(ii); prof_dateInd=prof_dateInd(ii);
    
    %store stats to structure:
    %-------------------------
    
    eval(['platform_stats_' nameData '.prof_descrInd=prof_descrInd;']);
    eval(['platform_stats_' nameData '.prof_countInd=prof_countInd;']);
    eval(['platform_stats_' nameData '.prof_lonInd=prof_lonInd;']);
    eval(['platform_stats_' nameData '.prof_latInd=prof_latInd;']);
    eval(['platform_stats_' nameData '.prof_dateInd=prof_dateInd;']);
    
end;

%display all platforms tracks:
%-----------------------------

if doDisplay>1;
    cols='krymbw';
    
    figure; set(gcf,'Units','Normalized','Position',[0.1 0.3 0.4 0.6]);
    [X,Y,FLD]=convert2pcol(mygrid.XC,mygrid.YC,mygrid.mskC); pcolor(X,Y,FLD);
    axis([-180 180 -90 90]); shading flat; xlabel('longitude'); ylabel('latitude');
    
    for ppInd=1:npInd;
        ii=circshift([1:length(cols)],[0 ppInd-1]); ii=ii(1); cc=cols(ii);
        jj=find(strcmp(MITprof.prof_descr,prof_descrInd{ppInd}));
        if length(jj)>20;
            hold on; plot(MITprof.prof_lon(jj),MITprof.prof_lat(jj),[cc '.']);
            title(prof_descrInd{ppInd}); pause(0.01);
        end;
    end;
end;%if doDisplay>0;

%refined analysis of a platform's data:
%--------------------------------------

if doPlatformCheck;
    for ii=51:250:2290;
        MITprofSub=MITprof_subset(MITprof,'descr',prof_descrInd{ii});
        if doDisplay>0;
            %             figure; set(gcf,'Units','Normalized','Position',[0.1 0.1 0.8 0.8]);
            figure; set(gcf,'Units','Normalized','Position',[-0.45 0.1 0.4 0.8]);
            subplot(3,1,1);
            [X,Y,FLD]=convert2pcol(mygrid.XC,mygrid.YC,mygrid.mskC); pcolor(X,Y,FLD);
            axis([-180 180 -90 90]); shading flat; xlabel('longitude'); ylabel('latitude');
            hold on; plot(MITprofSub.prof_lon,MITprofSub.prof_lat,'k.');
            ccT=prctile(MITprofSub.prof_T(:),[5 95]); ccS=prctile(MITprofSub.prof_S(:),[5 95]); if isnan(ccS(1)); ccS=[34 36]; end;
            subplot(3,2,3); imagescnan(MITprofSub.prof_T'); caxis(ccT); colorbar; title('T obs');
            subplot(3,2,4); imagescnan(MITprofSub.prof_S'); caxis(ccS); colorbar; title('S obs');
            subplot(3,2,5); imagescnan(MITprofSub.prof_Testim'); caxis(ccT); colorbar; title('T estim');
            subplot(3,2,6); imagescnan(MITprofSub.prof_Sestim'); caxis(ccS); colorbar; title('S estim');
            %pause;
        end;
        
        MITprofSub=MITprof_subset(MITprofSub,'depth',[50 150]);
        misfT=(MITprofSub.prof_T-MITprofSub.prof_Testim).*sqrt(MITprofSub.prof_Tweight); misfT=misfT(find(~isnan(misfT)&misfT~=0));
        misfS=(MITprofSub.prof_S-MITprofSub.prof_Sestim).*sqrt(MITprofSub.prof_Sweight); misfS=misfS(find(~isnan(misfS)&misfS~=0));
        if doDisplay>0;
            %             figure; set(gcf,'Units','Normalized','Position',[0.1 0.1 0.8 0.8]);
            figure; set(gcf,'Units','Normalized','Position',[-0.45 0.1 0.4 0.8]);
            subplot(2,2,1);
            [X,Y,FLD]=convert2pcol(mygrid.XC,mygrid.YC,mygrid.mskC); pcolor(X,Y,FLD);
            axis([-180 180 -90 90]); shading flat; xlabel('longitude'); ylabel('latitude');
            hold on; plot(MITprofSub.prof_lon,MITprofSub.prof_lat,'k.');
            subplot(2,2,2);
            plot(MITprofSub.prof_T,MITprofSub.prof_S,'bx'); hold on; xlabel('T'); ylabel('S');
            plot(MITprofSub.prof_Testim,MITprofSub.prof_Sestim,'rx'); title('blue: obs red: estim');
            subplot(2,2,3); hist(misfT(find(~isnan(misfT))),[-8:0.25:8]);
            aa=axis; aa(1:2)=[-1 1]*10; axis(aa); title('T normalized misfit');
            subplot(2,2,4); hist(misfS(find(~isnan(misfS))),[-8:0.25:8]);
            aa=axis; aa(1:2)=[-1 1]*10; axis(aa); title('S normalized misfit');
            %pause;
        end;
        
%         close; close;
        
    end;
end;%if doPlatformCheck;


