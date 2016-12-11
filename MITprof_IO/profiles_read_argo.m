function [varargout]=profile_read_argo(dataset,nf,m,varargin);
% read hydrographic data in the ARGO netcdf format
%  return the m-th profile from the nf-th file referenced in
%   dataset.fileInList.
%
% if m=0 :
%   dataset=profile_read_argo(dataset,nf,0);
%       dataset.nprofiles: number of profiles in the nf-th file
%       dataset.data_argo: argo data in a struct variable
%
% if m~=0 :
%   profileCur=profile_read_argo(dataset,nf,m);
%
% profileCur = (m-th profile of nf-th file)
%      pnum_txt: '5900841'
%           ymd: 20060101
%           hms: 3207
%           lat: -46.709
%           lon: 137.501
%         direc: 1
%             t: [1x115 single]
%             s: [1x115 single]
%             p: [1x115 single]
%         t_ERR: [1x115 single]
%         s_ERR: [1x115 single]
%     isBAD: 0
%

fileIn=[dataset.dirIn dataset.fileInList(nf).name];

if m==0; % return the number of profile.
        
    %get the number of profiles:
    list_var={'JULD','LATITUDE','LONGITUDE','DIRECTION','PLATFORM_NUMBER','DATA_MODE',...
              'JULD_QC','POSITION_QC','PRES_ADJUSTED_QC','PRES_QC',...
              'TEMP_ADJUSTED_QC','TEMP_QC','PSAL_ADJUSTED_QC','PSAL_QC'};
    argo_data=[];
    for ii=1:length(list_var),
        ncload(fileIn,list_var{ii});
        data=eval(list_var{ii});
        if ~isempty(data);
        nc=ncopen(fileIn);
        FillVal=ncgetFillVal(nc,list_var{ii});
        ncclose(nc);
        if ischar(FillVal),
            data(strcmp(data,FillVal))=' ';
        else
            data(data==FillVal)=NaN;
        end
        end
        argo_data=setfield(argo_data,list_var{ii},data);
    end

    list_var={'PRES_ADJUSTED','PRES','TEMP_ADJUSTED','TEMP','TEMP_ADJUSTED_ERROR',...
        'PSAL_ADJUSTED','PSAL','PSAL_ADJUSTED_ERROR'};
    for ii=1:length(list_var),
        ncload(fileIn,list_var{ii});
        data=double(eval(list_var{ii}));
        if ~isempty(data);
        nc=ncopen(fileIn);
        FillVal=ncgetFillVal(nc,list_var{ii});
        ncclose(nc);
        data(data==FillVal)=NaN;
        end;
        argo_data=setfield(argo_data,list_var{ii},data);
    end
    
    dataset.argo_data=argo_data;
    dataset.nprofiles = length(JULD);
    if isempty(dataset.argo_data.TEMP); 
      dataset.nprofiles=0;
      fprintf(['empty file:' dataset.fileInList(nf).name '\n']);
    end;

    if ~isfield(dataset,'greyList');
      if ~isempty(dir([dataset.dirIn '../../ar_greylist.txt']));
        fidgrey=fopen([dataset.dirIn '../../ar_greylist.txt'],'rt');
        tmp1=fgetl(fidgrey);
        greylist=[]; ii=0;
        while ~feof(fidgrey);
            tmp1=fgetl(fidgrey); tmp2=strfind(tmp1,',');
    
            cur_pnum=double(tmp1(1:tmp2(1)-1));
            cur_pnum=cur_pnum(find(cur_pnum~=0&cur_pnum~=32));
            cur_pnum=char(cur_pnum);
    
            date_ref=double(tmp1(tmp2(2)+1:tmp2(3)-1));
            date_ref=date_ref(find(date_ref~=0&date_ref~=32));
            date_ref=char(date_ref);
            date_ref=[str2num(date_ref(1:4)) str2num(date_ref(5:6)) str2num(date_ref(7:8)) 0 0 0];
    
            vnam=tmp1(tmp2(1)+1:tmp2(2)-1);
    
            ii=ii+1;
            greylist(ii).pnum=cur_pnum;
            greylist(ii).start=date_ref;
            greylist(ii).vnam=vnam;
        end;
        fclose(fidgrey);

        dataset.greyList.pnum={greylist(:).pnum};
        dataset.greyList.start={greylist(:).start};
        dataset.greyList.vnam={greylist(:).vnam};
      else;
        dataset.greyList.pnum=[];
        dataset.greyList.start=[];
        dataset.greyList.vnam=[];  
      end;
    end;

    varargout{1}=dataset;
    
