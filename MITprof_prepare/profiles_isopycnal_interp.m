function [profileCur]=profiles_isopycnal_interp(dataset,profileCur);

%t_Err (s_Err) contains the depth inversion index (depth) that now need t be interpolated


%interpolation for T : 
z_std=dataset.z_std; t_std=NaN*z_std; tE_std=t_std; if dataset.inclS; s_std=t_std; sE_std=t_std; end;
z=profileCur.z; t=profileCur.t; if dataset.inclS; s=profileCur.s; end;
t_ERR=profileCur.t_ERR; if dataset.inclS; s_ERR=profileCur.s_ERR; end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%SPEC STUFF
if ~isempty(t)&length(find(~isnan(z.*t)))>1;
tmp1=find( ~isnan(t) & ~isnan(z) );                     %compact
z_in=z(tmp1); t_in=t(tmp1); tE_in=t_ERR(tmp1);
[z_in,tmp1]=sort(z_in); t_in=t_in(tmp1); tE_in=tE_in(tmp1);%sort
tmp1=[find(z_in(1:end-1)~=z_in(2:end))   length(z_in)];
z_in=z_in(tmp1); t_in=t_in(tmp1); tE_in=tE_in(tmp1);    %avoid duplicate
if length(t_in)>5 %...expected to avoid isolated values
        t_std = interp1(z_in,t_in,z_std);
        tE_std = interp1(z_in,tE_in,z_std);
end
end%if ~isempty(t);
t_std(find(isnan(t_std)))=dataset.fillval; profileCur.t_std=t_std;
tE_std(find(isnan(tE_std)))=dataset.fillval; profileCur.tE_std=tE_std;

%interpolation for S :
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%SPEC STUFF
if dataset.inclS;
if ~isempty(s)&length(find(~isnan(z.*s)))>1;
tmp1=find( ~isnan(s) & ~isnan(z) );                     %compact
z_in=z(tmp1); s_in=s(tmp1); sE_in=s_ERR(tmp1);
[z_in,tmp1]=sort(z_in); s_in=s_in(tmp1); sE_in=sE_in(tmp1);%sort
tmp1=[find(z_in(1:end-1)~=z_in(2:end))   length(z_in)];
z_in=z_in(tmp1); s_in=s_in(tmp1); sE_in=sE_in(tmp1);    %avoid duplicate
if length(s_in)>5
        s_std = interp1(z_in,s_in,z_std);
        sE_std = interp1(z_in,sE_in,z_std);
end
end%if ~isempty(s)
s_std(find(isnan(s_std)))=dataset.fillval; profileCur.s_std=s_std;
sE_std(find(isnan(sE_std)))=dataset.fillval; profileCur.sE_std=sE_std;
end

%interpolation for depth : 
z_std=dataset.z_std; depth_std=NaN*z_std;
z=profileCur.z; depth=profileCur.depth;
if ~isempty(depth)&length(find(~isnan(z.*depth)))>1;
tmp1=find( ~isnan(depth) & ~isnan(z) );                     %compact
z_in=z(tmp1); depth_in=depth(tmp1);
[z_in,tmp1]=sort(z_in); depth_in=depth_in(tmp1); %sort
tmp1=[find(z_in(1:end-1)~=z_in(2:end))   length(z_in)];
z_in=z_in(tmp1); depth_in=depth_in(tmp1);   %avoid duplicate
if length(depth_in)>5 %...expected to avoid isolated values
        depth_std = interp1(z_in,depth_in,z_std);
end
end%if ~isempty(t);
depth_std(find(isnan(depth_std)))=dataset.fillval; profileCur.depth_std=depth_std;

