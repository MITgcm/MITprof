
p=genpath('gcmfaces'); addpath(p);
p=genpath('MITprof'); addpath(p);

MITprof_global;
YY=[2016:2017];
BB={'atlantic','indian','pacific'};
for bb=1:3;
bas=BB{bb};
for yy=YY;
  dataset=profiles_prep_select('argo',{bas,yy});
  profiles_prep_main(dataset);
end;
end;

