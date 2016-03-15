#!/bin/bash

WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

#get UESRNAME and PASSWORD
source etc/config

IP=$1
LOG_DIR=${WORKDIR}/log/$2/
LOG_FILE=${LOG_DIR}/${IP}.log
mkdir -p ${LOG_DIR}

exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)

############ main ############
echo -e "\n================================================="
echo "gather server info: $IP"
echo "================================================="
expect -c "
    set timeout 10
    spawn ssh -o \"StrictHostKeyChecking no\" ${USERNAME}@${IP}
    expect {
    	\"password:\" {send \"${PASSWORD}\r\";}
    	}
    send_user \"\rEnter server ${IP}\r\"
    expect \"*#\"
    send \"which hwinfo && echo 'hwinfo has already installed' || yum install -y http://li.nux.ro/download/nux/dextop/el7/x86_64/hwinfo-20.2-5.3.x86_64.rpm  http://li.nux.ro/download/nux/dextop/el7/x86_64/libx86emu-1.1-2.1.x86_64.rpm\r\"
    expect \"*#\"
    send \"curl -s https://raw.githubusercontent.com/Jimmy-Xu/my-devops/master/gather_server_info/server_info.sh | bash\r\"
    expect \"*#\"
    send_user \"\rLeaver server ${IP}\r\"
    send \"exit\r\"
    expect eof
"
echo "Done!"
