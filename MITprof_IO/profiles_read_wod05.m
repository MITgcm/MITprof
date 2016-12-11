function [varargout]=profile_read_wod05(dataset,nf,m,varargin);
% read hydrographic data in the WOD05 csv format
%  return the m-th profile from the nf-th file referenced in
%   dataset.fileInList.
%
% if m=0 :
%  return the information on the nf-th file referenced in
%  dataset.fileInList.
%   dataset=profile_read_wod05(dataset,nf,0);
%       dataset.nprofiles: number of profiles in the nf-th file
%       dataset.index_prof: list of position number for each profile block
%
% if m~=0 :
%  return the m-th profile from the nf-th file referenced in
%  dataset.fileInList.
%   profileCur=profile_read_odv(dataset,nf,m);
%
% profileCur = 
%      pnum_txt: 'WOD-CTD//29-1103//4.'
%           ymd: 19900210
%           hms: 82659
%           lat: 40.94
%           lon: 2.6467
%         direc: 2
%         isBAD: 0
%             t: [1x998 double]
%             s: [1x998 double]
%             z: [1x998 double]
%         t_ERR: [1x998 double]
%         s_ERR: [1x998 double]

fileIn=[dataset.dirIn dataset.fileInList(nf).name];
instrType=dataset.subset(3:end);

if m==0;
    
    % return the number of profiles in the file
    % also build an index of first-line prosition of profiles: index_prof
    fid_cur=fopen(fileIn,'rt');
    prof_cur=0;index_prof=[];
    while ~feof(fid_cur);
        line_cur = fgetl(fid_cur);
        if ~isempty(findstr(line_cur,'NODC Cruise ID'));
            prof_cur=prof_cur+1;
            index_prof(end+1)=ftell(fid_cur)-length(line_cur)-1;
            %to jump over second possible occurence of NODC Cruise ID
            while isempty(findstr(line_cur,'END OF VARIABLES SECTION'));
                line_cur = fgetl(fid_cur);
            end;
        end;
    end;
    fclose(fid_cur);
    
    dataset.nprofiles=prof_cur;
    dataset.index_prof=index_prof;
    
    varargout(1) = {dataset};
    
    
