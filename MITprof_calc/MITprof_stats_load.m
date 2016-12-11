function [MITprof]=MITprof_stats_load(dirData,listData,varCur,varargin);
%[MITprof]=MITprof_stats_load(dirData,listData,varCur,varargin);
%object: loads a series of MITprof files, and computes
%          normalized misfits for one variable
%input:  dirData is the data directory name
%        listData is the data file list (e.g. {'argo_in*'} or {'argo_in*','argo_at*'} )
%        varCur is 'T' or 'S'
%optional :
% EITHER normFactor (optional; double) is the normalization factor (1./prof_?weight by default)
%   OR   varSpec (optional; char) is e.g. 'prof_T' or 'prof_Testim'
%   OR   varSpec,true to remask varSpec according to e.g. prof_T & prof_Testim & prof_Tweight
%output: MITprof.prof is the normalized misfit
%note:   by assumption, all of the files in listData must share the same vertical grid

normFactor=[]; varSpec=''; doRemask=false;
if nargin>3;
    if isnumeric(varargin{1}); normFactor=varargin{1}; end;
    if ischar(varargin{1}); varSpec=varargin{1}; end;
end;
if nargin>4;
    if islogical(varargin{2}); doRemask=varargin{2}; end;
end;

useExtendedProfDepth=0;

%develop listData (that may include wildcards)
listData_bak=listData;
listData={};
for ii=1:length(listData_bak);
    tmp1=dir([dirData listData_bak{ii}]);
    for jj=1:length(tmp1);
        ii2=length(listData)+1;
        listData{ii2}=tmp1(jj).name;
    end;
end;
%avoid duplicates
listData=unique(listData);

%loop over files
for iFile=1:length(listData);
    fileData=dir([dirData listData{iFile}]);
    fileData=fileData.name;
    fprintf(['loading ' varCur ' from ' fileData '\n']);
    MITprofCur=MITprof_load([dirData fileData]);

    if isfield(MITprofCur,'prof_TeccoV4R2')&~isfield(MITprofCur,'prof_Testim');
       MITprofCur.prof_Testim=MITprofCur.prof_TeccoV4R2;
    end;
    if isfield(MITprofCur,'prof_SeccoV4R2')&~isfield(MITprofCur,'prof_Sestim');
       MITprofCur.prof_Sestim=MITprofCur.prof_SeccoV4R2;
    end;
    
    %fixes:
    if ~isfield(MITprofCur,['prof_' varCur]);
        tmp1=NaN*ones(MITprofCur.np,MITprofCur.nr);
        eval(['MITprofCur.prof_' varCur '=tmp1;']);
        eval(['MITprofCur.prof_' varCur 'estim=tmp1;']);
        eval(['MITprofCur.prof_' varCur 'weight=tmp1;']); 
        eval(['MITprofCur.prof_' varCur 'flag=[];']);
    end;
    
    if ~isfield(MITprofCur,['prof_' varCur 'weight']);
        eval(['MITprofCur.prof_' varCur 'weight=1+0*MITprofCur.prof_' varCur ';']);
    end;
    
    %replace weights with normFactor:
    if ~isempty(normFactor);
        eval(['tmp1=MITprofCur.prof_' varCur 'weight;']);
        tmp1(tmp1>0)=normFactor;
        eval(['MITprofCur.prof_' varCur 'weight=tmp1;']);
    end;
    
    %map variable of interest to MITprofCur.prof:
    if isempty(varSpec);        
        eval(['tmp1=(MITprofCur.prof_' varCur 'estim-MITprofCur.prof_' varCur ')' ...
            '.*sqrt(MITprofCur.prof_' varCur 'weight);']);
        tmp1(tmp1==0)=NaN;
    else;
        eval(['tmp1=MITprofCur.' varSpec ';']);
        if doRemask;
            eval(['tmp1(isnan(MITprofCur.prof_' varCur '))=NaN;']);
            eval(['tmp1(isnan(MITprofCur.prof_' varCur 'estim))=NaN;']);
            eval(['tmp1(isnan(MITprofCur.prof_' varCur 'weight))=NaN;']);
            eval(['tmp1(MITprofCur.prof_' varCur 'weight==0)=NaN;']);
        end;
    end;
    %                
    MITprofCur.prof=tmp1;
    
    %remove bad profiles:
    if isfield(MITprofCur,'prof_flag');
        tmp1=MITprofCur.prof_flag; tmp1=isnan(tmp1);
        MITprofCur.prof_flag(tmp1)=0;
        MITprofCur=MITprof_subset(MITprofCur,'flag',0);
        MITprofCur=rmfield(MITprofCur,'prof_flag');
    end;

    %remove un-needed variables:
    listKeep={'prof_YYYYMMDD','prof_HHMMSS','prof_lon','prof_lat',...
        'prof_depth','prof_date','prof_basin','prof_point','prof_descr',...
        'list_descr','nd','np','nr','prof'};
    listField=fieldnames(MITprofCur);
    for iField=1:length(listField);
        if sum(strcmp(listKeep,listField{iField}))==0;
            MITprofCur=rmfield(MITprofCur,listField{iField}); 
        end;
    end;
    
    %bug in 2013b? the following return wrong dates when SS='60'
    %MITprofCur.prof_date=datenum(num2str(MITprofCur.prof_YYYYMMDD*1e6+MITprofCur.prof_HHMMSS),'yyyymmddHHMMSS');
    %old:     ii=find(MITprofCur.prof_date<datenum(1992,1,1)|MITprofCur.prof_date>datenum(2008,12,27)); MITprofCur.prof(ii,:)=NaN;
    
    %extend prof_depth if needed:
    if iFile>1;
        prof_depth=union(MITprof.prof_depth,MITprofCur.prof_depth,'rows');
        for kk=1:2;
            if kk==1; tmpProf=MITprof; else; tmpProf=MITprofCur; end;
            if length(prof_depth)>length(tmpProf.prof_depth);
                tmp1=tmpProf.prof;
                tmp2=NaN*zeros(tmpProf.np,length(prof_depth));
                ii=NaN*length(tmpProf.prof_depth);
                for jj=1:length(tmpProf.prof_depth);
                    ii(jj)=find(prof_depth==tmpProf.prof_depth(jj));
                end;
                tmp2(:,ii)=tmpProf.prof;
                tmpProf.prof=tmp2;
                tmpProf.nr=length(prof_depth);
                tmpProf.prof_depth=prof_depth;
            end;
            if kk==1; MITprof=tmpProf; else; MITprofCur=tmpProf; end;
        end;
    end;
            
    if iFile==1;
        MITprof=MITprofCur;
    else;
        MITprof=MITprof_concat(MITprof,MITprofCur);
    end;
    clear MITprofCur;
end;


