function [profileCur]=profiles_prep_convert(dataset,profileCur);
%[profileCur]=profiles_prep_convert(dataset,profileCur);
%	applies lat/lon/depth/temp conversions
%	to profileCur depending on dataset specs

%check lat/lon ranges:
profileCur.lonlatISbad=0;
if profileCur.lat<-90|profileCur.lat>90; profileCur.lonlatISbad=1; warning('wrong latitude'); end;
if profileCur.lon<-180|profileCur.lon>360; profileCur.lonlatISbad=1;  warning('wrong longitude'); end;

%fix lon range if necessary:
if ~profileCur.lonlatISbad&profileCur.lon>180; profileCur.lon=profileCur.lon-360; end;
if profileCur.lonlatISbad; profileCur.lon=0; profileCur.lat=-89.99; end;

%convert pressure to depth (if necessary)
if dataset.inclZ==0;
        p=profileCur.p;
        tmp1=find(~isnan(p));
        if ~isempty(tmp1);
                p( tmp1 ) = sw_dpth(p(tmp1),profileCur.lat);
        end;
        profileCur=setfield(profileCur,dataset.var_out{1},p);
end

%convert T in situ to T potential (if necessary)
if dataset.TPOTfromTINSITU==1;
        tmpP=0.981*1.027*getfield(profileCur,dataset.var_out{1}); 
        tmpT=getfield(profileCur,dataset.var_out{2});
        tmpS=35*ones(size(tmpT));
        tmpIND=find(tmpT~=dataset.fillval);
        if ~isempty(tmpIND)
                tmpT(tmpIND)=sw_ptmp(tmpS(tmpIND),tmpT(tmpIND),tmpP(tmpIND),0);
        end
        profileCur=setfield(profileCur,dataset.var_out{2},tmpT);
end