else;%if m==0;
    
        
    % index_prof: position of beginning of each profile block in the .txt 
    index_prof=dataset.index_prof;

    fid_cur=fopen(fileIn,'rt');
    fseek(fid_cur,index_prof(m),'bof');
    data_cur=NaN*zeros(10000,3); %array that is used to store one profile
    
    line_cur = fgetl(fid_cur);
    while isempty(findstr(line_cur,'NODC Cruise ID'));
        line_cur = fgetl(fid_cur);
    end;
    tmp1=findstr(line_cur,',,');
    pnum_txt=['WOD-' instrType '//' deblank(line_cur(tmp1(1)+2:tmp1(2)-1))];
    
    probe_type='-1'; Time=12.0;
    lon=[]; lat=[]; Year=[]; Month=[]; Day=[];
    
    while isempty(findstr(line_cur,'VARIABLES'));
        line_cur = fgetl(fid_cur);
        var_cur=textscan(line_cur,'%s','delimiter',','); var_cur=var_cur{1};
        
        if ~isempty(findstr(cell2mat(var_cur(1)),'Latitude'));
            lat=str2num(cell2mat(var_cur(3)));
        end;
        if ~isempty(findstr(cell2mat(var_cur(1)),'Longitude'));
            lon=str2num(cell2mat(var_cur(3)));
        end;
        if ~isempty(findstr(cell2mat(var_cur(1)),'Year'));
            Year=str2num(cell2mat(var_cur(3)));
        end;
        if ~isempty(findstr(cell2mat(var_cur(1)),'Month'));
            Month=str2num(cell2mat(var_cur(3)));
        end;
        if ~isempty(findstr(cell2mat(var_cur(1)),'Day'));
            Day=str2num(cell2mat(var_cur(3)));
        end;
        if ~isempty(findstr(cell2mat(var_cur(1)),'Time'));
            Time=str2num(cell2mat(var_cur(3)));
        end;
        if ~isempty(findstr(cell2mat(var_cur(1)),'probe_type'));
            probe_type=cell2mat(var_cur(3));
        end;
        
    end;
    
    %case when necessary information missing: put dummy info
    if isempty(lon)|isempty(lat)|isempty(Year)|isempty(Month)|isempty(Day)
        lat=-89.9; lon=0.1; Year=1800; Month=1; Day=1;
    elseif Day==0;
        lat=-89.9; lon=0.1; Year=1800; Month=1; Day=1;
    end;
    
    if lon < 0; lon=lon+360;end;
    
    pnum_txt=[pnum_txt '//' deblank(probe_type)];
    
    var_cur=textscan(line_cur,'%s','delimiter',','); var_cur=var_cur{1};
    v_cur=[];
    for ii=1:length(var_cur);
        tmp1=cell2mat(var_cur(ii));
        if ~isempty(findstr(tmp1,'Depth')); v_cur=[v_cur; [1 ii]]; end;
        if ~isempty(findstr(tmp1,'Temperatur')); v_cur=[v_cur; [2 ii]]; end;
        if ~isempty(findstr(tmp1,'Salinity')); v_cur=[v_cur; [3 ii]]; end;
    end;
    line_cur = fgetl(fid_cur);
    line_cur = fgetl(fid_cur);
    
    data_tmp=cell2mat(textscan(line_cur,'%f','delimiter',',','treatAsEmpty',{'Prof-Flag'}));
    qc_cast=zeros(1,3);
    %get cast qc??
    qc_cast(v_cur(:,1))=data_tmp(v_cur(:,2)+1)';
    qc_cast=1*(qc_cast==2|qc_cast==3|qc_cast==9);
    %if ~isempty(find(qc_cast>0)); fprintf(['cast qc: ' num2str(qc_cast) ' for ' fileIn ' m=' num2str(m) '\n']); end;
    %
    
    data_cur(:)=NaN;
    line_cur = fgetl(fid_cur);
    count_cur=1;
    data_tmp=cell2mat(textscan(line_cur,'%f','delimiter',',','treatAsEmpty',{'---.---','**********'}));
    while ~isempty(data_tmp);
        %store data:
        data_cur(count_cur,v_cur(:,1))=data_tmp(v_cur(:,2))';
        %apply loc and global QC:
        qc_loc=zeros(1,3); qc_loc(v_cur(:,1))=data_tmp(v_cur(:,2)+1)';
        qc_bad=find(qc_loc(v_cur(:,1))>0|qc_cast(v_cur(:,1))>0);
        data_cur(count_cur,v_cur(qc_bad,1))=NaN;
        %read the next line:
        line_cur = fgetl(fid_cur);
        count_cur=count_cur+1;
        data_tmp=cell2mat(textscan(line_cur,'%f','delimiter',',','treatAsEmpty',{'---.---','**********'}));
    end
    
    fclose(fid_cur);
    
    z=data_cur(1:count_cur-1,1);
    t=data_cur(1:count_cur-1,2);
    s=data_cur(1:count_cur-1,3);
    t_ERR=zeros(size(t)); s_ERR=t_ERR; z_ERR=[];
    
    
    ymd=1e4*Year+1e2*Month+Day;
    tmp1=(Time-floor(Time))*3600;
    tmp2=floor(tmp1-floor(tmp1/60)*60);
    tmp1=floor(tmp1/60);
    hms=1e4*floor(Time)+1e2*tmp1+tmp2;
    direc=2;
    isBAD=0;
    
    profileCur.pnum_txt=pnum_txt;
    profileCur.ymd=ymd; profileCur.hms=hms;
    profileCur.lat=lat; profileCur.lon=lon;
    profileCur.direc=direc;
    profileCur.isBAD=isBAD;
    profileCur.T=t';
    profileCur.S=s';
    profileCur.depth=z';
    profileCur.T_ERR=t_ERR';
    profileCur.S_ERR=s_ERR';
    profileCur.depth_ERR=z_ERR';
    %by convention profileCur.z etc are line vectors
    
    varargout = {profileCur};
    
end;



