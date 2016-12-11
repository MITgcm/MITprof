function [profOut]=MITprof_resample(profIn,fldIn,filOut,method);
%
%[profOut]=MITPROF_RESAMPLE(profIn,fldIn,filOut,method);
%
%     resamples a set of fields (fldIn) to profile 3D locations (profIn)
%     and output the result to nc file (filOut) and memory (profOut).
%     using a chosen interpolation method (method).
%
%     profIn (structure) should contain: prof_depth, prof_lon, prof_lat, prof_date
%     fldIn (structure) should contain: fil, name, long_name, units, tim, 
%         missing_value, FillValue (for nc output), and fld ([] by default).
%         If fld is not [] then it is assumed that user already loaded 
%         the fields from fldIn.fil.
%
%     fldIn.tim can be set to
%         'const' (for time invariant climatology),
%         'monclim' (for monthly climatology)
%         'monser' (for monthly time series)
%         'monloop' (for cyclic monthly time series)
%
%     method can be set to
%         'polygons' (linear in space)
%         'bindata' (nearest neighbor in space)
%
% Example: 
%  grid_load; gcmfaces_global; MITprof_global; addpath matlab/;
%  profIn=idma_float_plot('4900828');
%  %
%  fldIn.fil=fullfile(myenv.MITprof_climdir,filesep,'T_OWPv1_M_eccollc_90x50.bin');
%  fldIn.name='prof_Towp';
%  fldIn.long_name='pot. temp. estimate (OCCA-WOA-PHC combination)';
%  fldIn.units='degree C';
%  fldIn.tim='monclim';
%  fldIn.missing_value=-9999.;
%  fldIn.FillValue=-9999.;
%  fldIn.fld=[];
%  %
%  profOut=MITprof_resample(profIn,fldIn);


gcmfaces_global;

doOut=~isempty(who('filOut')); doOutInit=false;
if doOut; doOut=~isempty(filOut); end;
if doOut; doOutInit=isempty(dir(filOut)); end;

if isempty(who('method')); method='polygons'; end;

%0) check for file types
test0=isfield(fldIn,'fil');
test1=0;
if test0;
  test0=~isempty(dir(fldIn.fil));
  [PATH,NAME,EXT]=fileparts(fldIn.fil);
  fil_nc=fullfile(PATH,NAME,[NAME '.0001.nc']);
  fil_nctiles=fullfile(PATH,NAME,NAME);
  test1=~isempty(dir(fil_nc));
end;
test2=~isempty(fldIn.fld);

%1) deal with time line
if strcmp(fldIn.tim,'monclim');
    tim_fld=[-0.5:12.5]; rec_fld=[12 1:12 1];
    tmp1=datevec(profIn.prof_date);
    tmp2=datenum([tmp1(:,1) ones(profIn.np,2) zeros(profIn.np,3)]);
    tim_prof=(profIn.prof_date-tmp2);
    tim_prof(tim_prof>365)=365;
    tim_prof=tim_prof/365*12;%neglecting differences in months length
    if test2; fldIs3d=(length(size(fldIn.fld{1}))==4); end;
