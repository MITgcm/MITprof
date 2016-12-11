function [MITprofSub]=MITprof_subset(MITprof,varargin);
% [MITprofSub]=MITprof_subset(MITprof,'PropertyName',PropertyValue,...)
%   load a subset of profiles from MITprof into MITprofSub
%
%   if PropertyName = 'list' : PropertyValue contains the list of profiles
%   otherwise PropertyName = 'field' : selection on MITprof.prof_field,
%       range or unique value given in PropertyValue.
%   if PropertyName = 'list' is used, then it needs to be the first one.
%
%   [MITprofSub]=MITprof_subset(MITprof,'list',1:50);
%       returns the 50th first profiles in MITprof
%   [MITprofSub]=MITprof_subset(MITprof,'depth',[50 150]);
%       returns the subset of MITprof that has prof_depth>=50 and <150
%   [MITprofSub]=MITprof_subset(MITprof,'depth',[50 150],'descr',platformName);
%       ... and prof_descr=platformName;

MITprofSub=MITprof;
fldNames=fieldnames(MITprof);

nSub=(nargin-1)/2;
for iSub=1:nSub;
    if ~strcmp('list',varargin{(iSub-1)*2+1});
        eval(['prof_sub=MITprofSub.prof_' varargin{(iSub-1)*2+1} ';']);
        range_sub=varargin{(iSub-1)*2+2};
        if strcmp('descr',varargin{(iSub-1)*2+1});
            KK=find(strcmp(prof_sub,range_sub));
        elseif length(range_sub)==2 & range_sub(1)<range_sub(2);
            KK=find(prof_sub>=range_sub(1)&prof_sub<range_sub(2));
        elseif length(range_sub)==1;
            KK=find(prof_sub==range_sub);
        else
            error('MITprof_subset: wrong arguments');
        end;
    else;
        KK=varargin{(iSub-1)*2+2};
        prof_sub=[1:length(MITprofSub.prof_lon)]';
        if iSub~=1; error('''list'' subset should come first'); end;
    end;
    KK=reshape(KK,length(KK),1);
    
    %  [varargin{(iSub-1)*2+1} ' -- ' num2str(length(KK))]
    for iFld=1:length(fldNames);
        eval(['tmp1=MITprofSub.' fldNames{iFld} ';']);
        if strcmp('depth',varargin{(iSub-1)*2+1}) & strcmp(fldNames{iFld},'prof_depth');
            tmp1=tmp1(KK);
        elseif strcmp('depth',varargin{(iSub-1)*2+1});
            if size(tmp1,2)==length(MITprof.prof_depth); tmp1=tmp1(:,KK); end;
        elseif ~strcmp(fldNames{iFld},'prof_depth');;
            if size(tmp1,1)==size(prof_sub,1); tmp1=tmp1(KK,:); end;
        end;
        eval(['MITprofSub.' fldNames{iFld} '=tmp1;']);
    end;
        
    %add a couple things:
    %--------------------
    MITprofSub.np=length(MITprofSub.prof_lon);
    MITprofSub.nr=length(MITprofSub.prof_depth);
    MITprofSub.list_descr=unique(MITprofSub.prof_descr);
    MITprofSub.nd=length(MITprofSub.list_descr);
    
end;
