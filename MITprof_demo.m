clear all

gcmfaces_global;
myenv.verbose=1;

fprintf('\n\n basic MITprof test: started... \n');

if myenv.verbose;
fprintf('\nadding directories to your path\n');
fprintf('===============================\n\n')
end;
MITprof_global;

if myenv.verbose;
fprintf('\nloading  reference grid and climatology\n')
fprintf('========================================\n\n')
end;
profiles_prep_load_fields;

if myenv.verbose;
fprintf('\nrunning main program on sample data sets\n')
fprintf('========================================\n\n')
end;

%select the data source (and specific params) => wod05 sample
dataset=profiles_prep_select('wod05','90CTD');
%process it
profiles_prep_main(dataset);
%
fil=[dataset.dirOut dataset.fileOut];
if ~isempty(dir(fil));
  fprintf(['\n\n wod05 sample -- done -- ' fil ' was created \n\n']);
else;
  warning(['wod05 sample -- SKIPPED -- ' fil ' was NOT created \n\n']);
end;

%select the data source (and specific params) => argo sample
dataset=profiles_prep_select('argo','sample'); 
%process it
profiles_prep_main(dataset);
%
fil=[dataset.dirOut dataset.fileOut];
if ~isempty(dir(fil));
  fprintf(['\n\n argo sample -- done -- ' fil ' was created \n\n']);
else;
  warning(['argo sample -- SKIPPED -- ' fil ' was NOT created \n\n']);
end;

%select the data source (and specific params) => odv sample
dataset=profiles_prep_select('odv','ODVcompact_sample');
%process it
profiles_prep_main(dataset);
%
fil=[dataset.dirOut dataset.fileOut];
if ~isempty(dir(fil));
  fprintf(['\n\n odv sample -- done -- ' fil ' was created \n\n']);
else;
  warning(['odv sample -- SKIPPED -- ' fil ' was NOT created \n\n']);
end;

fprintf('\n basic MITprof test: completed. \n');

