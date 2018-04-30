function [dataset]=profiles_prep_select(datasetname,subset,varargin);
%[dataset]=profiles_prep_select(datasetname,subset,'PropertyName',PropertyValue);
%       Specifies 'dataset' structure used as argument of
%           profiles_prep_main.m to process hydrographic data.
%           Contains a description of the data to process and processing options.
%
%  datasetname: type of input data. specify which script will be used in
%   the folder profiles_IO_external to read the data:
%       ['profiles_read_' datasetname '.m']
%       Can be 'argo','wod05','seals' or 'odv'
%
%  subset: name of the dataset used in the output name.
%
%typical calling sequence :
%
%MITprof_global;
%YY=[1992:2016];
%BB={'atlantic','indian','pacific'};
%for bb=1:3;
%bas=BB{bb};
%for yy=YY; 
%  dataset=profiles_prep_select('argo',{bas,yy});
%  profiles_prep_main(dataset);
%end;
%end;

gcmfaces_global;


% vertical levels
Z_STD=[5:10:185 200:20:500 550:50:1000 1100:100:6000];

%initialize empty data set description:
dataset.name=datasetname;
dataset.subset=subset;
dataset.dirIn='';
dataset.fileInList={};
dataset.dirOut='';
dataset.fileOut='';
dataset.depthrange=[];
dataset.z_std=[];
dataset.inclZ=0;%0 means that only P is provided, which we will convert to depth
dataset.inclT=0;
dataset.inclS=0;
dataset.inclU=0;
dataset.inclV=0;
dataset.inclPTR=0;
dataset.inclSSH=0;
dataset.fillval=-9999.;
dataset.TPOTfromTINSITU=1;%1 means that only in situ T is provided, which we will convert to pot T
dataset.coord='depth';%depth as a coordinate
dataset.doInterp=1;
dataset.addGrid=1;
dataset.var_out={'depth','T','S'};%depth,T,S need to be placed first
dataset.outputMore=0;
dataset.method='interp';

if myenv.verbose==2;
    fprintf(['by default, we assume that \n'...
        '   the data vertical coordinate is P \n' ...
        '   temperature data is in situ (rather than potential) \n' ...
        '   salinity data exists\n'...
        '   (you probably want to make sure about those \n things when processing a new data set). \n\n\n']);
end;

%=================================================================================

if strcmp(datasetname,'argo')&strcmp(subset,'sample');
  datasetname=[datasetname '_sample']; 
end;

