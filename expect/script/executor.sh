#!/bin/bash

WORKDIR=$(cd `dirname $0`; cd ..; pwd)
cd ${WORKDIR}

#get UESRNAME and REMOTE_PASSWORD
source etc/config


HOST_FILE=$1
CMD_DIR=$2
IP=$3
TS=$4

#LOG_DIR=${WORKDIR}/log/${HOST_FILE}@${CMD_DIR}/${TS}
LOG_DIR=${WORKDIR}/log/${HOST_FILE}@${CMD_DIR}  ## change log_dir level

mkdir -p ${LOG_DIR}
[ -f ${LOG_DIR}/${IP}.log ] && rm -rf ${LOG_DIR}/${IP}.log
LOG_FILE=${LOG_DIR}/${IP}.log

exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# check and read cmd/${CMD_DIR}, ignore invalid line
[ -s cmd/${CMD_DIR}/cmd.exp ] && TASK_LIST=$(cat cmd/${CMD_DIR}/cmd.exp | grep -vE "(^#|^$|^[[:space:]]$)")

############ main ############
if [ "${JUMPER_ENABLED}" != "true" ];then

  echo -e "\n================================================="
  echo "gather server info(without jumper): $IP"
  echo "================================================="
  expect -c "
set timeout ${EXPECT_TIMEOUT}
spawn ssh -o \"StrictHostKeyChecking no\" ${REMOTE_USERNAME}@${IP}
expect {
	\"password:\" {send \"${REMOTE_PASSWORD}\n\";}
}
send_user \"\nEnter server ${IP}\n\"
set timeout 10
${TASK_LIST}
expect \"${REMOTE_PROMPT}\"
send_user \"\nLeaver server ${IP}\n\"
send \"exit\n\"
expect eof
"
else
  echo -e "\n================================================="
  echo "gather server info(from jumper:${JUMPER_IP}): $IP"
  echo "================================================="
  expect -c "
set timeout ${EXPECT_TIMEOUT}
send_user \"\nEnter jumper ${JUMPER_IP}\n\"
spawn ssh -i ${JUMPER_KEY} -o \"StrictHostKeyChecking no\" ${JUMPER_USERNAME}@${JUMPER_IP}
expect \"${JUMPER_PROMPT}\"
send \"ssh ${REMOTE_USERNAME}@${IP}\n\"
expect {
	\"password:\" {send \"${REMOTE_PASSWORD}\n\";}
}
send_user \"\nEnter server ${IP}\n\"
set timeout 10
${TASK_LIST}
expect \"${REMOTE_PROMPT}\"
send_user \"\nLeaver server ${IP}\n\"
send \"exit\n\"
expect \"${JUMPER_PROMPT}\"
send_user \"\nLeaver jumper ${JUMPER_IP}\n\"
send \"exit\n\"
expect eof
"
fi