elseif strcmp(fldIn.tim,'monloop')|strcmp(fldIn.tim,'monser');
    if test1;
      eval(['ncload ' fil_nc ' tim']);
      nt=length(tim);
    elseif ~test2;
      %note: 2D case still needs to be treated here ... or via fldIn.is3d ?
      tmp1=dir(fldIn.fil);
      nt=tmp1.bytes/prod(mygrid.ioSize)/length(mygrid.RC)/4;
    else;
      ndim=length(size(fldIn.fld{1}));
      fldIs3d=(ndim==4);
      nt=size(fldIn.fld{1},ndim);
    end;
    tmp1=[1:nt]'; tmp2=ones(nt,1)*[1992 1 15 0 0 0]; tmp2(:,2)=tmp1;
    tim_fld=datenum(tmp2);
    tim_fld=[tim_fld(1)-31 tim_fld' tim_fld(end)+31];
    rec_fld=[nt 1:nt 1];
    if strcmp(fldIn.tim,'monloop');
      tmp1=datenum([1992 1 1 0 0 0]);
      tmp2=datenum([1992+nt/12 1 1 0 0 0]);;
      tim_prof=tmp1+mod(profIn.prof_date-tmp1,tmp2-tmp1);
    else;
      tim_prof=profIn.prof_date;
    end;
    %round up tim_prof to prevent interpolation in time:
    %  tmp3=tim_prof*ones(1,length(tim_fld))-ones(length(tim_prof),1)*tim_fld;
    %  tmp4=sum(tmp3>0,2);
    %  tim_prof=tim_fld(tmp4)';
elseif strcmp(fldIn.tim,'const')|strcmp(fldIn.tim,'std');
    tim_fld=[1 2]; rec_fld=[1 1];
    tim_prof=1.5*ones(profIn.np,1);
    if test2; fldIs3d=(length(size(fldIn.fld{1}))==3); end;
else;
    error('this case remains to be implemented');
end;

lon=profIn.prof_lon; lat=profIn.prof_lat;
depIn=-mygrid.RC; depOut=profIn.prof_depth;
profOut=NaN*ones(profIn.np,profIn.nr);

%2) loop over record pairs
if strcmp(method,'bindata'); gcmfaces_bindata; end;
for tt=1:length(rec_fld)-1;
  ii=find(tim_prof>=tim_fld(tt)&tim_prof<tim_fld(tt+1));
  if ~isempty(ii);
    %tt
    %
    if test2&fldIs3d;
      fld0=fldIn.fld(:,:,:,rec_fld(tt));
      fld1=fldIn.fld(:,:,:,rec_fld(tt+1));
    elseif test2&~fldIs3d;
      fld0=fldIn.fld(:,:,rec_fld(tt));
      fld1=fldIn.fld(:,:,rec_fld(tt+1));
    elseif test1;
      fld0=read_nctiles(fil_nctiles,NAME,rec_fld(tt));
      fld1=read_nctiles(fil_nctiles,NAME,rec_fld(tt+1));
    elseif test0;
      fld0=read_bin(fldIn.fil,rec_fld(tt));
      fld1=read_bin(fldIn.fil,rec_fld(tt+1));
    else;
      error(['file not found:' fldIn.fil]);
    end;
    %
    ndim=length(size(fld0{1}));
    if ndim==2;
      fld0=fld0.*mygrid.mskC(:,:,1);
      fld1=fld1.*mygrid.mskC(:,:,1);
      fldIs3d=0;
    else;
      fld0=fld0.*mygrid.mskC;
      fld1=fld1.*mygrid.mskC;
      fldIs3d=1;
    end;
    fld=cat(ndim+1,fld0,fld1);
    %
    if ~strcmp(method,'bindata');
      arr=gcmfaces_interp_2d(fld,lon(ii),lat(ii),method);
      if fldIs3d;
        arr2=gcmfaces_interp_1d(2,depIn,arr,depOut);
      else;
        arr2=arr;
      end;
      %now linear in time:
      k0=floor(tim_prof(ii));
      a0=tim_prof(ii)-k0;
      if fldIs3d;
        a0=a0*ones(1,profIn.nr);
        profOut(ii,:)=(1-a0).*arr2(:,:,1)+a0.*arr2(:,:,2);
      else;
        profOut(ii,1)=(1-a0).*arr2(:,1)+a0.*arr2(:,2);
      end;
    elseif fldIs3d;
      [prof_i,prof_j]=gcmfaces_bindata(lon(ii),lat(ii));
      FLD=convert2array(fld(:,:,:,1));
      nk=length(mygrid.RC); kk=ones(1,nk);
      np=length(ii); pp=ones(np,1);
      ind2prof=sub2ind(size(FLD),prof_i*kk,prof_j*kk,pp*[1:nk]);
      arr=FLD(ind2prof);
      arr2=gcmfaces_interp_1d(2,depIn,arr,depOut);
      profOut(ii,:)=arr2;
    else;
      error('2D field case is missing here');
    end;
    %    
    if strcmp(fldIn.tim,'std');
      profOut(ii,:)=profOut(ii,:).*randn(size(profOut(ii,:)));
    end;

  end;%if ~isempty(ii);
end;

if ~fldIs3d;
  profOut=profOut(:,1);
end;

%3) deal with file output
if doOutInit;
    %create a header only file to later append resampled fields
    prof=profIn;
    tmp1=fieldnames(prof);
    nt=length(prof.prof_date);
    nr=length(prof.prof_depth);
    for ii=1:length(tmp1);
        tmp2=prod(size(getfield(prof,tmp1{ii})));
        if tmp2==nt*nr; prof=rmfield(prof,tmp1{ii}); end;
    end;
    MITprof_write(filOut,prof);
end;

if doOut;
    if ~fldIs3d;
      dims={'iPROF'};
    else;
      dims={'iDEPTH','iPROF'};
    end;
    %add the array itelf    
    MITprof_addVar(filOut,fldIn.name,'double',dims,profOut);
    
    %add its attributes
    nc=ncopen(filOut,'write');
    ncaddAtt(nc,fldIn.name,'long_name',fldIn.long_name);
    ncaddAtt(nc,fldIn.name,'units',fldIn.units);
    ncaddAtt(nc,fldIn.name,'missing_value',fldIn.missing_value);
    ncaddAtt(nc,fldIn.name,'_FillValue',fldIn.FillValue);
    ncclose(nc);
end;

%4) deal with argument output
if nargout>0; profOut=setfield(profIn,fldIn.name,profOut); end;


