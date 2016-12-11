function []=MITprof_create(fileOut,MITprofCur,varargin);
% MITPROF_CREATE(fileOut,MITprofCur,list_vars)
%   Creates a file in the MITprof format. The list of variables
%   can further be specified via list_vars (optional).

% check that file exists and add prefix and suffix if necessary
[pathstr, name, ext] = fileparts(fileOut);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
if isempty(ext) | ~strcmp(ext,'.nc'), ext='.nc'; end
fileOut=[pathstr '/' name ext];

%define netcdf dimensions :
prof_depth=MITprofCur.prof_depth;
prof_depth=reshape(prof_depth,length(prof_depth),1);
iPROF=MITprofCur.np; iDEPTH=MITprofCur.nr;
if isfield(MITprofCur,'prof_interp_weights');
  iINTERP=size(MITprofCur.prof_interp_weights,2);
  addGrid=1;
else;
  iINTERP=1;
  addGrid=0;
end;
lTXT=30; fillval=double(-9999);

%=============list of variables that will actually be in the file==============%
if nargin>2;
    list_vars=varargin{1};
else;
    list_vars={'prof_depth','prof_descr','prof_date','prof_YYYYMMDD','prof_HHMMSS',...
        'prof_lon','prof_lat','prof_basin','prof_point','prof_flag','prof_T','prof_Tweight','prof_Testim','prof_Terr','prof_Tflag',...
        'prof_S','prof_Sweight','prof_Sestim','prof_Serr','prof_Sflag','prof_D','prof_Destim'};
    if addGrid; 
      list_vars={list_vars{:},'prof_interp_XC11','prof_interp_YC11','prof_interp_XCNINJ','prof_interp_YCNINJ'};
      list_vars={list_vars{:},'prof_interp_i','prof_interp_j','prof_interp_lon','prof_interp_lat','prof_interp_weights'};
    end;
end;

% eliminate duplicates
[list,m]=unique(list_vars);
list_vars=list_vars(sort(m));

list_vars_plus={};
for ii=1:length(list_vars);
    if ~isempty(strfind(list_vars{ii},'estim'))&...
            ~strcmp(list_vars{ii},'prof_Testim')&...
            ~strcmp(list_vars{ii},'prof_Sestim');
        list_vars_plus={list_vars_plus{:},list_vars{ii}(1:end-5)};
    end;
end;

%==========masters table of variables, units, names and dimensions=============%

