dump mongodb data automatically
===================================

REF: https://github.com/micahwedemeyer/automongobackup

#quickstart

## config for automongobackup.sh

### deploy config file
```
$ sudo cp etc/automongobackup.template /etc/default/automongobackup
```

### for single node mongo
```
DBHOST            : "127.0.0.1"
DBPORT            : "27017"
BACKUPDIR         : "/home/xjimmy/my-devops/mongo/dump_data/data"
OPLOG             : "no"
REPLICAONSLAVE    : "no"
```

### for mongo cluster
```
DBHOST            : "10.1.1.4"
DBPORT            : "27017"
BACKUPDIR         : "/opt/mongo_bak/dump_data"
OPLOG             : "yes"
REPLICAONSLAVE    : "yes"
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
