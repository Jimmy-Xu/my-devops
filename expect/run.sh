#/bin/bash

###### check config file ######
#check etc/config
if [ ! -s etc/config ];then
  echo "please create a etc/config file first (see etc/config.template)"
  exit 1
fi

#check host_list, one list at least
HOSTLST_CNT=$(ls host | grep -v "template" | wc -l)
if [ ${HOSTLST_CNT} -eq 0 ];then
  echo "please create a host list file in host/ first (see host/example.lst.template)"
  exit 1
fi

#check cmd file, one list at least
CMDFILE_CNT=$(ls cmd | grep -v "template" | wc -l)
if [ ${CMDFILE_CNT} -eq 0 ];then
  echo "please create a cmd file in cmd/ first (see cmd/example.lst.template)"
  exit 1
fi

#################
WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

###### check argument ######
if [ $# -eq 2 ];then
  #check host_list
  HOST_FILE="$1.lst"
  if [ ! -s host/${HOST_FILE} ]; then
    echo "host_list file: host/$HOST_FILE not found or empty!"
    exit 1
  fi
  #check cmd file
  CMD_FILE="$2.exp"
  if [ ! -s cmd/${CMD_FILE} ]; then
    echo "cmd file: cmd/$CMD_FILE not found or empty!"
    exit 1
  fi
else
  # show usage
  echo -e "\nUsage: ./run.sh <host_list> <cmd>"
  #
  echo -e "\nAvailable host_list:\n--------------------------"
  ls host | grep -v "\.template" | awk -F"." '{print $1 }'
  #
  echo -e "\nAvailable cmd:\n--------------------------"
  ls cmd | grep -v "\.template" | awk -F"." '{print $1 }'
  exit 1
fi

###### generate name of logfile ######
TS=$(date +"%y%m%d.%H%M%S")
LOGFILE=${TS}
mkdir -p ${WORKDIR}/log/${LOGFILE}
#re-create symlink "log/latest"
ls log/latest >/dev/null 2>&1
[ $? -eq 0 ] && rm -rf log/latest
cd ${WORKDIR}/log && ln -s ${LOGFILE} latest && cd -



############################
##          main          ##
############################
echo ">save host_list and cmd file"
mkdir -p ${WORKDIR}/log/latest/host ${WORKDIR}/log/latest/cmd
cp host/${HOST_FILE} ${WORKDIR}/log/latest/host
cp cmd/${CMD_FILE} ${WORKDIR}/log/latest/cmd
echo ">start batch execute"
while read HOST_IP
do
{
  #skip comment line and blank line
  echo ${HOST_IP} | grep -E "(^#|^$|^[[:space:]]$)" >/dev/null 2>&1
  [ $? -eq 0 ] && continue
  #process
  CMD="${WORKDIR}/script/executor.sh ${HOST_IP} ${LOGFILE} ${CMD_FILE}"
  echo "${CMD}"
  eval "${CMD}"
}&
done < host/${HOST_FILE}
wait

echo "All Done!"
