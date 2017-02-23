function []=MITprof_global(varargin);
% 
% MITPROF_GLOBAL calls gcmfaces_global, adds MITprof paths, adds
%    defines MITprof_climdir and MITprof_griddir in myenv, and 
%    adds myenv (global variable) to caller routine workspace

%get/define global variables:
gcmfaces_global;

%take care of path:
test0=which('MITprof_load.m');
if isempty(test0);
    test0=which('MITprof_global.m'); ii=strfind(test0,filesep);
    mydir=test0(1:ii(end));
    %
    addpath(fullfile(mydir));
    addpath(fullfile(mydir,'MITprof_prepare'));
    addpath(fullfile(mydir,'MITprof_IO'));
    addpath(fullfile(mydir,'MITprof_misc'));
    addpath(fullfile(mydir,'MITprof_calc'));
    addpath(fullfile(mydir,'ecco_v4'));
    addpath(fullfile(mydir,'MITprof_devel'));
end;

%environment variables:
if ~isfield(myenv,'MITprof_dir');
    test0=which('MITprof_global.m'); ii=strfind(test0,filesep);
    myenv.MITprof_dir=test0(1:ii(end));
    %
    gridDir='';
    tmpDir=fullfile(myenv.gcmfaces_dir,'..','GRID',filesep);
    if isdir(tmpDir); gridDir=tmpDir; end;
    tmpDir=fullfile(myenv.gcmfaces_dir,'..','nctiles_grid',filesep);
    if isdir(tmpDir); gridDir=tmpDir; end;
    if isdir('GRID/'); gridDir='GRID/'; end;
    if isdir('nctiles_grid/'); gridDir='nctiles_grid/'; end;

    if isempty(gridDir); 
     fprintf('\n please indicate the ECCO v4 grid directory (e.g., ''nctiles_grid/'') \n\n');
     fprintf('   It can be obtained as follows: \n');
     fprintf('   wget --recursive ftp://mit.ecco-group.org/ecco_for_las/version_4/release2/nctiles_grid/ .\n');
     fprintf('   mv mit.ecco-group.org/ecco_for_las/version_4/release2/nctiles_grid/ . \n\n');
     gridDir=input('');
    end;

    addpath(gridDir);
    fil=which('GRID.0001.nc');
    if isempty(fil); fil=which('XC.meta'); end;
    if isempty(fil); error('could not find grid'); end;
    myenv.MITprof_griddir=[fileparts(fil) filesep];
    %
    climDir='';    
    tmpDir=fullfile(myenv.gcmfaces_dir,'sample_input','OCCAetcONv4GRID',filesep);
    if isdir(tmpDir); climDir=tmpDir; end;
    tmpDir=fullfile(myenv.MITprof_dir,'..','gcmfaces_climatologies',filesep);
    if isdir(tmpDir); climDir=tmpDir; end;
    tmpDir=fullfile('sample_input','OCCAetcONv4GRID',filesep);
    if isdir(tmpDir); climDir=tmpDir; end;
    tmpDir=fullfile('gcmfaces_climatologies',filesep);
    if isdir(tmpDir); climDir=tmpDir; end;

    addpath(climDir);
    fil=which('sigma_T_mad_feb2013.bin');
    if isempty(fil);
     fprintf('\n please indicate the climatologies directory (e.g., ''gcmfaces_climatologies/'') \n\n');
     fprintf('   It can be obtained as follows: \n');
     fprintf('   wget --recursive ftp://mit.ecco-group.org/gforget/OCCAetcONv4GRID .\n');
     fprintf('   mv mit.ecco-group.org/gforget/OCCAetcONv4GRID gcmfaces_climatologies \n\n');
     climDir=input('');
    end;
 
    addpath(climDir);
    fil=which('sigma_T_mad_feb2013.bin');
    if isempty(fil); error('could not find sigma_T_mad_feb2013.bin'); end;
    myenv.MITprof_climdir=[fileparts(fil) filesep];

end;

%send to workspace:
evalin('caller','global mygrid myenv');

