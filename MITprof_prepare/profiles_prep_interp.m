function [profileCur]=profiles_prep_interp(dataset,profileCur);
%[profileCur]=profiles_prep_interp(dataset,profileCur);
%	interpolate profileCur to dataset.z_std standard levels

for ii=2:length(dataset.var_out);
    z_std=dataset.z_std;
    t_std=NaN*z_std; e_std=NaN*t_std;
    z=getfield(profileCur,dataset.var_out{1});
    t=getfield(profileCur,dataset.var_out{ii});
    if isfield(profileCur,[dataset.var_out{ii} '_ERR']);
        e=getfield(profileCur,[dataset.var_out{ii} '_ERR']);
    else;
        e=[];
    end;
    %
    if dataset.doInterp&length(find(~isnan(z.*t)))>1;
        tmp1=find( ~isnan(t) & ~isnan(z) );                     %compact
        z_in=z(tmp1);
        t_in=t(tmp1);
        if ~isempty(e); e_in=e(tmp1); end;
        [z_in,tmp1]=sort(z_in);
        t_in=t_in(tmp1);
        if ~isempty(e); e_in=e_in(tmp1); end;%sort
        tmp1=[find(z_in(1:end-1)~=z_in(2:end))   length(z_in)];
        z_in=z_in(tmp1);
        t_in=t_in(tmp1);
        if ~isempty(e); e_in=e_in(tmp1); end;   %avoid duplicate
        if length(t_in)>5 %...expected to avoid isolated values
            t_std = interp1(z_in,t_in,z_std);
            if ~isempty(e); e_std = interp1(z_in,e_in,z_std); end;
        end
    elseif ~dataset.doInterp&length(find(~isnan(z.*t)))>1;
        tmp1=z_std'*(1+0*z)-(1+0*z_std)'*z;
        [II,JJ]=find(tmp1==0);
        if length(II)>1;
            t_std(II)=t(JJ);
            if ~isempty(e); e_std(II)=e(JJ); end;
        end;
    end%if ~isempty(t);
    t_std(find(isnan(t_std)))=dataset.fillval;
    e_std(find(isnan(e_std)))=dataset.fillval;
    
    eval(['profileCur.' dataset.var_out{ii} '_std=t_std;']);
    if ~isempty(e); eval(['profileCur.' dataset.var_out{ii} 'E_std=e_std;']); end;
end;
