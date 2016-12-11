function []=MITprof_gcm2nc(varargin);
%[]=MITprof_gcm2nc;
%[]=MITprof_gcm2nc;
%object:	takes binary output from MITgcm/pkg/profiles (in dir_model)
%		and recomposes a MITprof netcdf file (in dir_model/input)
%optional inputs:
%		dir_model is the directory where the binary files are ('./' by default)
%		list_model is the list of the corresponding MITprof files, which 
%		need to be copied or linked to dir_model/input
%		({'seals*','WOD09_XBT*','WOD09_CTD*','argo_at*','argo_pa*','argo_in*'} by default)
%
%e.g.		dir_model='./';
%		list_model={'seals*','WOD09_XBT*','WOD09_CTD*','argo_at*','argo_pa*','argo_in*'};
%		MITprof_gcm2nc(dir_model,list_model);
%note:
%		by assumption, dir_model contains the binaries,
%		dir_model/input contains the matching MITprof file
%		that was provided as input to MITgcm/pkg/profiles, and
%		the recomposed MITprof file will be put in dir_model/output

warning off MATLAB:mir_warning_variable_used_as_function;

if nargin==2; dir_model=varargin{1}; list_model=varargin{2}; 
else; 
  dir_model='./'; 
  list_model={'seals*','WOD09_XBT*','WOD09_CTD*','argo_at*','argo_pa*','argo_in*'};
end;

if iscell(dir_model);
  %the following assumes that
  %dir_model{1} is the run directory where *.nc MITgcm input files and profiles/*bin MITgcm output files are
  %dir_model{2} typically is dirMat/profiles/output/ and is where the new *.nc files will be created
  dir_out=dir_model{2};
  dir_data=dir_model{1};
  dir_model=[dir_model{1} 'profiles/'];
else;
  %the following assumes that
  %dir_model is where MITgcm input and output files have been linked to dir_model (*.bin)
  %and dir_model/input/ (*.nc) -- the new *.nc files will then be created in dir_model/output/
  dir_out=[dir_model 'output/'];
  dir_data=[dir_model 'input/'];
end;

%loop over files:
for ff=1:length(list_model)
    
    %initialize the process:
    clear prof_*;
    file_data=dir([dir_data list_model{ff}  '*.nc']);
    file_data2=file_data.name;
    
    %load the data:
    MITprof=MITprof_load([dir_data file_data2]);
    
    %prepare relevant output:
    varList={'T','S','U','V','ptr','ssh','OXY'};
    varMax=length(varList);
    varNum=zeros(varMax,1); varCount=0;
    for v=1:varMax; vv=varList{v};
        if isfield(MITprof,['prof_' vv]);
            varCount=varCount+1; varNum(v)=varCount;
            eval(['prof_' vv '=-9999*ones(size(MITprof.prof_' vv ')); prof_' vv 'mask=prof_' vv ';']);
        end;
    end;
    varList={varList{find(varNum)}};
    nr=length(MITprof.prof_depth);
    
    %list tile/processor model files:
    eval(['model_list_model=dir(''' dir_model list_model{ff} '*.data'');']);
    
    %if no model files then stop
    if size(model_list_model,1)==0; fprintf(['file: ' file_data2 ' \n, no model files found\n']);
    else;
        
        %loop over model files:
        for ffM=1:length(model_list_model)
            file_model2=model_list_model(ffM).name;
            np=model_list_model(ffM).bytes/8/2/(nr+1)/varCount;
            tmp_prof=read2memory([dir_model file_model2],[nr+1 2 varCount np],64);
            
            for v=1:varCount; vv=varList{v};
                tmp1=squeeze(tmp_prof(1:nr,1,v,:))'; tmp2=squeeze(tmp_prof(1:nr,2,v,:))'; tmp3=squeeze(tmp_prof(nr+1,1,v,:));
                tmp4=find(tmp3>0); tmp1=tmp1(tmp4,:); tmp2=tmp2(tmp4,:); tmp3=tmp3(tmp4,:);
                eval(['prof_' vv '(tmp3,:)=tmp1; prof_' vv 'mask(tmp3,:)=tmp2;']);
            end;
        end; %for ffM
        
        %include in structure:
        for v=1:varCount; vv=varList{v}; eval(['prof_' vv '(prof_' vv 'mask==0)=-9999; MITprof.prof_' vv 'estim=prof_' vv ';']); end;
        
        %prepare fields list:
        list_out=fieldnames(MITprof)';
        ii=find(strncmp(list_out,'prof_U',6)+strncmp(list_out,'prof_S',6)+strncmp(list_out,'prof_T',6)+...
            strncmp(list_out,'prof_V',6)+strncmp(list_out,'prof_ssh',8)+strncmp(list_out,'prof_ptr',8)+...
            strncmp(list_out,'prof_OXY',8));
        list_out={list_out{ii}};
        %prepare other fields:
        file_out=[file_data2(1:end-3) '_model.nc'];
        nr=length(MITprof.prof_depth);
        np=length(MITprof.prof_lon);
        %write to file:
        fprintf(['writing file: ' file_data2 ' \n']);
        MITprof_write([dir_out file_out],MITprof);
        
        fprintf(['file: ' file_data2 ' \n has been processed \n']);
    end %if size(model_list_model,1)~=0;
end%for ff=1:length(list_model)


