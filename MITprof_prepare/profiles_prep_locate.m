function [MITprofCur]=profiles_prep_locate(dataset,MITprofCur);
%[MITprofCur]=profiles_prep_locate(dataset,MITprofCur);
%   locates MITprofCur profiles on ECCO v4 grid, and set
%   month and basin index. Two methods are available:
%   'bindata' (default) and 'interp'
%
%  global variables MYBASININDEX must be set in gcmfaces

MITprof_global; global MYBASININDEX;

method='bindata';
if isfield(dataset,'method');
  method=dataset.method;
end;

if strcmp(method,'bindata')
  MITprofCur.prof_point=gcmfaces_bindata(MITprofCur.prof_lon,MITprofCur.prof_lat);
  [MITprofCur.ii,MITprofCur.jj]=gcmfaces_bindata(MITprofCur.prof_lon,MITprofCur.prof_lat);
elseif strcmp(method,'interp');
  [MITprofCur.interp,MITprofCur.corners]=gcmfaces_interp_coeffs(MITprofCur.prof_lon,MITprofCur.prof_lat);

  MITprofCur.prof_point=MITprofCur.interp.point;

  list_in={'XC11','YC11','XCNINJ','YCNINJ'};
  list_out={'XC11','YC11','XCNINJ','YCNINJ'};
  for iF=1:length(list_out);
    eval(['MITprofCur.prof_interp_' list_out{iF} '=MITprofCur.corners.' list_in{iF} ';']);
  end;

  list_in={'i','j','XC','YC','w'};
  list_out={'i','j','lon','lat','weights'};
  for iF=1:length(list_out);
    eval(['MITprofCur.prof_interp_' list_out{iF} '=MITprofCur.interp.' list_in{iF} ';']);
  end;

else;
  error('unknown dataset.method')
end;

MITprofCur.prof_basin=MYBASININDEX(MITprofCur.prof_point);
MITprofCur.imonth=floor(MITprofCur.prof_YYYYMMDD/1e2)-1e2*floor(MITprofCur.prof_YYYYMMDD/1e4);

