# prepare

### create config

> create etc/config, set ssh account in it

### create host_list file

> create a host_list in host/, see host/example.lst.template

### create cmd file

> create a cmd file in cmd/, see cmd/example.exp.template

# batch run cmd
```
//show usage
$ ./run.sh
  Usage: ./run.sh <host_list> <cmd>

  Available host_list:
  --------------------------
  all
  test

  Available cmd:
  --------------------------
  gather_info

//run
$ ./run.sh all gather_info
```

# view result

> 1)view raw result data in `log/latest` dir
> 2)run web server view html result
```
//start simple web server
$ ./startsrv.sh
  /home/xjimmy/my-devops/expect/log/latest
  serving at port 8888

//open http://x.x.x.x:8888 to view result
```
