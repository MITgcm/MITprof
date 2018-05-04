function [varargout]=profiles_read_odvnc(dataset,nf,m,varargin);
% read hydrographic data in the ODV netcdf export format
%
% if m=0 :
%  return the information on the nf-th file referenced in dataset.fileInList
%   dataset=profiles_read_odvnc(dataset,nf,0);
%
% if m~=0 :
%  return the m-th profile from the nf-th file referenced in dataset.fileInList
%   profileCur=profile_read_odv(dataset,nf,m);
%
% note: the above assumes that dataset has been initialized, e.g., by running
%   dataset=profiles_prep_select('odvnc','OXYGEN');
%
% note: for now, this function simply masks out any values for which QC>=3 (see below),
%   but this may need to be refined since QCs in the GLODAPv2 data collection 
%   are defined differently for depth, T vs S, OXYGEN, etc. with 
%   - QCs for depth,temp:      var3_QC:comment = "0: good quality, 1: unknown quality, 4: questionable quality, 8: bad quality" ;
%   - QCs for salt,oxy, etc:   var4_QC:comment = "1: sample for this measurement was drawn from water bottle but analysis not received, 
%     2: acceptable measurement, 3: questionable measurement, 4: bad measurement, 5: not reported, 6: mean of replicate measurements, 
%     7: manual chromatographic peak measurement, 8: irregular digital chromatographic peak integration, 
%     9: sample not drawn for this measurement from this bottle" ;


fileIn=[dataset.dirIn dataset.fileInList(nf).name];
instrType=dataset.subset(3:end);

if m==0;
    
    % return the number of profiles in the file

    f = ncopen(fileIn, 'nowrite');
    tmpID=netcdf.inqDimID(f,'N_STATIONS');
    [dimname, dimlen]=netcdf.inqDim(f,tmpID);
    dataset.nprofiles=dimlen;
    %    
    var_in={dataset.var_in{:},'Cruise','date_time','longitude','latitude'};
    var_out={dataset.var_out{:},'Cruise','datenum','longitude','latitude'};
    var_in_noQC={'Cruise','date_time','longitude','latitude'};
    var_found=NaN*zeros(1,length(dataset.var_in));
    varids = netcdf.inqVarIDs(f);
    for vv=1:length(varids);
        [varname,xtype,dimids,natts] = netcdf.inqVar(f,varids(vv));
        tmp_var=netcdf.getVar(f,varids(vv));
        if isnumeric(tmp_var); tmp_var=double(tmp_var); end;
        tmp_fillval=netcdf.getAtt(f,varids(vv),'_FillValue');
        if isnumeric(tmp_fillval)&~isempty(tmp_fillval);
            tmp_var(tmp_var==tmp_fillval)=NaN;
        end;
        if strcmp(varname,'date_time');
            tmp_att=netcdf.getAtt(f,varids(vv),'units');
            tmp_att=datenum(tmp_att(12:end-4));
            tmp_var=tmp_var+tmp_att;
        end;
        if isempty(strfind(varname,'_QC'));
            long_name=netcdf.getAtt(f,varids(vv),'long_name');
        else;
            long_name='';
        end;
        ww=find(strcmp(var_in,long_name)|strcmp(var_in,varname));
        if ~isempty(ww);
            eval(['dataset.' var_out{ww} '=tmp_var;']);
            var_found(ww)=1;
            %get QC
            if isempty(find(strcmp(var_in_noQC,var_in{ww})));
                tmpID=netcdf.inqVarID(f,[varname '_QC']);
                tmp2=netcdf.getVar(f,tmpID);
                eval(['dataset.' var_out{ww} '_QC=tmp2;']);
            end;
        end;
    end;
    %
    netcdf.close(f);
    
    varargout(1) = {dataset};
    
else;%if m==0;
    
    %% date, position, etc
    juld=dataset.datenum(m);
    [Y, M, D, H, MN, S] = datevec(juld);
    ymd=Y*1e4+M*1e2+D;
    hms=H*1e4+MN*1e2+S;
    
    lat=dataset.latitude(m);
    lon=dataset.longitude(m); if lon < 0; lon=lon+360;end;

    pnum_txt=dataset.Cruise(:,m)';
    direc=2;
    isBAD=0;

    %%
    
    profileCur.pnum_txt=pnum_txt;
    profileCur.ymd=ymd; profileCur.hms=hms;
    profileCur.lat=lat; profileCur.lon=lon;
    profileCur.direc=direc;
    profileCur.isBAD=isBAD;

    for vv=1:length(dataset.var_out);
        eval(['tmp1=dataset.' dataset.var_out{vv} '(:,m)'';']);
        eval(['tmp1qc=dataset.' dataset.var_out{vv} '_QC(:,m)'';']);
        tmp1qc=str2num(tmp1qc);
        tmp1(tmp1qc>=3)=NaN; %This may need to be refined (see above notes on QC values)
        %
        profileCur = setfield(profileCur,dataset.var_out{vv},tmp1);
        profileCur = setfield(profileCur,[dataset.var_out{vv} '_ERR'],0*tmp1);        
    end;

    if isnan(profileCur.ymd)|isnan(profileCur.hms)|...
            isnan(profileCur.lon)|isnan(profileCur.lat);
        profileCur=[];
    end;
        
    varargout = {profileCur};
    
end;



