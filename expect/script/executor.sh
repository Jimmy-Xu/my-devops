#!/bin/bash

WORKDIR=$(cd `dirname $0`; cd ..; pwd)
cd ${WORKDIR}

#get UESRNAME and REMOTE_PASSWORD
source etc/config


HOST_FILE=$1
CMD_DIR=$2
IP=$3
TS=$4

LOG_DIR=${WORKDIR}/log/${HOST_FILE}@${CMD_DIR}/${TS}
mkdir -p ${LOG_DIR}
LOG_FILE=${LOG_DIR}/${IP}.log

exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# check and read cmd/${CMD_DIR}, ignore invalid line
[ -s cmd/${CMD_DIR}/cmd.exp ] && TASK_LIST=$(cat cmd/${CMD_DIR}/cmd.exp | grep -vE "(^#|^$|^[[:space:]]$)")

############ main ############
echo -e "\n================================================="
echo "gather server info: $IP"
echo "================================================="
expect -c "
    set timeout 10
    spawn ssh -o \"StrictHostKeyChecking no\" ${REMOTE_USERNAME}@${IP}
    expect {
    	\"password:\" {send \"${REMOTE_PASSWORD}\n\";}
    	}
    send_user \"\nEnter server ${IP}\n\"
    ${TASK_LIST}
    expect \"${REMOTE_PROMPT}\"
    send_user \"\nLeaver server ${IP}\n\"
    send \"exit\n\"
    expect eof
"
echo "Done!"
