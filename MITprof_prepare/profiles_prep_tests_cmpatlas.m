function [MITprofCur]=profiles_prep_tests_cmpatlas(dataset,MITprofCur,atlas);
% [MITprofCur]=profiles_prep_tests_cmpatlas(MITprofCur,atlas)
%   range tests based on comparison with the reference climatology
%       flag excessively large distance to climatologies to 5
%   require gcmfaces
%
% set profilCur.t_test (and profilCur.s_test) following the code:
%   0 = valid data
%   1 = not enough data near standard level
%   2 = absurd sal value
%   3 = doubtful profiler (based on our own evaluations)
%   4 = doubtful profiler (based on Argo grey list)
%   5 = high climatology/atlas cost - all four of them
%   6 = bad Pressure vector
%
% set MITprofCur.prof_Testim and MITprofCur.prof_Sestim as the nearest
%   climatological T/S profile
%
% global variable mygrid must be set.

MITprof_global;

method='bindata';
if isfield(dataset,'method');
  method=dataset.method;
end;

%%set parameters according to MITprofCur specifications:

do_S=isfield(MITprofCur,'prof_S');

max_cost=50;
if isfield(dataset,'max_cost');
  max_cost=dataset.max_cost;
end;

unbias_T=0;
unbias_S=0;
if isfield(dataset,'unbias_T');
  if dataset.unbias_T==1;
    unbias_T=1;
  end;
end;
if isfield(dataset,'unbias_S');
  if dataset.unbias_S==1;
    unbias_S=1;
  end;
end;

%%set sizes and indices:

nk=length(mygrid.RC);
kk=ones(1,nk);
np=length(MITprofCur.prof_lon);
pp=ones(np,1);

if strcmp(method,'bindata');
  ind2prof=sub2ind(size(atlas.T{1}),MITprofCur.ii*kk,MITprofCur.jj*kk,pp*[1:nk],MITprofCur.imonth*kk);
end;

%%cost computations:

warning('off','MATLAB:interp1:NaNinY');

for ff=1:length(atlas.T);
    if strcmp(method,'bindata');
      t_equi=atlas.T{ff}(ind2prof);%collocate
      t_equi=interp1(-mygrid.RC',t_equi',MITprofCur.prof_depth)';%vert. interp.
    elseif strcmp(method,'interp');
      fldIn.name='prof_tmp'; fldIn.tim='monclim';
      fldIn.fld=convert2array(atlas.T{ff});
      MITprofCur=MITprof_resample(MITprofCur,fldIn);
      t_equi=MITprofCur.prof_tmp;
      MITprofCur=rmfield(MITprofCur,'prof_tmp');
    else;
      error('unknown dataset.method')
    end;
    if ff==1;
        MITprofCur.prof_Testim=t_equi;
        t_cost=NaN*t_equi;
    end;
    tmp_cost=MITprofCur.prof_Tweight.*((MITprofCur.prof_T-t_equi).^2);
    t_cost( (isnan(t_cost)&~isnan(tmp_cost)) | (tmp_cost<t_cost) )=...
        tmp_cost( (isnan(t_cost)&~isnan(tmp_cost)) | (tmp_cost<t_cost) );

    if unbias_T;
      t_bias=MITprofCur.prof_T-t_equi;
      t_bias=nanmedian(t_bias,1);
      t_bias=ones(MITprofCur.np,1)*t_bias;
      tmp_cost=MITprofCur.prof_Tweight.*((MITprofCur.prof_T-t_equi-t_bias).^2);
      t_cost( (isnan(t_cost)&~isnan(tmp_cost)) | (tmp_cost<t_cost) )=...
          tmp_cost( (isnan(t_cost)&~isnan(tmp_cost)) | (tmp_cost<t_cost) );
    end;

    if ~strcmp(dataset.coord,'depth');
        d_equi=atlas.D{ff}(ind2prof);%collocate
        d_equi=interp1(-mygrid.RC',d_equi',MITprofCur.prof_depth)';%vert. interp.
        if ff==1;
            MITprofCur.prof_Destim=d_equi;
        end;
    end;
    
    if do_S;
        if strcmp(method,'bindata');
          s_equi=atlas.S{ff}(ind2prof);%collocate
          s_equi=interp1(-mygrid.RC',s_equi',MITprofCur.prof_depth)';%vert. interp.
        elseif strcmp(method,'interp');
          fldIn.name='prof_tmp'; fldIn.tim='monclim';
          fldIn.fld=convert2array(atlas.S{ff});
          MITprofCur=MITprof_resample(MITprofCur,fldIn);
          s_equi=MITprofCur.prof_tmp;
          MITprofCur=rmfield(MITprofCur,'prof_tmp');
        else;
          error('unknown dataset.method')
        end;
        if ff==1;
            MITprofCur.prof_Sestim=s_equi;
            s_cost=NaN*s_equi;
        end;
        tmp_cost=MITprofCur.prof_Sweight.*((MITprofCur.prof_S-s_equi).^2);
        s_cost( (isnan(s_cost)&~isnan(tmp_cost)) | (tmp_cost<s_cost) )=...
            tmp_cost( (isnan(s_cost)&~isnan(tmp_cost)) | (tmp_cost<s_cost) );
        %
        if unbias_S;
          s_bias=MITprofCur.prof_S-s_equi;
          s_bias=nanmedian(s_bias,1); 
          s_bias=ones(MITprofCur.np,1)*s_bias;
          tmp_cost=MITprofCur.prof_Sweight.*((MITprofCur.prof_S-s_equi-s_bias).^2);
          s_cost( (isnan(s_cost)&~isnan(tmp_cost)) | (tmp_cost<s_cost) )=...
              tmp_cost( (isnan(s_cost)&~isnan(tmp_cost)) | (tmp_cost<s_cost) );
        end;
    end;
end;

warning('on','MATLAB:interp1:NaNinY');

%%test for cost>max_cost and update flag and weight accordingly:

ii=find( (MITprofCur.prof_T~=MITprofCur.fillval)&(t_cost>max_cost) );
MITprofCur.prof_Tflag(ii)=10*MITprofCur.prof_Tflag(ii)+5;
if do_S;
    ii=find( (MITprofCur.prof_S~=MITprofCur.fillval)&(s_cost>max_cost) );
    MITprofCur.prof_Sflag(ii)=10*MITprofCur.prof_Sflag(ii)+5;
end;

MITprofCur.prof_Tweight(isnan(MITprofCur.prof_T)|...
           MITprofCur.prof_T==-9999|MITprofCur.prof_Tflag>0)=0;
MITprofCur.prof_Testim(isnan(MITprofCur.prof_Testim))=-9999;
if do_S;
    MITprofCur.prof_Sweight(isnan(MITprofCur.prof_S)|...
               MITprofCur.prof_S==-9999|MITprofCur.prof_Sflag>0)=0;
    MITprofCur.prof_Sestim(isnan(MITprofCur.prof_Sestim))=-9999;
end;


