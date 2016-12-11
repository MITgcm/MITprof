function [grid,atlas]=model_load(model,varargin);
% [grid,atlas]=model_load(model,[reload]);
%
%   model is a string used to select the model to be loaded
%       'OCCA' : ECCOv4 grid + OCCA atlas
%       'SOSE59' : SOSE59 grid + atlas
%
%	if reload=0 (default), variables are loaded from .mat files
%	if reload=1 , variables are loaded from original files, and saved in
%       the matlab form.
%
%   - grid ("model"_grid.mat)
%       mygrid : structure containing XC, YC, RAC and RC
%       mytri : information used for delaunay triangulation
%       MYBASININDEX : basin index
%
%   - state/variance reference climatologies ("model"_atlas.mat)
%       atlas : T/S atlas in a structure format
%           atlas.T, atlas.S are cells of 4-dim arrays with monthly values
%
% gcmfaces toolbox must be working
%

% process arguments
reload=0;
if nargin>1,
    reload=varargin{1};
end

% directory where .mat model files are stored
dir_model='/Users/roquet/Documents/MATLAB/MITprof/model_database/';


% try to load .mat files
if reload==0 & exist([dir_model model '_grid.mat'],'file') & exist([dir_model model '_atlas.mat'],'file')
    % load grid and atlas
    load([dir_model model '_grid.mat']);
    load([dir_model model '_atlas.mat']);
    return
    
end


% if reload~=0 or fields are not found, generation of .mat files

% protect global grid variables
global mygrid mytri MYBASININDEX
mygrid1=mygrid; mytri1=mytri; MYBASININDEX1=MYBASININDEX;

switch model
    case 'OCCA',
        % atlas made combining OCCA, PHC in arctic and WOA in marginal seas
        %   using the grid ECCOv4, monthly values
        
        % set directories:
        dir_in='/Users/roquet/Documents/MATLAB/MITprof/climatology/';
        dirGrid=[dir_in 'GRIDv4/'];
        fileBasin=[dir_in 'basin_masks_eccollc_90x50.bin'];
        fileT=[dir_in 'T_OWPv1_M_eccollc_90x50.bin'];
        fileS=[dir_in 'S_OWPv1_M_eccollc_90x50.bin'];
        
        %load and save grid :
        grid_load(dirGrid,5,'compact'); gcmfaces_bindata;
        mygrid=rmfield(mygrid,{'XG','YG','RAC','RAZ','DXC','DYC','DXG','DYG'});
        mygrid=rmfield(mygrid,{'hFacC','hFacW','hFacS','Depth','AngleCS','AngleSN'});
        mygrid=rmfield(mygrid,{'hFacCsurf','mskW','mskS','DRC','DRF','RF'});
        % list_param={'XC','YC','RAC','RC'};
        % grid_load(dirGrid,5,list_param);
        % gcmfaces_bindata;
        MYBASININDEX=convert2array(read_bin(fileBasin,1,0));
        grid.name=model;
        grid.mygrid=mygrid;
        grid.mytri=mytri;
        grid.MYBASININDEX=MYBASININDEX;
        
        % read T/S Atlas
        fldT=mygrid.mskC; fldT(:)=0; fldS=fldT;
        for tt=1:12;
            fldT(:,:,:,tt)=read_bin(fileT,tt).*mygrid.mskC;
            fldS(:,:,:,tt)=read_bin(fileS,tt).*mygrid.mskC;
        end;
        atlas.name=model;
        atlas.T={convert2array(fldT)};  atlas.S={convert2array(fldS)};
        
    case 'SOSE59',
        % 59th iteration of SOSE, annual climatology
        
        % set directories:
        dir_in='/Users/roquet/Documents/donnees/MODEL/SOSE59/';
        dirGrid=[dir_in 'grid/'];

        %load grid :
        grid_load(dirGrid,1,'straight'); gcmfaces_bindata;
        mygrid=rmfield(mygrid,{'XG','YG','RAC','RAZ','DXC','DYC','DXG','DYG'});
        mygrid=rmfield(mygrid,{'hFacC','hFacW','hFacS','Depth','AngleCS','AngleSN'});
        mygrid=rmfield(mygrid,{'hFacCsurf','mskW','mskS','DRC','DRF','RF'});
        % list_param={'XC','YC','RAC','RC'};
        % grid_load(dirGrid,1,list_param);
        % gcmfaces_bindata;
        
        MYBASININDEX=convert2array(mygrid.mskC(:,:,1));
        MYBASININDEX(isnan(MYBASININDEX))=0;
        
        grid.name=model;
        grid.mygrid=mygrid;
        grid.mytri=mytri;
        grid.MYBASININDEX=MYBASININDEX;

        % load atlas
        atlas_file=[dir_in 'SOSE59_TS.mat'];
        load(atlas_file);
        atlas.name=model;
        atlas.T={THETA_SOSE59}; 
        atlas.S={SALT_SOSE59};
        
    otherwise
        error('not a valid model string');
end

% save .mat files
save([dir_model model '_grid.mat'],'grid');
save([dir_model model '_atlas.mat'],'atlas');

% reload global grid variables
mygrid=mygrid1; mytri=mytri1; MYBASININDEX=MYBASININDEX1;
    

