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
```
//result
$ ls log/latest/*.log

//host_list backup
$ ls log/host

//cmd file backup
$ ls log/cmd
```
