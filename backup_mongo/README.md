dump mongodb data automatically
===================================

REF: https://github.com/micahwedemeyer/automongobackup

#quickstart

## create etc/config
```
$ cat etc/config
MGO_HOST="127.0.0.1"
MGO_PORT="27017"
MGO_BACKUPDIR="$(pwd)/data"
MGO_REPLICAONSLAVE="no"
MGO_OPLOG="no"
```

## start backup
```
$ sudo ./util.sh
```

## check result
```
$ tree data
  data
  ├── daily
  │   ├── 2016-04-07_23h52m.Thursday.tgz
  │   └── 2016-04-08_00h23m.Friday.tgz
  ├── latest
  │   └── 2016-04-08_00h23m.Friday.tgz
  ├── monthly
  └── weekly
```
