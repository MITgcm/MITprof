function []=profiles_prep_load_fields(varargin);
% []=profiles_prep_load_fields([loadFromMat,saveToMat]);
%   - object : load grid and atlas data to global variables
%   - optional inputs :
%	if loadFromMat=0 (default) then variables are loaded from gcmfaces/sample_input/ files
%	if loadFromMat=1 then variables are loaded from mat files prepared by users
%       if saveToMat=1 then variables are saved to mat files
%   - result consists of global variables :
%       mygrid : structure containing XC, YC, RAC and RC from the ECCOv4 grid
%       mytri : information used for delaunay triangulation
%       MYBASININDEX : basin index
%       atlas : T/S atlas in a structure format
%           atlas.T, atlas.S are monthly mean 3D T/S climatologies (OCCA by default)
%       sigma : T/S observational standard deviation in a structure format
%           sigma.T and sigma.S are 3D fields (updated Forget and Wunsch 2007 by default)
%           by assumption: the uncertainty fields contain non-zero values
%           (which avoid the complication of handling horiz interpolation here)
%           and we do not mask the data (the model will do this, given a mask)
%   - note : gcmfaces toolbox is required
%

% process arguments
loadFromMat=0;
if nargin==1,
    loadFromMat=varargin{1};
end
saveToMat=0;
if nargin==2,
    saveToMat=varargin{1};
end

%set global variables
gcmfaces_global;
global mytri MYBASININDEX atlas sigma;

% set directories:

%%%%%% part 1 : default usage %%%%%%%

if loadFromMat==0,

    %default directory location
    %dirGrid=myenv.MITprof_griddir;
    dirClim=myenv.MITprof_climdir;
    
    % read grid :
    mygrid=[];
    dir0=[pwd filesep '../GRID/']; test0=~isempty(dir(dir0));
    dir1=[pwd filesep '../nctiles_grid/']; test1=~isempty(dir(dir1));
    if test0; grid_load(dir0,5,'compact');
    elseif test0; grid_load(dir1,5,'nctiles');
    else; grid_load;
    end;
    gcmfaces_bindata;
    disp(['grid was loaded from ' mygrid.dirGrid]);
    mygrid=rmfield(mygrid,{'XG','YG','RAC','RAZ','DXC','DYC','DXG','DYG'});
    mygrid=rmfield(mygrid,{'hFacC','hFacW','hFacS','Depth','AngleCS','AngleSN'});
    mygrid=rmfield(mygrid,{'hFacCsurf','mskW','mskS','DRC','DRF','RF'});
    MYBASININDEX=convert2array(read_bin('v4_basin.bin',1,0));
    
    % read T/S Atlas
    disp(['load atlas from ' dirClim]);
    atlas=[];
    fldT=mygrid.mskC; fldT(:)=0; fldS=fldT;
    for tt=1:12;
        fldT(:,:,:,tt)=read_bin('T_OWPv1_M_eccollc_90x50.bin',tt).*mygrid.mskC;
        fldS(:,:,:,tt)=read_bin('S_OWPv1_M_eccollc_90x50.bin',tt).*mygrid.mskC;
    end;
    atlas.T={convert2array(fldT)};  atlas.S={convert2array(fldS)};
    
    % read T/S variance fields
    disp(['load sigma from ' dirClim]);
    sigma.T=read_bin([dirClim 'sigma_T_nov2015.bin']);
    sigma.S=read_bin([dirClim 'sigma_S_nov2015.bin']);

    % error variance bounds
    for kk=1:size(sigma.T{1},3);
      %cap sigma.T(:,:,kk) to ...
      tmp1=convert2vector(sigma.T(:,:,kk).*mygrid.mskC(:,:,kk));
      tmp1(tmp1==0)=NaN;
      tmp2=prctile(tmp1,5);%... its fifth percentile...
      tmp2=max(tmp2,1e-3);%... or 1e-3 instrumental error floor:
      tmp1(tmp1<tmp2|isnan(tmp1))=tmp2;
      sigma.T(:,:,kk)=convert2vector(tmp1).*mygrid.mskC(:,:,kk);
      %cap sigma.S(:,:,kk) to ...
      tmp1=convert2vector(sigma.S(:,:,kk).*mygrid.mskC(:,:,kk));
      tmp1(tmp1==0)=NaN;
      tmp2=prctile(tmp1,5);%... its fifth percentile...
      tmp2=max(tmp2,1e-3);%... or 1e-3 instrumental error floor:
      tmp1(tmp1<tmp2|isnan(tmp1))=tmp2;
      sigma.S(:,:,kk)=convert2vector(tmp1).*mygrid.mskC(:,:,kk);
    end;

    % convert to array format (for use with mytri)
    sigma.T=convert2array(sigma.T);
    sigma.S=convert2array(sigma.S);

    %min sigma used in feb2013 version:
    %sigTmin=0.25*sigma.T(1,1,:); sigTmin(sigTmin<0.001)=0.001;
    %sigTmin=repmat(sigTmin,[size(sigma.T,1) size(sigma.T,2) 1]);
    %sigma.T(sigma.T<sigTmin)=sigTmin(sigma.T<sigTmin);
    %sigSmin=0.25*sigma.S(1,1,:); sigSmin(sigSmin<0.001)=0.001;
    %sigSmin=repmat(sigSmin,[size(sigma.S,1) size(sigma.S,2) 1]);
    %sigma.S(sigma.S<sigSmin)=sigSmin(sigma.S<sigSmin);
    
end

%%%%%% part 2 : custom usage %%%%%%%

dirGrid=myenv.MITprof_griddir;
mat_grid=[dirGrid 'MITprof_grid.mat'];
dirClim=myenv.MITprof_climdir;
mat_clim=[dirClim 'MITprof_clim.mat'];

if loadFromMat == 1

    if exist(mat_clim,'file') & exist(mat_grid,'file'),

        % load grid, atlas and sigma
        load(mat_grid);
        load(mat_clim);
        return

    else
        error('matlab files could not be found. They need to be generated using profiles_prep_load_fields(1)');
    end
end;

if saveToMat==1;
    disp('save fields')
    save(mat_grid,'mygrid','mytri','MYBASININDEX');
    save(mat_clim,'atlas','sigma');
end;

