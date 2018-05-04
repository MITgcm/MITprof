function []=profiles_prep_revise(dir_in,file_in,dir_out,file_out);
%[]=profiles_prep_revise(dir_in,file_in,dir_out,file_out);
%	Takes an old pkg/profiles file and
%	map it to a new pkg/profiles file.
%
%	Essentially: add fields such as prof_date,
%	prof_Testim (clim), prof_Tflag (empty), etc.
%	and redo weights and atlas tests (i.e. the
%	second half of profiles_prep_main.m)

%example:
%dir_in='sample_files/reference_results/';
%dir_out='sample_files/modified_results/';
%file_in='argo_indian.nc';
%file_out='argo_indian.nc';
%profiles_prep_revise(dir_in,file_in,dir_out,file_out);



% set global variables
gcmfaces_global; 
global mytri MYBASININDEX atlas sigma;

if isempty(mygrid) | isempty(mytri) | isempty(MYBASININDEX) | isempty(atlas) | isempty(sigma),
  profiles_prep_load_fields;
end;


%load old data set:
MITprof=MITprof_load([dir_in file_in]);
if isfield(MITprof,'prof_T');
  if ~isfield(MITprof,'prof_Testim'); MITprof.prof_Testim=NaN*MITprof.prof_T; end;
  if ~isfield(MITprof,'prof_Tflag'); MITprof.prof_Tflag=zeros(size(MITprof.prof_T)); end;
  if ~isfield(MITprof,'prof_Terr'); MITprof.prof_Terr=zeros(size(MITprof.prof_T)); end;
end;

if isfield(MITprof,'prof_S');
  if ~isfield(MITprof,'prof_Sestim'); MITprof.prof_Sestim=NaN*MITprof.prof_S; end;
  if ~isfield(MITprof,'prof_Sflag'); MITprof.prof_Sflag=zeros(size(MITprof.prof_S)); end;
  if ~isfield(MITprof,'prof_Serr'); MITprof.prof_Serr=zeros(size(MITprof.prof_S)); end;
end;

%back out dataset struture:
dataset.z_std=MITprof.prof_depth;
dataset.inclT=isfield(MITprof,'prof_T');
dataset.inclS=isfield(MITprof,'prof_S');
dataset.fillval=-9999.;
dataset.coord='depth';

%locate profile on grid:
MITprof=profiles_prep_locate(dataset,MITprof);

%instrumental + representation error profile:
MITprof=profiles_prep_weights(dataset,MITprof,sigma);

%carry tests vs atlases:
MITprof.fillval=dataset.fillval;
[MITprof]=profiles_prep_tests_cmpatlas(dataset,MITprof,atlas);

%overwrite file with completed arrays:
fileOut=[dir_out file_out];
if exist(fileOut,'file'), delete(fileOut), end
MITprof_write(fileOut,MITprof);

%specify atlas names:
ncid=ncopen(fileOut,'write');
ncaddAtt(ncid,'prof_Testim','long_name','pot. temp. atlas (OCCA | PHC in arctic| WOA in marginal seas)');
ncaddAtt(ncid,'prof_Sestim','long_name','salinity atlas (OCCA | PHC in arctic| WOA in marginal seas)');
ncclose(ncid);

%print statement:
fprintf(['file: ' file_out ' \n has been processed \n']);


