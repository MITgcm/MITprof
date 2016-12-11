function [profileCur]=profiles_isopycnal_z(dataset,profileCur,choiceDensity);

%aa=which('density'); if isempty(aa); addpath /data4/gforget/matlab_diags/TOOLS/DIVERS/; end;
%aa=which('gamma_n'); if isempty(aa); addpath /data4/gforget/DIAG_ecco/TOOLS/gamma_n/gamma_ml/; end;

kk=find(~isnan(profileCur.t.*profileCur.s.*profileCur.z));

if ~isempty(kk);
 if strcmp(choiceDensity,'gamma'); 
   lon=profileCur.lon; lat=profileCur.lat; if lon<0; lon=lon+180; end;
   if (lon<0|lon>360|lat<-80|lat>64|length(kk)<3);
     profileCur.dens=NaN*profileCur.z;
   else;
     temp = sw_temp(profileCur.s(kk)',profileCur.t(kk)',profileCur.z(kk)',0);
     [g,dgl,dgh] = gamma_n(profileCur.s(kk)',temp,profileCur.z(kk)',profileCur.lon,profileCur.lat);
     g(find(g<-99))=NaN;%get rid of errors
     tmp1=NaN*profileCur.z; tmp1(kk)=g; g=tmp1;%complete profile
     profileCur.dens=g;
   end;
 else;
  [RHOP,RHOIS,RHOR] = density(profileCur.t(kk),profileCur.s(kk),profileCur.z(kk),1000);
  tmp1=NaN*profileCur.z; tmp1(kk)=RHOP; RHOP=tmp1;%complete profile
  tmp1=NaN*profileCur.z; tmp1(kk)=RHOIS; RHOIS=tmp1;%complete profile
  tmp1=NaN*profileCur.z; tmp1(kk)=RHOR; RHOR=tmp1;%complete profile
  if strcmp(choiceDensity,'sig0'); profileCur.dens=RHOP-1000;
  elseif strcmp(choiceDensity,'sig1'); profileCur.dens=RHOR-1000;
  elseif strcmp(choiceDensity,'insitu'); profileCur.dens=RHOIS-1000;
  else; fprintf('error in profiles_prep_switch2isopycnal\n'); return;
  end;
 end;
 profileCur.dens(find(~isreal(profileCur.dens)|~isfinite(profileCur.dens)))=NaN; 
else;
  profileCur.dens=NaN*profileCur.z;
end;

%replace z with density
profileCur.depth=profileCur.z; 
profileCur.z=profileCur.dens;

%check for density inversions:
kk=find(~isnan(profileCur.dens.*profileCur.depth));
tmp_dens=profileCur.dens(kk); tmp_depth=profileCur.depth(kk);
[tmp_depth,kk] = sort(tmp_depth); tmp_dens=tmp_dens(kk);
if length(tmp_dens)>1; test0=100*length(find(diff(tmp_dens)<0))/(length(tmp_dens)-1); else; test0=100; end;
%store in prof.t_ERR and s_ERR: 
profileCur.t_ERR=test0*ones(size(profileCur.t));
profileCur.s_ERR=profileCur.depth;
%t_ERR and s_ERR will be interpolated

if 0; %code to test the various computations
kk=find(~isnan(profileCur.t.*profileCur.s.*profileCur.z));
[profileCur.dens_sig,profileCur.dens_insitu,profileCur.dens_sig1] = density(profileCur.t,profileCur.s,profileCur.z,1000);
[g,dgl,dgh] = gamma_n(profileCur.s',profileCur.t',profileCur.z',profileCur.lon',profileCur.lat');
profileCur.dens_gamman=g';

figure;
subplot(2,2,1); plot(profileCur.dens_insitu(kk),-profileCur.z(kk),'.-'); title('insitu');
subplot(2,2,2); plot(profileCur.dens_sig(kk),-profileCur.z(kk),'.-'); title('sig');
subplot(2,2,3); plot(profileCur.dens_sig1(kk),-profileCur.z(kk),'.-'); title('sig1');
subplot(2,2,4); plot(profileCur.dens_gamman(kk),-profileCur.z(kk),'.-'); title('gamman');
end;

