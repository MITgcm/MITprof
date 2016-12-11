
MITprof_global;

fprintf('strike return after visualizing each plot is 0\n');

for ii=1:3;
if ii==1; nameSample='argo'; nameFile='argo_sample.nc';
elseif ii==2; nameSample='wod05'; nameFile='wod05_CTD_1990s.nc';
elseif ii==3; nameSample='odv'; nameFile='ODVcompact_sample_MITprof.nc';
end;

MITprof_ref=MITprof_read([myenv.MITprof_dir 'sample_files/reference_results/' nameFile]);
MITprof_new=MITprof_read([myenv.MITprof_dir 'sample_files/' nameSample '_sample/processed/' nameFile]);

figureL; imagesc(MITprof_new.prof_T-MITprof_ref.prof_T); colorbar; title('prof_T'); pause; close;
figureL; imagesc(MITprof_new.prof_Testim-MITprof_ref.prof_Testim); colorbar; title('prof_Testim'); pause; close;
figureL; imagesc((MITprof_new.prof_Tweight-MITprof_ref.prof_Tweight)./MITprof_ref.prof_Tweight); colorbar; title('prof_Tweight'); pause; close;
figureL; imagesc(MITprof_new.prof_Tflag-MITprof_ref.prof_Tflag); colorbar; title('prof_Tflag'); pause; close;

figureL; imagesc(MITprof_new.prof_S-MITprof_ref.prof_S); colorbar; title('prof_S'); pause; close;
figureL; imagesc(MITprof_new.prof_Sestim-MITprof_ref.prof_Sestim); colorbar; title('prof_Sestim'); pause; close;
figureL; imagesc((MITprof_new.prof_Sweight-MITprof_ref.prof_Sweight)./MITprof_ref.prof_Sweight); colorbar; title('prof_Sweight'); pause; close;
figureL; imagesc(MITprof_new.prof_Sflag-MITprof_ref.prof_Sflag); colorbar; title('prof_Sflag'); pause; close;

end;

