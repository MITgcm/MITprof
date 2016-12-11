function [MITprof]=MITprof_struct(nProf,dataset,varargin);
%   [MITprof]=MITprof_struct;
%   create an empty struct variable using the format MITprof
%       nProf: number of profiles
%       prof_depth: list of depth levels
%       list_var: specify name of created fields
%
%   list of fields always created:
%       prof_depth      [nDepth x 1]
%       prof_descr      {nProf x 1}
%       prof_date       [nProf x 1]
%       prof_YYYYMMDD   [nProf x 1]
%       prof_HHMMSS     [nProf x 1]
%       prof_lon        [nProf x 1]
%       prof_lat        [nProf x 1]
%       prof_basin      [nProf x 1]
%       prof_point      [nProf x 1]
%       np, nr, list_descr, nd
%
%   list of fields created by default, if list_var not specified
%       prof_T, prof_Tflag, prof_Terr, prof_Tweight, prof_Testim
%       prof_S, prof_Sflag, prof_Serr, prof_Sweight, prof_Sestim
%           array size: [nProf x nLev]

prof_depth=dataset.z_std;

list_vars={};
for ii=2:length(dataset.var_out);
    list_vars={list_vars{:},['prof_' dataset.var_out{ii} ]};
    list_vars={list_vars{:},['prof_' dataset.var_out{ii} 'weight']};
    list_vars={list_vars{:},['prof_' dataset.var_out{ii} 'estim']};
    %if dataset.outputMore;
    list_vars={list_vars{:},['prof_' dataset.var_out{ii} 'err']};
    list_vars={list_vars{:},['prof_' dataset.var_out{ii} 'flag']};
    %end;
end;
% list_vars={'prof_T','prof_Tweight','prof_Testim','prof_Terr','prof_Tflag',...
%     'prof_S','prof_Sweight','prof_Sestim','prof_Serr','prof_Sflag'};
% if ~strcmp(dataset.coord,'depth'); list_vars={list_vars{:},'prof_D','prof_Destim'}; end;
if nargin>2,
    list_vars=varargin{1};
end


MITprof=[];

nLev=length(prof_depth);
prof_depth=reshape(prof_depth,length(prof_depth),1);
MITprof.prof_depth=prof_depth;

MITprof.prof_date=zeros(nProf,1);
MITprof.prof_YYYYMMDD=zeros(nProf,1);
MITprof.prof_HHMMSS=zeros(nProf,1);
MITprof.prof_lon=zeros(nProf,1);
MITprof.prof_lat=zeros(nProf,1);
MITprof.prof_basin=zeros(nProf,1);
MITprof.prof_point=zeros(nProf,1);

MITprof.prof_descr=cell(nProf,1);

for ii=1:length(list_vars),
    MITprof=setfield(MITprof,list_vars{ii},zeros(nProf,nLev));
end

MITprof.np=nProf;
MITprof.nr=nLev;
MITprof.nd=0;
MITprof.list_descr={};



