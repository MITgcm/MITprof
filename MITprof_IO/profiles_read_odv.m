function [varargout]=profile_read_odv(dataset,nf,m,varargin)
% read seal data in the odv spreadsheet format
%
% if m=0 :
%  return the information on the nf-th file referenced in
%  dataset.fileInList.
%   dataset=profile_read_odv(dataset,nf,0);
%       dataset.nprofiles: number of profiles in the nf-th file
%       dataset.Iprofile: index referencing the profile for each dataline
%
% if m~=0 :
%  return the m-th profile from the nf-th file referenced in
%  dataset.fileInList.
%   profileCur=profile_read_odv(dataset,nf,m);
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
%         isBAD: 0
%
% IMPORTANT: Use three global variables: pnum Date and Data.

global pnum Date Data

fileIn=[dataset.dirIn dataset.fileInList(nf).name];

if m==0;

    % return the number of profiles in the file
    % also build an index of first-line prosition of profiles: index_prof
    fid_cur=fopen(fileIn,'rt');
    nprofiles=0;index_prof=[];
    
    % jump comment line at the beginning
    line_cur = fgetl(fid_cur);
    while ~feof(fid_cur) & strcmp(line_cur(1:2),'//')
        line_cur = fgetl(fid_cur);
        continue
    end
    
    % analyse data description line
    I=[0 find(double(line_cur)==9) length(line_cur)+1];
    format=[];
    % column index for (in this order) :
    %   Cruise, Station, Date, Lon, Lat, Dep, Dep_qv, Temp,
    %   Temp_qv, Sal, Sal_qv
    for ii=1:length(I)-1,
        field=line_cur(I(ii)+1:I(ii+1)-1);
        field=field(1:min([6 length(field)]));
        switch field
            case 'Cruise'
                format(1)=ii;
            case 'Statio'
                format(2)=ii;
            case 'yyyy-m'
                format(3)=ii;
            case {'Longit'}
                format(4)=ii;
            case {'Latitu'}
                format(5)=ii;
            case {'Depth '}
                format([6 7])=[ii ii+1];
            case {'Temper'}
                format([8 9])=[ii ii+1];
            case {'Salini'}
                format([10 11])=[ii ii+1];
        end
    end
    
    % read end of the textfile
    nlines=0;nbuffer=100000;niter=0;
    while ~feof(fid_cur);
        niter=niter+1;
        data_odv=cell(length(format)-1,nbuffer);
        for ii=1:nbuffer,
            tline=fgets(fid_cur);
            nlines=nlines+1;
            I_sep=[0 find(double(tline)==9)];
            data_odv{1,ii}=[ tline(I_sep(format(1))+1:I_sep(format(1)+1)-1) '//' ...
                tline(I_sep(format(2))+1:I_sep(format(2)+1)-1) ];
            data_odv{2,ii}=tline(I_sep(format(3))+1:I_sep(format(3)+1)-1);
            for kk=4:length(format),
                I=I_sep(format(kk))+1:I_sep(format(kk)+1)-1;
                if length(I)>1,
                    data_odv{kk-1,ii}=tline(I);
                elseif isempty(I),
                    data_odv{kk-1,ii}='99999';
                else
                    val=tline(I);
                    if val==0,
                        data_odv{kk-1,ii}='99999';
                    else
                        data_odv{kk-1,ii}=val;
                    end
                end
            end
            if feof(fid_cur), break, end
        end
        data_odv=data_odv(:,1:ii);
        data=data_odv(3:length(format)-1,:);
        datanum=sscanf(sprintf('%s,',data{:}), '%g,');
        datanum(datanum==99999)=NaN;
        
        %no salinity case
        if dataset.inclS,
            datanum=reshape(datanum(:),8,ii);
        else
            datanum=reshape(datanum(:),6,ii);
        end

        fprintf('%d lines\n',nlines);
        if niter==1,
            pnum=data_odv(1,:);
            Date=data_odv(2,:);
            Data=datanum;
        else
            pnum=[pnum data_odv(1,:)];
            Date=[Date data_odv(2,:)];
            Data=[Data datanum];
        end
        
    end
    fclose(fid_cur);    

    % get rid of empty indicator string
    [pnum_txt_list,Iprof]=unique(pnum);
    if size(Iprof,2)==1; Iprof=Iprof'; end;
    for kk=1:length(pnum),
        if strcmp(pnum_txt_list{kk},'//'),
            pnum_txt_list=pnum_txt_list(setdiff(1:length(pnum_txt_list),kk));
            Iprof(kk)=[];
            break
        end
    end
    
    % sort index of profile
    [Iprof_sort,J]=sort(Iprof);
    pnum_txt_sort=pnum_txt_list(J);
    
    % write index of profile
    Iprof_sort=[Iprof_sort nlines+1];
    Iprofile=zeros(nlines,1);
    for kk=1:length(Iprof_sort)-1,
        for ii=Iprof_sort(kk):Iprof_sort(kk+1)-1,
            Iprofile(ii)=kk;
        end
    end
    dataset.Iprofile=Iprofile;
    
    % number of profiles
    dataset.nprofiles=length(Iprof);

    varargout(1) = {dataset};
    
    
else;%if m==0;
    
    % profile coordinates
    Iprof=find(dataset.Iprofile==m);
    pnum_txt=pnum{Iprof(1)};
    lon=Data(1,Iprof(1));
    lat=Data(2,Iprof(1));
    strdate=Date{Iprof(1)};
    if length(strdate)<10, varargout = {[]}; return; end
    ymd=str2num(strdate([1:4 6:7 9:10]));
    hms=0;  
    if length(strdate)==19, hms=str2num(strdate([12:13 15:16 18:19])); end
    if length(strdate)==16, hms=str2num(strdate([12:13 15:16]))*100; end
    if length(strdate)==13, hms=str2num(strdate([12:13]))*10000; end

    %case when necessary information missing: dont retrieve profile
    if isempty(lon)|isempty(lat)|isempty(ymd), varargout = {[]}; return; end
    if lon < 0; lon=lon+360; end;
    
    % get T/S data
    z=Data(3,Iprof);
    z_qv=Data(4,Iprof);z_qv(isempty(z_qv))=1;
    t=Data(5,Iprof);
    t_qv=Data(6,Iprof);t_qv(isempty(t_qv))=1;
    if dataset.inclS,
        s=Data(7,Iprof);
        s_qv=Data(8,Iprof);s_qv(isempty(s_qv))=1;
    else
        s=t*NaN;  s_qv=t*NaN;   s_ERR=t*NaN;
    end
    
    I=find(isnan(z)|z_qv~=0);
    z(I)=[]; t(I)=[]; t_qv(I)=[]; 
    t(t_qv~=0)=NaN; 
    t_ERR=t*0;
    if dataset.inclS,
        s_qv(I)=[];    s(I)=[]; 
        s(s_qv~=0)=NaN;     s_ERR=s*0;
    end
    z_ERR=t*0;
    
    direc=2;
    isBAD=0;
    
    profileCur.pnum_txt=pnum_txt;
    profileCur.ymd=ymd; profileCur.hms=hms;
    profileCur.lat=lat; profileCur.lon=lon;
    profileCur.direc=direc;
    profileCur.isBAD=isBAD;
    profileCur.T=t;
    profileCur.S=s;
    profileCur.depth=z;
    profileCur.T_ERR=t_ERR;
    profileCur.S_ERR=s_ERR;
    profileCur.depth_ERR=z_ERR;
    
    varargout = {profileCur};
    
end;



