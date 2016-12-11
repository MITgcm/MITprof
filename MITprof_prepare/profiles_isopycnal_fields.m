function []=profiles_isopycnal_fields(dataset); 
%1) compute density at depth levels (as in diags_COR1)
%2) interpolate density to target grid (as in profiles_prep_weights & profiles_prep_tests_cmpatlas)

if ~strcmp(dataset.coord,'sig0')&~strcmp(dataset.coord,'sig1'); 
  error('not implemeneted yet'); 
end;

gcmfaces_global; global atlas sigma;

dirAtlases=[myenv.gcmfaces_dir 'sample_input/OCCAetcONv4GRID/'];
atlasT=['T_OWPv1_M_eccollc_90x50_' dataset.coord '.bin'];
atlasS=['S_OWPv1_M_eccollc_90x50_' dataset.coord '.bin'];
atlasD=['D_OWPv1_M_eccollc_90x50_' dataset.coord '.bin'];
sigmaT=['sigma_T_mad_feb2013_' dataset.coord '.bin'];
sigmaS=['sigma_S_mad_feb2013_' dataset.coord '.bin'];

nr=length(dataset.z_std);
tmp1=read2memory([dirAtlases atlasT],[90 1170 nr 12]);
tmp1(tmp1==0)=NaN;
atlas.T{1}=convert2array(convert2gcmfaces(tmp1));

nr=length(dataset.z_std);
tmp1=read2memory([dirAtlases atlasS],[90 1170 nr 12]);
tmp1(tmp1==0)=NaN;
atlas.S{1}=convert2array(convert2gcmfaces(tmp1));

tmp1=read2memory([dirAtlases atlasD],[90 1170 nr 12]);
tmp1(tmp1==0)=NaN;
atlas.D{1}=convert2array(convert2gcmfaces(tmp1));

nr=length(dataset.z_std);
tmp1=read2memory([dirAtlases sigmaT],[90 1170 nr]);
tmp1(tmp1==0)=NaN;
sigma.T=convert2array(convert2gcmfaces(tmp1));

nr=length(dataset.z_std);
tmp1=read2memory([dirAtlases sigmaS],[90 1170 nr]);
tmp1(tmp1==0)=NaN;
sigma.S=convert2array(convert2gcmfaces(tmp1));

mygrid.RC=-dataset.z_std;%negative sign follows from gcm convention : RC=-depth

