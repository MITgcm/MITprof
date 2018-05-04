function [profileCur]=profiles_prep_tests_basic(dataset,profileCur);
% [profileCur]=profiles_prep_tests_basic(dataset,profileCur)
%   basic range and resolution tests
%
% set profilCur.t_test (and profilCur.s_test) following the code:
%   0 = valid data
%   1 = not enough data near standard level
%   2 = absurd sal value
%   3 = doubtful profiler (based on our own evaluations)
%   4 = doubtful profiler (based on Argo grey list)
%   5 = high climatology/atlas cost - all four of them
%   6 = bad profile location, date, or pressure
%

%test for 'not enough data near standard level'
z=getfield(profileCur,dataset.var_out{1});
tmp1=ones(size(z))'*dataset.z_top-z'*ones(size(dataset.z_top));
tmp2=ones(size(z))'*dataset.z_bot-z'*ones(size(dataset.z_bot));
tmp1=tmp1<0; tmp2=tmp2>=0; tmp3=sum(tmp1.*tmp2,1);
for ii=2:length(dataset.var_out);
    eval(['t_std=profileCur.' dataset.var_out{ii} '_std;']);
    t_test=zeros(size(t_std));
    if dataset.doInterp; t_test((tmp3<=0)&(t_std~=dataset.fillval))=1; end;
    eval(['profileCur.' dataset.var_out{ii} '_test=t_test;']);
end;

%test for "absurd" salinity values :
%this test needs to be revisited
ii=find(strcmp(dataset.var_out,'S'));
if ~isempty(ii);
    s_std=getfield(profileCur,[dataset.var_out{ii} '_std']);
    s_test=getfield(profileCur,[dataset.var_out{ii} '_test']);
    s_test(find( (s_std>42)&(s_std~=dataset.fillval) ))=2;
    s_test(find( (s_std<15)&(s_std~=dataset.fillval) ))=2;
    profileCur=setfield(profileCur,[dataset.var_out{ii} '_std'],s_std);
    profileCur=setfield(profileCur,[dataset.var_out{ii} '_test'],s_test);
end;

%bad pressure flag:
if profileCur.isBAD;
    for ii=2:length(dataset.var_out);
        tmp1=dataset.var_out{ii};
        eval(['profileCur.' tmp1 '_test(:)=10*profileCur.' tmp1 '_test(:)+6;']);
        %eval(['profileCur.' tmp1 '_std(:)=dataset.fillval;']);
    end;
end;

if isfield(profileCur,'DATA_MODE')&isfield(dataset,'greyList');
    
    test1=~strcmp(profileCur.DATA_MODE,'D');%is real time profile ('R' or 'A')
    test2=sum(strcmp(dataset.greyList.pnum,profileCur.pnum_txt));%is in grey list
    if test1&test2;
        II=find(strcmp(dataset.greyList.pnum,profileCur.pnum_txt));
        for ii=II;
            time0=datenum(dataset.greyList.start{ii});
            timeP=datenum(num2str(profileCur.ymd*1e6+profileCur.hms),'yyyymmddHHMMSS');
            if (time0<timeP);
                for ii=2:length(dataset.var_out);
                    tmp1=dataset.var_out{ii};
                    eval(['profileCur.' tmp1 '_test(:)=10*profileCur.' tmp1 '_test(:)+4;']);
                end;
            end;
        end;
    end;
    
end;


