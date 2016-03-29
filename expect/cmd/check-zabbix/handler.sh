#!/bin/bash
# this script is used for process result(process.sh will invoke this file)

LOG_FILE="$1"

HOST_IP=$(cat ${LOG_FILE} | grep '^Enter server' | awk '{printf $3}')
ZABBIX_AGENT_ACTIVE=$(cat ${LOG_FILE} | grep 'active (running)' | wc -l)
ZABBIX_SERVER=$(cat ${LOG_FILE} | grep -E "^Server=" | awk -F"=" '{print $2}' |  tr -d '\n' | tr -d '\r' )
ZABBIX_SERVER_ACTIVE=$(cat ${LOG_FILE} | grep -E "^ServerActive=" | awk -F"=" '{print $2}'  |  tr -d '\n' | tr -d '\r'  )
ZABBIX_HOSTNAME=$(cat ${LOG_FILE} | grep -E "^Hostname=" | awk -F"=" '{print $2}'  |  tr -d '\n' | tr -d '\r'  )
printf "%-15s | %2s | %15s | %15s | %s\n" ${HOST_IP} ${ZABBIX_AGENT_ACTIVE} ${ZABBIX_SERVER} ${ZABBIX_SERVER_ACTIVE} ${ZABBIX_HOSTNAME}
