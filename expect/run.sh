#/bin/bash

#check hosts file
if [ ! -s etc/hosts ];then
  echo "please create a hosts file first (see etc/hosts.template)"
  exit 1
fi

if [ ! -s etc/config ];then
  echo "please create a hosts file first (see etc/hosts.template)"
  exit 1
fi


WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

#generate name of logfile
TS=$(date +"%y%m%d.%H%M%S")
LOGFILE=${TS}

#ensure log dir
mkdir -p ${WORKDIR}/log/${LOGFILE}

#delete symlink "log/latest"
ls log/latest >/dev/null 2>&1
[ $? -eq 0 ] && rm -rf log/latest

#create symlink log/latest
cd ${WORKDIR}/log && ln -s ${LOGFILE} latest && cd -

########### main ###########
while read LINE
do
{
  echo "${WORKDIR}/get_server_info.sh ${LINE} ${LOGFILE}"
  ${WORKDIR}/get_server_info.sh ${LINE} ${LOGFILE}
}&
done < etc/hosts
wait

echo "All Done!"
