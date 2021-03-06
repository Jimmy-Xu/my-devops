#!/bin/bash
# this script is used for process result(process.sh will invoke this file)

LOG_FILE="$1"
LOG_NAME=$(echo $LOG_FILE | awk -F"/" '{print $NF}')
HOST_IP=${LOG_NAME/.log/}
HOSTNAME=$(cat ${LOG_FILE} | grep '^HOSTNAME:' | tr -d "\r" | awk '{print $2}')
echo
cat ${LOG_FILE} | grep -E "(^found imaged)"| tr -d "\r" | awk -v HOSTNAME=${HOSTNAME} -v HOST_IP=${HOST_IP} '{printf "%s %s %s\n", HOSTNAME,HOST_IP,$2}'
