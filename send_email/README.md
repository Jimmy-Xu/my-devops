Send email with AWS SES
========================

#quickstart

## modify settings.py
```
//setting the following parameter
SENDER_NAME
SENDER_EMAIL
SMTP_USERNAME
SMTP_PASSWORD
SMTP_SERVER
```

## usage

### send mail without attachments
```
$ python ./zabbix-alert-smtp.py jimmy@xxxxx.sh "title" "content"
```

### send mail with attachments
```
$ python ./zabbix-alert-smtp.py jimmy@xxxxx.sh "title" "body" "file1,file2"
```
