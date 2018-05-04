# Tutorial: 

Here we scan, visualize, and save Argo profile locations in the Pacific. 

## Preliminary Steps


- Dowload the `Argo` data from `ftp.ifremer.fr`.
- Install `MITprof` toolbox that contains `profiles_read_argo.m`.
- Launch `Matlab` or `Octave`.

To this end, open a terminal window and execute:

``` 
wget -r ftp://ftp.ifremer.fr/ifremer/argo/geo/pacific_ocean/
git clone https://github.com/gaelforget/MITprof
git clone https://github.com/gaelforget/gcmfaces
matlab -nodesktop -nosplash
```

## Extract Profile Locations

Within `Matlab` or `Octave`, proceed as follows:


####1. Set Paths

```
p = genpath('MITprof/'); addpath(p);
p = genpath('gcmfaces/'); addpath(p);
dataset.dirIn='ftp.ifremer.fr/ifremer/argo/geo/pacific_ocean/';
```

####2. List Data Files

```
dataset.fileInList=[];
tmp1=clock;
dataset.YY=[1997:tmp1(1)];

for yy=dataset.YY;
  for mm=1:12;
    tmp1=sprintf('%04d/%02d/',yy,mm);
    tmp2=dir([dataset.dirIn tmp1 '*.nc']);
    if ~isempty(tmp2);
    for ff=1:length(tmp2); tmp2(ff).name=[tmp1 tmp2(ff).name]; end;
      if isempty(dataset.fileInList); dataset.fileInList=tmp2;
      else; dataset.fileInList=[dataset.fileInList;tmp2];
      end;
    end;
  end;
end;
```

####3. Get locations

```
dataset.LONGITUDE=[];
dataset.LATITUDE=[];
dataset.PLATFORM_NUMBER='';
dataset.JULD=[];

for nf=1:length(dataset.fileInList);
  tmp1=profiles_read_argo(dataset,nf,0);
  if tmp1.nprofiles>0;
    dataset.LONGITUDE=[dataset.LONGITUDE;tmp1.argo_data.LONGITUDE'];
    dataset.LATITUDE=[dataset.LATITUDE;tmp1.argo_data.LATITUDE'];
    dataset.PLATFORM_NUMBER=[dataset.PLATFORM_NUMBER;tmp1.argo_data.PLATFORM_NUMBER];
    dataset.JULD=[dataset.JULD;tmp1.argo_data.JULD'];
  end;
end;
```

Note: if using `Octave` you may need to install `nectdf` (e.g., as explained in [this page](https://github.com/Alexander-Barth/octave-netcdf/wiki)).

####5. Visualize Locations

```
datefac=(2050-1950)/(datenum(2050,1,1)-datenum(1950,1,1));
dataset.dateYea=1950+dataset.JULD*datefac;
dataset.dateMin=datestr(datenum(1950,1,1,0,0,0)+min(dataset.JULD));
dataset.dateMax=datestr(datenum(1950,1,1,0,0,0)+max(dataset.JULD));

figure;
subplot(2,1,1); plot(dataset.LONGITUDE,dataset.LATITUDE,'.');
d0=dataset.dateMin(1:11); d1=dataset.dateMax(1:11);
title(['float locations between ' d0 ' and ' d1]);
subplot(2,1,2); hist(dataset.dateYea); title('Profile Dates');
```

###5. Save Locations

```
save('one_dataset.mat', '-struct', 'dataset');
%datasetReloaded=load('dataset_locations.mat');
```

####6. Exit Matlab

```
exit
```


