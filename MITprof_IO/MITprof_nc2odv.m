function MITprof_nc2odv(fileIn,varargin)
% function MITprof_nc2odv(fileIn,[fileOut])
%
%   convert a file in MITprof netcdf format into an ODV spreadsheet.
%   fileIn: path (absolute or relative) to MITprof netcdf file
%   fileOut: path (absolute or relative) to ODV spreadsheet.
%       use a .txt prefix (either added or replaced in fileOut name)
%       by default, fileOut is the same than fileIn but with a .txt suffix
%       if the file already exist, it will be replaced.


fileOut=fileIn;
if nargin>1, fileOut=varargin{1}; end

[pathstr, name, ext] = fileparts(fileIn);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
fileIn=[pathstr '/' name ext];

[pathstr, name, ext] = fileparts(fileOut);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
if isempty(ext) | ~strcmp(ext,'.txt'), ext='.txt'; end
fileOut=[pathstr '/' name ext];




dat=datestr(now,'yyyy-mm-ddTHH:MM:SS');

str={'//<Version>ODV Spreadsheet V4.0</Version>'
['//<CreateTime>' dat '</CreateTime>']
['//<Software>MITprof on Matlab ' version '</Software>']
['//<Source>' fileIn '</Source>']
'//<DataField>Ocean</DataField>'
'//<DataType>Profiles</DataType>'
'//'
};

% open fileOut
fid=fopen(fileOut,'w');

% write headerlines
for kk=1:length(str)
fprintf(fid,'%s\n',str{kk});
end

% load fileIn
M=MITprof_load(fileIn);

str=['Cruise	Station	Type	yyyy-mm-ddThh:mm:ss.sss	' ...
    'Longitude [degrees_east]	Latitude [degrees_north]	' ...
    'Depth [m]	QV:WOD	Temperature [¬?C]	QV:WOD	Salinity [psu]	QV:WOD	QV:ODV:SAMPLE'];
fprintf(fid,'%s\n',str);
format_head='%s\t%s\t%s\t%s\t%6.4f\t%6.4f\t';
format_nohead='\t\t\t\t\t\t';
format_TS='%3.1f\t0\t%6.4f\t%d\t%6.4f\t%d\t1\n';
format_Tonly='%3.1f\t0\t%6.4f\t%d\t\t\t1\n';
format_Sonly='%3.1f\t0\t\t\t%6.4f\t%d\t1\n';
for ii=1:length(M.prof_lon),
    prof_descr=M.prof_descr{ii};
    I=strfind(prof_descr,'//');
    cruise=prof_descr(1:I-1);
    station=prof_descr(I+2:end);
    type='B';
    dat=datestr(M.prof_date(ii),'yyyy-mm-ddTHH:MM:SS');
    lon=M.prof_lon(ii);
    lat=M.prof_lat(ii);
    D=M.prof_depth;
    T=M.prof_T(ii,:);
    Tflag=M.prof_Tflag(ii,:);
    S=M.prof_S(ii,:);
    Sflag=M.prof_Sflag(ii,:);
    iFormat=(1:length(D))*0;
    Its=find(~isnan(T)&~isnan(S));iFormat(Its)=1;
    It=find(~isnan(T)&isnan(S));iFormat(It)=2;
    Is=find(isnan(T)&~isnan(S));iFormat(Is)=3;
    I=find(iFormat~=0);
    if length(I)==0, continue, end
    pp=I(1);
    switch iFormat(pp)
        case 1
            fprintf(fid,[format_head format_TS], ...
                cruise,station,type,dat,lon,lat,D(pp),T(pp),Tflag(pp),S(pp),Sflag(pp));
        case 2
            fprintf(fid,[format_head format_Tonly], ...
                cruise,station,type,dat,lon,lat,D(pp),T(pp),Tflag(pp));
        case 3
            fprintf(fid,[format_head format_Sonly], ...
                cruise,station,type,dat,lon,lat,D(pp),S(pp),Sflag(pp));
    end
    for ii=2:length(I),
        pp=I(ii);
        switch iFormat(pp)
            case 1
                fprintf(fid,[format_nohead format_TS], ...
                    D(pp),T(pp),Tflag(pp),S(pp),Sflag(pp));
            case 2
                fprintf(fid,[format_nohead format_Tonly], ...
                    D(pp),T(pp),Tflag(pp));
            case 3
                fprintf(fid,[format_nohead format_Sonly], ...
                    D(pp),S(pp),Sflag(pp));
        end
    end
end

fclose(fid);

