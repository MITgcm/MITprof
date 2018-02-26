function [varargout]=MITprof_wrapper(varargin);
% MITPROF_WRAPPER  applies encoded operation to MITprof variables
%                 
%  [myout]=MITprof_wrapper(myprof,myop) applies operation specified 
%  by myop.op_name ('nanmean' by default; options listed below) to 
%  myprof variables listed by suffix in myop.op_vars (all variables 
%  of length myprofmyop.np by default).
%
%  [myout]=MITprof_wrapper(K) obtains myprofmyop from global variable, 
%  subsets according to K (1:myprofmyop.np by default), and returns 
%  the result in vector form. This approach allows bootstrapping.
%
%       myop options:
%          - op_name='mean','std', 'timeave', or 'cycle'
%          - op_vars='prof_T', 'prof_S', or a list {'prof_T','prof_S'}
%          - additional options can be specified depending on op_name
%
%  Example:
%
%       example_MITprof; global myprofmyop; disp(myprofmyop);
%
%       myop.op_name='cycle'; myop.op_tim=[0:7:365]; %myop.op_dt=30;
%       myop.op_vars={'prof_T','prof_Tclim'};
%       myprof=myprofmyop;
%
%       [myout]=MITprof_wrapper(myprof,myop);
%       figure; imagescnan(myout'); colorbar;
%
%       K=[1:myprofmyop.np]; myout = bootstrp(100, @MITprof_wrapper,K);         
%       figure; z=cell2mat(myout); z=z(:,10:myprof.nr:end); hist(z,20);
%

%%

if nargin<=1; 
    global myprofmyop;
    myprof=myprofmyop;
    tmp1=fieldnames(myprofmyop);
    for ii=1:length(tmp1);
      tmp2=tmp1{ii};
      tmp2=tmp2(1:min(3,length(tmp2)));
      if strcmp(tmp2,'op_');
        tmp2=tmp1{ii};
        myop.(tmp2)=myprofmyop.(tmp2);
      end;
    end;
end;

if nargin==1;
    myind=varargin{1};
end;

if nargin==2;
    myprof=varargin{1};
    myop=varargin{2};
end;

if isempty(whos('myind')); 
    myind=[1:myprof.np];
end;
    
if isempty(myprof)|isempty(myop); 
    error('incorrect input specifications'); 
end;
    
if ischar(myop.op_vars); 
    myop.op_vars={myop.op_vars}; 
end;

%%

[myprof]=MITprof_subset(myprof,'list',myind);

%%

if strcmp(myop.op_name,'std');
    for vv=1:length(myop.op_vars);
        tmp1=getfield(myprof,myop.op_vars{vv});
        varargout{vv}=nanstd(tmp1,[],1);
    end;
end;

%%

if strcmp(myop.op_name,'mean');
    for vv=1:length(myop.op_vars);
        tmp1=getfield(myprof,myop.op_vars{vv});
        varargout{vv}=nanmean(tmp1,1);
    end;
end;

%%

if strcmp(myop.op_name,'timeave');
    nt=length(myop.op_tim0); nv=length(myop.op_vars);
    if ~isfield(myop,'op_tim0')|~isfield(myop,'op_tim1');
        error('missing op_tim0, op_tim1 specifications');
        %notes: 
        %(1) I should have defaults! 
        %(2) use the op_tim, op_dt approach?
    end;
    for vv=1:nv;
        tmpIn=getfield(myprof,myop.op_vars{vv});
        tmpOut=NaN*repmat(tmpIn(1,:),[nt 1]);
        for tt=1:nt;
            ii=find(myprof.prof_date>=myop.op_tim0(tt)&myprof.prof_date<=myop.op_tim1(tt));
            tmp1=nanmean(tmpIn(ii,:),1);
            tmp2=sum(~isnan(tmpIn(ii,:)),1);
            tmp1(~tmp2)=NaN; 
            tmpOut(tt,:)=tmp1;
        end;
        varargout{vv}=tmpOut;
    end;
end;


%%

if strcmp(myop.op_name,'cycle');
    tim=myprof.prof_date-datenum([2002 1 1]); tim=mod(tim,365); 
    nt=length(myop.op_tim); nv=length(myop.op_vars);
    if isfield(myop,'op_dt'); 
      dt=myop.op_dt;
    else;
      dt=median(diff(myop.op_tim));
    end;
    for vv=1:nv;
        tmpIn=getfield(myprof,myop.op_vars{vv});
        tmpOut=NaN*repmat(tmpIn(1,:),[nt 1]);
        for tt=1:nt;
            t0=mod(myop.op_tim(tt)-dt/2,365);
            t1=mod(myop.op_tim(tt)+dt/2,365);
            if t1>t0; ii=find(tim<=t1&tim>t0); 
            else; ii=find(tim<=t1|tim>t0);
            end;
            tmp1=nanmean(tmpIn(ii,:),1);
            tmp2=sum(~isnan(tmpIn(ii,:)),1);
            tmp1(~tmp2)=NaN; 
            tmpOut(tt,:)=tmp1;
        end;
        varargout{vv}=tmpOut;
    end;
end;

%%

if nargin<=1&nargout==1;
    varargout{1}=varargout;
end;

