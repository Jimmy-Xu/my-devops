#!/bin/bash
# this script is used for process result(process.sh will invoke this file)

LOG_FILE="$1"
cat ${LOG_FILE} | grep -E "(Enter|nameserver)" |  tr '\n' '|' | sed -e 's/|$/\n/'
