function [xh,yh,zh,varargout]=MITprof_pdf(x,xBinCenters,y,yBinCenters,varargin);
%input:
%       x/y         position vectors or 2D arrays
%       xBinCenters position bin centers
%       yBinCenters position bin centers
%       choiceStat  [optional] type of statistic (pdf, hist, sum, mean, or var)
%       z           [optional] data vector or 2D array
%
%note:  all inputs are assumed to have be nan-masked accordingly
%
%output:
%       xh/yh are the position arrays for the historgam bin centers
%       zh is the 2D histogram

warning('off','MATLAB:dsearch:DeprecatedFunction');

gcmfaces_global;

if ~isfield(myenv,'useDelaunayTri');
    myenv.useDelaunayTri=~isempty(which('DelaunayTri'));
end;

if nargin>4; choiceStat=varargin{1}; else; choiceStat='pdf'; end;
if nargin>5; z=varargin{2}; else; z=[]; end;

%take care of input dimensions:
if size(x,1)==1; x=x'; end; if size(y,1)==1; y=y'; end;
%
if size(y,2)==1; %x is array => make sure y is so
    if size(x,2)==size(y,1); 
        y=ones(size(x,1),1)*y';
    else;
        y=y*ones(1,size(x,2));
    end;
end;
%
if size(x,2)==1; %y is array => make sure x is so
    if size(y,2)==size(x,1); 
        x=ones(size(y,1),1)*x';
    else;
        x=x*ones(1,size(y,2));
    end;
end;
%
if size(z,2)>1;%z is array => make sure x/y are so
    if size(x,2)==1&size(x,1)==size(z,1); x=x*ones(1,size(z,2)); end;
    if size(x,2)==1&size(x,1)==size(z,2); x=ones(size(z,1),1)*x'; end;
    %
    if size(y,2)==1&size(y,1)==size(z,1); y=y*ones(1,size(z,2)); end;
    if size(y,2)==1&size(y,1)==size(z,2); y=ones(size(z,1),1)*y'; end;
end;
if isempty(z); z=NaN*x; end;%to facilitate vector length tests
%switch to vector form:
x=x(:); y=y(:); z=z(:);
%check vectors length:
if length(x)~=length(y)|length(x)~=length(z)|length(y)~=length(z);
    error('inconsistent diemnsions of [x,y[,z]]');
end;

%prepare output arrays:
if size(xBinCenters,1)==1; xh=xBinCenters'; else; xh=xBinCenters; end;
if size(yBinCenters,1)==1; yh=yBinCenters'; else; yh=yBinCenters; end;
if size(xh,2)>1|size(yh,2)>1; error('inconsistent diemnsions of [xBinCenters yBinCenters]'); end;
xh=xh*ones(1,size(yh,1));
yh=ones(size(xh,1),1)*yh';

%build the histogram
if myenv.useDelaunayTri;
    %the new way, using DelaunayTri&nearestNeighbor
    mytri.TRI=DelaunayTri(xh(:),yh(:));
else;
    TRI=delaunay(xh,yh,{'QJ'}); nxy = prod(size(xh));
    Stri=sparse(TRI(:,[1 1 2 2 3 3]),TRI(:,[2 3 1 3 1 2]),1,nxy,nxy);
end;

%compute grid point vector associated with lon/lat vectors
if nargin>5; ii=find(~isnan(x.*y.*z)); else; ii=find(~isnan(x.*y)); end;
x=x(ii); y=y(ii); z=z(ii);
if myenv.useDelaunayTri;
    ik = mytri.TRI.nearestNeighbor(x,y);
else;
    ik = dsearch(xh,yh,TRI,x,y,Stri);
end;

%compute bin sums:
nh=zeros(size(xh)); if nargin>5; zh=nh; zh2=zh; end;
for k=1:length(ik)
    nh(ik(k))=nh(ik(k))+1;
    if nargin>5;
        zh(ik(k))=zh(ik(k))+z(k);
        zh2(ik(k))=zh2(ik(k))+z(k)^2;
    end;
end  % k=1:length(ik)
ii=find(nh(:)==0); nh(ii)=NaN;
if nargin>5; zh(ii)=NaN; zh2(ii)=NaN; end;

%compute output:
if strcmp(choiceStat,'pdf'); %hist + normalization along second dimension
    zh=nh; zh(isnan(zh))=0;
    %normalize by total number of samples
    zh=zh./(nansum(zh,2)*ones(1,size(zh,2)));
    %normalize by delta(yh) => pdf
    tmp2=diff(yh,1,2);
    tmp2=0.5*(tmp2(:,1:end-1)+tmp2(:,2:end));
    tmp2=[tmp2(:,1) tmp2 tmp2(:,end)];
    zh=zh./tmp2;
elseif strcmp(choiceStat,'hist');
    zh=nh;
elseif strcmp(choiceStat,'sum');
    zh=zh;
elseif strcmp(choiceStat,'mean');
    zh=zh./nh;
elseif strcmp(choiceStat,'var');
    zh=zh2./nh-(zh./nh).^2;
end;

if nargout>3; 
    varargout{1}=nh;
else;
    varargout={};
end;

%for debugging purposes:
if 0; figure; pcolor(xh,yh,zh); colorbar; end;

warning('on','MATLAB:dsearch:DeprecatedFunction');