mt_v={'prof_depth'}; mt_u={'me'}; mt_n={'depth'}; mt_d={'iDEPTH'};
%mt_v=[mt_v '']; mt_u=[mt_u ' ']; mt_n=[mt_n '']; mt_d=[mt_d ''];
mt_v=[mt_v 'prof_date']; mt_u=[mt_u ' ']; mt_n=[mt_n 'Julian day since Jan-1-0000']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_YYYYMMDD']; mt_u=[mt_u ' ']; mt_n=[mt_n 'year (4 digits), month (2 digits), day (2 digits)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_HHMMSS']; mt_u=[mt_u ' ']; mt_n=[mt_n 'hour (2 digits), minute (2 digits), second (2 digits)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_lon']; mt_u=[mt_u 'degrees_east']; mt_n=[mt_n 'Longitude (degree East)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_lat']; mt_u=[mt_u 'degrees_north']; mt_n=[mt_n 'Latitude (degree North)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_basin']; mt_u=[mt_u ' ']; mt_n=[mt_n 'ocean basin index (ecco 4g)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_point']; mt_u=[mt_u ' ']; mt_n=[mt_n 'grid point index (ecco 4g)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_flag']; mt_u=[mt_u ' ']; mt_n=[mt_n 'flag = i > 0 for suspicious profile ']; mt_d=[mt_d 'iPROF'];
%
mt_v=[mt_v 'prof_T']; mt_u=[mt_u 'degree C']; mt_n=[mt_n 'potential temperature']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Tweight']; mt_u=[mt_u '(degree C)^-2']; mt_n=[mt_n 'pot. temp. least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Testim']; mt_u=[mt_u 'degree C']; mt_n=[mt_n 'pot. temp. estimate (e.g. from atlas)']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Terr']; mt_u=[mt_u 'degree C']; mt_n=[mt_n 'pot. temp. instrumental error']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Tflag']; mt_u=[mt_u ' ']; mt_n=[mt_n 'flag = i > 0 means test i rejected data.']; mt_d=[mt_d 'iPROF,iDEPTH'];
%
mt_v=[mt_v 'prof_S']; mt_u=[mt_u 'psu']; mt_n=[mt_n 'salinity']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Sweight']; mt_u=[mt_u '(psu)^-2']; mt_n=[mt_n 'salinity least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Sestim']; mt_u=[mt_u 'psu']; mt_n=[mt_n 'salinity estimate (e.g. from atlas)']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Serr']; mt_u=[mt_u 'psu']; mt_n=[mt_n 'salinity instrumental error']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Sflag']; mt_u=[mt_u ' ']; mt_n=[mt_n 'flag = i > 0 means test i rejected data.']; mt_d=[mt_d 'iPROF,iDEPTH'];
%
for ii=1:length(list_vars_plus);    
    mt_v=[mt_v list_vars_plus{ii}]; mt_u=[mt_u 'unknown']; mt_n=[mt_n 'unknown']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v [list_vars_plus{ii} 'weight']]; mt_u=[mt_u '(unknown)^-2']; mt_n=[mt_n 'unknown least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v [list_vars_plus{ii} 'estim']]; mt_u=[mt_u 'unknown']; mt_n=[mt_n 'unknown estimate (e.g. from atlas)']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v [list_vars_plus{ii} 'err']]; mt_u=[mt_u 'unknown']; mt_n=[mt_n 'unknown instrumental error']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v [list_vars_plus{ii} 'flag']]; mt_u=[mt_u ' ']; mt_n=[mt_n 'flag = i > 0 means test i rejected data.']; mt_d=[mt_d 'iPROF,iDEPTH'];
end;
%
list_interpr={'prof_interp_XC11','prof_interp_YC11','prof_interp_XCNINJ','prof_interp_YCNINJ'};
for ii=1:length(list_interpr);    
    mt_v=[mt_v list_interpr{ii}]; mt_u=[mt_u 'unknown']; mt_n=[mt_n 'interpolation variable']; mt_d=[mt_d 'iPROF'];
end;
list_interpr={'prof_interp_i','prof_interp_j','prof_interp_lon','prof_interp_lat','prof_interp_weights'};
for ii=1:length(list_interpr);    
    mt_v=[mt_v list_interpr{ii}]; mt_u=[mt_u 'unknown']; mt_n=[mt_n 'interpolation variable']; mt_d=[mt_d 'iPROF,iINTERP'];
end;
%
if 0;
    mt_v=[mt_v 'prof_U']; mt_u=[mt_u 'm/s']; mt_n=[mt_n 'eastward velocity comp.']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v 'prof_Uweight']; mt_u=[mt_u '(m/s)^-2']; mt_n=[mt_n 'east. v. least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v 'prof_V']; mt_u=[mt_u 'm/s']; mt_n=[mt_n 'northward velocity comp.']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v 'prof_Vweight']; mt_u=[mt_u '(m/s)^-2']; mt_n=[mt_n 'north. v. least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v 'prof_ptr']; mt_u=[mt_u 'X']; mt_n=[mt_n 'passive tracer']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v 'prof_ptrweight']; mt_u=[mt_u '(X)^-2']; mt_n=[mt_n 'pass. tracer least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
    %
    mt_v=[mt_v 'prof_D']; mt_u=[mt_u 'me']; mt_n=[mt_n 'variable depth']; mt_d=[mt_d 'iPROF,iDEPTH'];
    mt_v=[mt_v 'prof_Destim']; mt_u=[mt_u 'me']; mt_n=[mt_n 'variable depth estimate (e.g. from atlas)']; mt_d=[mt_d 'iPROF,iDEPTH'];
    %
    mt_v=[mt_v 'prof_bp']; mt_u=[mt_u 'cm']; mt_n=[mt_n 'bottom pressure']; mt_d=[mt_d 'iPROF'];
    mt_v=[mt_v 'prof_bpweight']; mt_u=[mt_u '(cm)^-2']; mt_n=[mt_n 'bot. pres. least-square weight']; mt_d=[mt_d 'iPROF'];
    mt_v=[mt_v 'prof_ssh']; mt_u=[mt_u 'cm']; mt_n=[mt_n 'sea surface height']; mt_d=[mt_d 'iPROF'];
    mt_v=[mt_v 'prof_sshweight']; mt_u=[mt_u '(cm)^-2']; mt_n=[mt_n 'ssh least-square weight']; mt_d=[mt_d 'iPROF'];
end;

%=============================create the file=================================%

% write the netcdf structure
ncid=nccreate(fileOut,'clobber');

aa=sprintf(['The contents of this MITprof file were processed \n' ...
            'using the MITprof matlab toolbox which can be obtained from \n'...
            'http://mitgcm.org/viewvc/MITgcm/MITgcm_contrib/gael/profilesMatlabProcessing/']);
ncputAtt(ncid,'','Format',aa);
ncputAtt(ncid,'','date',date);

ncdefDim(ncid,'iPROF',iPROF);
ncdefDim(ncid,'iDEPTH',iDEPTH);
if addGrid; ncdefDim(ncid,'iINTERP',iINTERP); end;
ncdefDim(ncid,'lTXT',lTXT);

for ii=1:length(list_vars);
    jj=find(strcmp(mt_v,list_vars{ii}));
    if ~isempty(jj);
        if strcmp(mt_d{jj},'iPROF,iDEPTH');
            ncdefVar(ncid,mt_v{jj},'double',{'iDEPTH','iPROF'});%note the direction flip
        elseif strcmp(mt_d{jj},'iPROF,iINTERP');
            ncdefVar(ncid,mt_v{jj},'double',{'iINTERP','iPROF'});%note the direction flip
        else;
            ncdefVar(ncid,mt_v{jj},'double',{mt_d{jj}});
        end;
        ncputAtt(ncid,mt_v{jj},'long_name',mt_n{jj});
        ncputAtt(ncid,mt_v{jj},'units',mt_u{jj});
        ncputAtt(ncid,mt_v{jj},'missing_value',fillval);
        ncputAtt(ncid,mt_v{jj},'_FillValue',fillval);
    else;
        if strcmp(list_vars{ii},'prof_descr')
            ncdefVar(ncid,'prof_descr','char',{'lTXT','iPROF'});
            ncputAtt(ncid,'prof_descr','long_name','profile description');
        else
            warning([list_vars{ii} ' not included -- it is not a MITprof variable']);
        end
    end;
end;

ncclose(ncid);

%=============================set prof_depth=================================%

ncid=ncopen(fileOut,'write');
ncputvar(ncid,'prof_depth',prof_depth);
ncclose(ncid);


