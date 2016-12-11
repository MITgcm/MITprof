function [MITprofCur]=model_interp(MITprofCur,model,varargin)
% function [MITprofCur]=model_interp(MITprofCur,model,varargin)
%   interpolate model hydrographic fields at the location of given profiles
%
%   MITprofCur: structure containing profile information
%   model is a string used to select the model to be loaded
%       'OCCA' : ECCOv4 grid + OCCA atlas
%       'SOSE59' : SOSE59 grid + atlas

% load model
[grid,atlas]=model_load(model);

% protect global grid variables
global mygrid mytri MYBASININDEX
mygrid1=mygrid; mytri1=mytri; MYBASININDEX1=MYBASININDEX;
mygrid=grid.mygrid; mytri=grid.mytri; MYBASININDEX=grid.MYBASININDEX;

% compute index of closest profile
MITprofCur.prof_point=gcmfaces_bindata(MITprofCur.prof_lon,MITprofCur.prof_lat);
[MITprofCur.ii,MITprofCur.jj]=gcmfaces_bindata(MITprofCur.prof_lon,MITprofCur.prof_lat);

% temporal index
switch model
    case 'SOSE59'
        MITprofCur.imonth=MITprofCur.ii*0+1;
    case 'OCCA'
        MITprofCur.imonth=floor(MITprofCur.prof_YYYYMMDD/1e2)-1e2*floor(MITprofCur.prof_YYYYMMDD/1e4);
    otherwise
        error('not a valid model string');
end

% extract profiles
nk=length(mygrid.RC);kk=ones(1,nk);
np=length(MITprofCur.ii);pp=ones(np,1);
ind2prof=sub2ind(size(atlas.T{1}),MITprofCur.ii*kk,MITprofCur.jj*kk,pp*[1:nk],MITprofCur.imonth*kk);

I=find(~isnan(ind2prof));
Tatlas=ind2prof*NaN;Tatlas(I)=atlas.T{1}(ind2prof(I)); Tatlas(Tatlas==0)=NaN;
Satlas=ind2prof*NaN;Satlas(I)=atlas.S{1}(ind2prof(I)); Satlas(Satlas==0)=NaN;

warning off
Tatlas=interp1(-mygrid.RC',Tatlas',MITprofCur.prof_depth)';
Satlas=interp1(-mygrid.RC',Satlas',MITprofCur.prof_depth)';
warning on

% record values
MITprofCur=setfield(MITprofCur,['prof_T_' model],Tatlas');
MITprofCur=setfield(MITprofCur,['prof_S_' model],Satlas');

% put back global grid values
mygrid=mygrid1; mytri=mytri1; MYBASININDEX=MYBASININDEX1;

