#!/bin/bash

WORKDIR=$(cd `dirname $0`; cd ..; pwd)
cd ${WORKDIR}

#get UESRNAME and PASSWORD
source etc/config

IP=$1
LOG_DIR=${WORKDIR}/log/$2/
CMD_FILE=$3
LOG_FILE=${LOG_DIR}/${IP}.log
mkdir -p ${LOG_DIR}

exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

# check and read cmd/${CMD_FILE}, ignore invalid line
[ -s cmd/${CMD_FILE} ] && TASK_LIST=$(cat cmd/${CMD_FILE} | grep -vE "(^#|^$|^[[:space:]]$)")

############ main ############
echo -e "\n================================================="
echo "gather server info: $IP"
echo "================================================="
expect -c "
    set timeout 10
    spawn ssh -o \"StrictHostKeyChecking no\" ${USERNAME}@${IP}
    expect {
    	\"password:\" {send \"${PASSWORD}\n\";}
    	}
    send_user \"\nEnter server ${IP}\n\"
    ${TASK_LIST}
    expect \"*\]#\"
    send_user \"\nLeaver server ${IP}\n\"
    send \"exit\n\"
    expect eof
"
echo "Done!"