switch datasetname

        %=================================================================================

    case 'argo_sample',

        %Argo profiles:
        %--------------
        dataset.dirIn=[myenv.MITprof_dir 'sample_files/argo_sample/'];
        dataset.fileInList=dir([dataset.dirIn '*.nc']);
        dataset.dirOut=[myenv.MITprof_dir 'sample_files/argo_sample/processed/'];
        dataset.fileOut=['argo_' subset];
        dataset.depthrange=[0 2000];
        dataset.inclT=1;
        dataset.inclS=1;

        %=================================================================================
    
    case 'argo',

        %Argo profiles:
        %--------------

        dir0=[pwd filesep];
        dataset.dirIn=[dir0 'ftp.ifremer.fr/ifremer/argo/geo/' subset{1} '_ocean/'];
        %year range
        if length(subset)==2; subset{3}=subset{2}; end;
        YY=subset{2}:subset{3};
        if length(YY)>1;
          DD=[num2str(YY(1)) 'to' num2str(YY(end))];
        else;
          DD=num2str(YY(1));
        end;
        %
        for yy=YY;
          for mm=1:12;
            tmp1=sprintf('%04d/%02d/',yy,mm);
            tmp2=dir([dataset.dirIn tmp1 '*.nc']);
            for ff=1:length(tmp2); tmp2(ff).name=[tmp1 tmp2(ff).name]; end;
            if isempty(dataset.fileInList); dataset.fileInList=tmp2;
            else; dataset.fileInList=[dataset.fileInList;tmp2];
            end;
          end;
        end;
        dataset.dirOut=[dir0 'processed_' dataset.coord '/' DD '/'];
        dataset.fileOut=['argo_' subset{1} '_' DD];
        dataset.depthrange=[0 2000];
        dataset.inclT=1;
        dataset.inclS=1;

        %=================================================================================
        
    case 'wod05',
        
        %data from the World Ocean Data Base 2005:
        %-----------------------------------------
        wod_decade=subset(1:2); wod_instr_code=subset(3:end);
        
        if strcmp(wod_decade,'00'); wod_decade2=['20' wod_decade 's'];
        else; wod_decade2=['19' wod_decade 's']; end;
        
        dataset.dirIn=[myenv.MITprof_dir 'sample_files/wod05_sample/'];
        dataset.fileInList=dir([dataset.dirIn '*' wod_instr_code '*']);
        dataset.dirOut=[myenv.MITprof_dir 'sample_files/wod05_sample/processed/'];
        dataset.fileOut=['wod05_' wod_instr_code '_' wod_decade2];
        dataset.inclZ=1;
        dataset.inclT=1;
        dataset.inclS=1;
        
        if strcmp(wod_instr_code,'OSD')|strcmp(wod_instr_code,'CTD')|strcmp(wod_instr_code,'OTH');
            dataset.depthrange=[0 5400];
        elseif strcmp(wod_instr_code,'PFL');
            dataset.depthrange=[0 2000];
        elseif strcmp(wod_instr_code,'MBT');
            dataset.depthrange=[0 300];
            dataset.inclS=0;
        elseif strcmp(wod_instr_code,'XBT');
            dataset.depthrange=[0 1000];
            dataset.inclS=0;
        else;
            error('un-supported wod instrument code');
        end;%if strfind(wod_instr_code...
        
        %=================================================================================
        
    case 'seals',
        
        % seal data in ARGO format
        dataset.dirIn=[myenv.MITprof_dir 'sample_files/seals_sample/'];
        dataset.fileInList=dir([dataset.dirIn '*' subset '*.nc']);
        dataset.dirOut=[myenv.MITprof_dir 'sample_files/seals_sample/processed/'];
        dataset.fileOut=[datasetname '_' subset '_MITprof'];
        dataset.depthrange=[0 2000];
        dataset.inclT=1;
        dataset.inclS=1;
        
        %=================================================================================
        
    case 'odv',
        
        % seal data in odv format
        dataset.dirIn=[myenv.MITprof_dir 'sample_files/odv_sample/'];
        dataset.fileInList=dir([dataset.dirIn '*.txt']);
        dataset.dirOut=[myenv.MITprof_dir 'sample_files/odv_sample/processed/'];
        dataset.fileOut=[subset '_MITprof'];
        dataset.depthrange=[0 2000];
        dataset.inclZ=1;
        dataset.inclT=1;
        dataset.inclS=1;
        
        %=================================================================================

    case 'odvnc',

        %GLODAPv2 bottle data exported as nectdf using ODV
        dataset.dirIn='ODV-GLODAP-v2/';
        dataset.fileInList=dir([dataset.dirIn 'data_from_GLODAPv2_bottle.nc']);
        dataset.var_in={'DEPTH','TEMPERATURE','SALNTY',subset};
        dataset.dirOut='MITprof-GLODAP-v2/';;
        if strcmp(subset,'pH~_T(p=0,T=25,S)'); subset='pHat025'; end;
        if strcmp(subset,'pH~_T(p,T,S)'); subset='pH'; end;
        dataset.var_out={'depth','T','S',subset};
        dataset.fileOut=['GLODAPv2_' subset '_MITprof.nc'];
        dataset.depthrange=[0 6000];
        dataset.inclT=1;
        dataset.inclS=1;
        dataset.inclZ=1;
                
    otherwise
        error('un-supported data set');
        
end;%if strcmp(datasetname,'wod05')

if ~dataset.inclS;
    dataset.var_out={'depth','T'};%depth,T need to be placed first
end;

% overwrite properties using arguments
if nargin>2
    if mod(nargin,2)==1, error('problem in argument list'); end
    for kk=1:(nargin-1)/2,
        PropertyName=varargin{(kk-1)*2+1};
        PropertyValue=varargin{kk*2};
        dataset=setfield(dataset,PropertyName,PropertyValue);
    end;
end

%if not done yet, set the depth levels now:
if isempty(dataset.z_std);
    kk=find(Z_STD>=dataset.depthrange(1)&Z_STD<=dataset.depthrange(2));
    dataset.z_std=Z_STD(kk);
end;
%set z_top, z_bot:
z_std=dataset.z_std;
tmp1=(z_std(2:end)+z_std(1:end-1))/2;
dataset.z_top=[z_std(1)-(z_std(2)-z_std(1))/2 tmp1];
dataset.z_bot=[tmp1 z_std(end)+(z_std(end)-z_std(end-1))/2];

% determine the output file name, and try to delete it
[pathstr, name, ext] = fileparts([dataset.dirOut dataset.fileOut]);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
if isempty(ext) | ~strcmp(ext,'.nc'), ext='.nc'; end
dataset.fileOut=[name ext];
if exist([dataset.dirOut dataset.fileOut],'file'),
    delete([dataset.dirOut dataset.fileOut]);
end

%create output directory if necessary:
tmp1=dir(dataset.dirOut); if isempty(tmp1); eval(['mkdir ' dataset.dirOut ]); end;

if myenv.verbose;
    fprintf(['\n\n generating file : ' dataset.dirOut dataset.fileOut ' \n']);
    fprintf(['\n depth range : ' num2str(dataset.depthrange) ' \n']);
    fprintf([' compute T pot from T in-situ : ' num2str(dataset.TPOTfromTINSITU) ' \n']);
    fprintf([' compute Z from P : ' num2str(~dataset.inclZ) ' \n']);
    fprintf([' include T : ' num2str(dataset.inclT) ' \n']);
    fprintf([' include S : ' num2str(dataset.inclS) ' \n\n']);
end;


