#/bin/bash

#################
WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

CMD_FILE=$(ls ${WORKDIR}/log/latest/cmd/*.exp)
CMD_NAME=$(echo $CMD_FILE | awk -F"/" '{print $NF}')
CMD=${CMD_NAME/.exp/}

CMD_HANDLER=cmd/${CMD}.handler
if [ "${CMD_HANDLER}" == "" ];then
  echo "There is no handler for ${CMD_FILE}"
  exit 1
fi

############################
##          main          ##
############################
#start batch process
for f in $(ls ${WORKDIR}/log/latest/*.log)
do
  ${CMD_HANDLER} $f
done
