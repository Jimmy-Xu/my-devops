export collections and upload to s3
===================================

# quickstart

## config s3
```
$ aws --profile live configure
```

## backup manually
```
$ ./export.sh
```

## backup by crontab
```
$ crontab -l
#backup mongo to s3 everyday
0 16 */1 * * /opt/mongo_bak/backup.sh
```

## check result
```
$ ls db_bak
```