else;%if m==0;
   
    % load data
    argo_data=dataset.argo_data;
    
    %date, position, etc
    juld=argo_data.JULD(m)+datenum(1950,1,1);
    [Y, M, D, H, MN, S] = datevec(juld);
    ymd=Y*1e4+M*1e2+D;
    hms=H*1e4+MN*1e2+S;
    
    lat=argo_data.LATITUDE(m);
    lon=argo_data.LONGITUDE(m); if lon < 0; lon=lon+360;end;
    
    direction=argo_data.DIRECTION(m);
    direc=0; 
    if(direction=='A');direc=1;end;
    if(direction=='D');direc=2;end
    
    pnum_txt=deblank(argo_data.PLATFORM_NUMBER(m,:));
    pnum_txt=pnum_txt(ismember(pnum_txt,'0123456789')); pnum=str2num(pnum_txt);
    if isempty(pnum_txt); pnum_txt='9999'; pnum=9999; disp(['no name for profile ' num2str(m)]); end;
    
    
    % pressure data
    
    p=argo_data.PRES_ADJUSTED(m,:);
    p_QC=argo_data.PRES_ADJUSTED_QC(m,:);
    if all(isnan(p)), p=argo_data.PRES(m,:); p_QC=argo_data.PRES_QC(m,:); end
    p_QC(isnan(p))='5';
    
    for n=1:length(p)-1; % doubles
        tmp1=find(p(n+1:end)==p(n)); p(n+tmp1)=NaN; p_QC(n+tmp1)='5';
    end

    % QC on position, date and pressure    
    isBAD=0;

    if ~ismember(argo_data.POSITION_QC(m),'1258'); isBAD=1; end;
    if ~ismember(argo_data.JULD_QC(m),'1258'); isBAD=1; end;

    tmp1=find(~ismember(p_QC,'1258'));
    if(length(tmp1)<=5);
        %get rid of these few bad points and keep the profile
        p(tmp1)=NaN;
    else;
        %flag the profile (will be masked in the main file)
        %but keep the bad points (to interp and be able to CHECK)
        isBAD=1;
    end;
    
    % temperature data
    %[num2str(m) ' in ' dataset.fileInList(nf).name]
    t=argo_data.TEMP_ADJUSTED(m,:);
    t_QC=argo_data.TEMP_ADJUSTED_QC(m,:);
    t_ERR=argo_data.TEMP_ADJUSTED_ERROR(m,:);
    t_ERR(isnan(t_ERR))=0;
    if all(isnan(t)), t=argo_data.TEMP(m,:); t_QC=argo_data.TEMP_QC(m,:); end

    %accomodate files that have no salinity
    if isempty(argo_data.PSAL);
      argo_data.PSAL=NaN*argo_data.TEMP;    
      argo_data.PSAL_QC=char(32*ones(size(argo_data.TEMP_ADJUSTED_QC)));
      argo_data.PSAL_ADJUSTED=NaN*argo_data.TEMP;
      argo_data.PSAL_ADJUSTED_ERROR=NaN*argo_data.TEMP;
      argo_data.PSAL_ADJUSTED_QC=char(32*ones(size(argo_data.TEMP_ADJUSTED_QC)));
    end;

    % salinity data
    s=argo_data.PSAL_ADJUSTED(m,:);
    s_QC=argo_data.PSAL_ADJUSTED_QC(m,:);
    s_ERR=argo_data.PSAL_ADJUSTED_ERROR(m,:);
    s_ERR(isnan(s_ERR))=0;
    if all(isnan(s)), s=argo_data.PSAL(m,:); s_QC=argo_data.PSAL_QC(m,:); end
    
    if isnan(t(1)); %this file does not contain temperature data...
        t=NaN*p; t_ERR=0*p;
    else;
        t(~ismember(t_QC,'1258'))=NaN;
    end;
    if isnan(s(1)); %this file does not contain salinity data...
        s=NaN*p; s_ERR=0*p;
    else;
        s(~ismember(s_QC,'1258'))=NaN;
    end;
    
    profileCur.pnum_txt=pnum_txt;
    profileCur.ymd=ymd; profileCur.hms=hms;
    profileCur.lat=lat; profileCur.lon=lon;
    profileCur.direc=direc;
    profileCur.T=t;
    profileCur.S=s;
    profileCur.p=p;
    profileCur.T_ERR=t_ERR;
    profileCur.S_ERR=s_ERR;
    profileCur.isBAD=isBAD;
    profileCur.DATA_MODE=argo_data.DATA_MODE(m);
    
    varargout = {profileCur};
    
end;



