download software, grid, and climatologies

```
git clome https://github.com/gaelforget/gcmfaces
git clone https://github.com/gaelforget/MITprof

setenv FTPv4r2 'ftp://mit.ecco-group.org/\
				ecco_for_las/version_4/release2/'
wget --recursive {$FTPv4r2}/nctiles_grid
mv mit.ecco-group.org/ecco_for_las/version_4/\
				release2/nctiles_grid/ .

setenv FTPclim 'ftp://mit.ecco-group.org/gforget/'
wget --recursive {$FTPclim}/OCCAetcONv4GRID
mv mit.ecco-group.org/gforget/OCCAetcONv4GRID \
				gcmfaces_climatologies
```

download argo data

```
setenv FTPargo 'ftp://ftp.ifremer.fr/ifremer/argo/geo/'
wget $FTPargo/ar_greylist.txt
wget -r $FTPargo/atlantic_ocean/2016 &
wget -r $FTPargo/atlantic_ocean/2017 &
wget -r $FTPargo/pacific_ocean/2016 &
wget -r $FTPargo/pacific_ocean/2017 &
wget -r $FTPargo/indian_ocean/2016 &
wget -r $FTPargo/indian_ocean/2017 &

```

start matlab and process data

```
matlab -nodesktop -nodisplay
>> p = genpath('gcmfaces/'); addpath(p);
>> p = genpath('MITprof/'); addpath(p);
>> argo_process_loop;
>> argo_split_by_years;
```
