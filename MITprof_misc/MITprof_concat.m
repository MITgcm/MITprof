function [MITprof]=MITprof_concat(MITprof1,MITprof2);
%   [MITprof]=MITprof_concat(MITprof1,MITprof2);
%   concatenates MITprof1 and MITprof2, which mut 
%   have the same vertical grid
%

MITprof=MITprof1;
fldNames=fieldnames(MITprof);

%check that the vertical grids of MITprof1 and MITprof2 are the same:
%--------------------------------------------------------------------
tmp1=MITprof1.prof_depth; tmp2=MITprof2.prof_depth;
if length(tmp1)~=length(tmp2);
    error('vertical grids differ => cannot concatenate');
else;
    if sum(tmp1~=tmp2)>0;
        error('vertical grids differ => cannot concatenate');
    end;
end;

%concatenate:
%------------
for iFld=1:length(fldNames);
    eval(['tmp1=MITprof1.' fldNames{iFld} ';']);
    eval(['tmp2=MITprof2.' fldNames{iFld} ';']);
    if ~strcmp(fldNames{iFld},'prof_depth');
        tmp1=[tmp1;tmp2];
    end;
    eval(['MITprof.' fldNames{iFld} '=tmp1;']);
end;

%add a couple things:
%--------------------
MITprof.np=length(MITprof.prof_lon);
MITprof.nr=length(MITprof.prof_depth);
MITprof.list_descr=unique(MITprof.prof_descr);
MITprof.nd=length(MITprof.list_descr);

