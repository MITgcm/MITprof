function [MITprofCur]=profiles_prep_weights(dataset,MITprofCur,sigma);
%[MITprofCur]=profiles_prep_weights(dataset,MITprofCur,sigma);
%	Attributes least square weights to MITprofCur
%	based upon dataset specs, instrumental and
%	representation error estimates
%
%by assumption:
%	neither the representation error fields (sigma.T and sigma.S)
%	nor the data is 'land-masked'. And sigma.T/S>0 everywhere.
%
% global variable mygrid must be set.

MITprof_global;

method='bindata';
if isfield(dataset,'method');
  method=dataset.method;
end;

nk=size(sigma.T,3); kk=ones(1,nk); np=length(MITprofCur.prof_lon); pp=ones(np,1);

if strcmp(method,'bindata')
    ind2prof=sub2ind(size(sigma.T),MITprofCur.ii*kk,MITprofCur.jj*kk,pp*[1:nk]);
end;

for ii=2:length(dataset.var_out);
    vv=dataset.var_out{ii};
    if isfield(sigma,vv);
        sig_in=getfield(sigma,vv);
    else;
        sig_in=ones(size(sigma.T));
    end;
    if strcmp(method,'bindata')
      %collocate sig_in to profiles locations:
      sig_in=sig_in(ind2prof);
      %interpolate in the vertical:
      sig_out=interp1(-mygrid.RC',sig_in',MITprofCur.prof_depth)';
    elseif strcmp(method,'interp');
      fldIn.name='prof_tmp'; fldIn.tim='const';
      fldIn.fld=convert2array(sig_in);
      MITprofCur=MITprof_resample(MITprofCur,fldIn);
      sig_out=MITprofCur.prof_tmp;
      MITprofCur=rmfield(MITprofCur,'prof_tmp');
    else;
      error('unknown dataset.method')
    end;
    %
    if isfield(MITprofCur,['prof_' vv 'err']);
        sig_instr=getfield(MITprofCur,['prof_' vv 'err']);
        sig_instr(sig_instr==dataset.fillval)=0;
    else;
        sig_instr=0*getfield(MITprofCur,['prof_' vv]);
    end;
    %
    tmp_weight=1./(sig_out.^2+sig_instr.^2);
    eval(['MITprofCur.prof_' vv 'weight=tmp_weight;']);
end;


