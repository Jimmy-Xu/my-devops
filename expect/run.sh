#/bin/bash

WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

HOST_FILE=""
CMD_DIR=""
TMP_DIR="/tmp/expect"
mkdir -p ${TMP_DIR}
FILE_SUCCESS="${TMP_DIR}/counter.success"
FILE_FAIL="${TMP_DIR}/counter.fail"

#load MAX_NPROC and DELAY_SEC(# limit number of concurrent tasks
source etc/config

#############################################################
#                       function                            #
#############################################################
function check_config() {
  #check etc/config
  if [ ! -s etc/config ];then
    echo "please create a etc/config file first (see etc/config.template)"
    exit 1
  fi

  #check host_list, one list at least
  HOSTLST_CNT=$(ls host/*.lst | wc -l)
  if [ ${HOSTLST_CNT} -eq 0 ];then
    echo "please create a host list file in host/ first (see host/example.lst.template)"
    exit 1
  fi

  #check cmd file, one list at least
  CMDFILE_CNT=$(ls -d cmd/*/ | wc -l)
  if [ ${CMDFILE_CNT} -eq 0 ];then
    echo "please create a cmd directory in cmd/ first"
    exit 1
  fi
}

function check_jumper(){
  if [ "${JUMPER_ENABLED}" == "true" ];then
    if [ ! -s ${JUMPER_KEY} ];then
      echo "jumper is enabled, but '${JUMPER_KEY}' doesn't exist"
      exit 1
    fi
  fi
}

function check_argument() {
    case $# in
      1)
        show_usage $1 "ERROR: missing <host_list>"
        ;;
      2)
        show_usage $1 "ERROR: missing <cmd_dir>"
        ;;
      3)
        #check host_list
        HOST_FILE="$2"
        if [ ! -s host/${HOST_FILE}.lst ]; then
          echo "ERROR: host/${HOST_FILE}.lst not found or empty!"
          exit 1
        fi
        #check cmd file
        CMD_DIR="$3"
        if [ ! -s cmd/${CMD_DIR}/cmd.exp ]; then
          echo "ERROR: cmd/${CMD_DIR}/cmd.exp not found or empty!"
          exit 1
        fi
        ;;
    esac
}

function check_log(){
  if [[ $# -eq 3 ]] && [[ -d ${WORKDIR}/log/$2@$3 ]] ;then
    echo -e "\n>${WORKDIR}/log/$2@$3 is valid\n"
  else
    cat <<EOF

>ERROR: ${WORKDIR}/log/$2@$3 is invalid
------------------------------------------------------------------------------------
Please run the following command first:
  ./run.sh exec $2 $3

EOF
    show_available $@
  fi
}

function show_available(){
  case $1 in
    process|web)
      echo -e "\nAvailable <log_dir> in log/:"
      echo "------------------------------------------------------------------------------------"
      cd ${WORKDIR}/log/ && ls -d */ | grep -v latest | tr -d "/"
      ;;
    *)
      echo -e "\nAvailable <host_list>:"
      echo "------------------------------------------------------------------------------------"
      cd ${WORKDIR}/host && grep -vE "(^#|^$|^[[:space:]]$)" *.lst | awk -F"[.:]" '{S[$1]=S[$1]+1}END{for(i in S){printf "%s\t(%4d hosts )\n", i, S[i]}}'
      echo -e "\nAvailable <cmd_dir>:"
      echo "------------------------------------------------------------------------------------"
      cd ${WORKDIR}/cmd && ls -d */
      echo
      ;;
  esac
  exit 1
}

function show_usage(){
  [ $# -ne 0 ] && echo -e "\n$@"
  cat <<EOF

====================================================================================
usage: ./run.sh <action> [option]
------------------------------------------------------------------------------------
<action>:
  exec    <host_list> <cmd_dir>       # batch execute command
  process <host_list> <cmd_dir>       # process result
  web     <host_list> <cmd_dir>       # start a web server to view raw result
====================================================================================
EOF
  show_available
  exit 1
}

function inc_job_result(){
  case $1 in
    success)
      read -u7
      CNT_SUCESS=$(cat ${FILE_SUCCESS})
      CNT_SUCESS=$((CNT_SUCESS+1))
      echo ${CNT_SUCESS} > ${FILE_SUCCESS}
      echo "[ inc_job_result : success ] [$2] ${CNT_SUCESS}/${TOTAL}"
      echo >&7
      ;;
    fail)
      read -u8
      CNT_FAIL=$(cat ${FILE_FAIL})
      CNT_FAIL=$((CNT_FAIL+1))
      echo ${CNT_FAIL} > ${FILE_FAIL}
      echo "[ inc_job_result : fail ] [$2] ${CNT_FAIL}/${TOTAL}"
      echo >&8
      ;;
    *)
      echo "unknow job result"
      exit 1
  esac
}

function do_exec() {
  START_TS=$(date +"%s")
  START_TIME=$(date +"%F %T")

  # generate timestamp of log
  TS=$(date +"%Y%m%dT%H%M%S")

  #LOG_FULLPATH=${WORKDIR}/log/${HOST_FILE}@${CMD_DIR}/${TS}
  LOG_FULLPATH=${WORKDIR}/log/${HOST_FILE}@${CMD_DIR}   ## change log_dir level

  #print var
  cat <<EOF
==============================================================================
HOST_FILE    : ${HOST_FILE}
CMD_DIR      : ${CMD_DIR}
LOG_FULLPATH : ${LOG_FULLPATH}
==============================================================================
EOF

  # ensure output  dir
  mkdir -p ${LOG_FULLPATH}

  # save current host_list and cmd file
  echo ">save host_list and cmd file"
  mkdir -p ${LOG_FULLPATH}/snap
  cp cmd/${CMD_DIR}/* ${LOG_FULLPATH}/snap

  # create log/latest
  echo ">create symlink 'log/latest'"
  ls log/latest >/dev/null 2>&1
  [ $? -eq 0 ] && rm -rf log/latest

  ##cd ${WORKDIR}/log && ln -s ${HOST_FILE}@${CMD_DIR}/${TS} latest && cd -
  cd ${WORKDIR}/log && ln -s ${HOST_FILE}@${CMD_DIR} latest && cd -  ## change log_dir level

  # prepare pipe(for control concurrent tasks)
  Pfifo="${TMP_DIR}/$$.fifo"
  mkfifo $Pfifo $Pfifo.success $Pfifo.fail

  # fd6: limit concurrent
  exec 6<>$Pfifo #file descriptor(fd could be 0-9, except 0,1,2,5)

  # fd7: locker to write ${FILE_SUCCESS}
  exec 7<>$Pfifo.success

  # fd8: locker to write ${FILE_FAIL}
  exec 8<>$Pfifo.fail

  rm -f $Pfifo $Pfifo.success $Pfifo.fail

  #init fd6, fd7, fd8
  echo >&7
  echo >&8
  for((i=1; i<=$MAX_NPROC; i++));
  do #write blank line as token
    echo
  done >&6 #fd6

  #init sucess/fail counter
  echo -n 0 > ${FILE_SUCCESS}
  echo -n 0 > ${FILE_FAIL}
  TOTAL=$(grep -vE "(^#|^$|^[[:space:]]$)" host/${HOST_FILE}.lst 2>/dev/null | wc -l)
  # start exec task
  echo ">start batch fetch"
  JOB_TOTAL=0
  while read CURRENT_IP
  do
    #skip comment line and blank line
    echo ${CURRENT_IP} | grep -E "(^#|^$|^[[:space:]]$)" >/dev/null 2>&1
    [ $? -eq 0 ] && continue

    JOB_TOTAL=$((JOB_TOTAL+1))
    #fetch token from pipe(block here if there is no token in pipe)
    read -u6 #fd6
    {
      #exec job
      EXEC_CMD="${WORKDIR}/script/executor.sh ${HOST_FILE} ${CMD_DIR} ${CURRENT_IP} ${TS} "
      #echo "${EXEC_CMD}"
      echo "start execute job: [ ${HOST_FILE} ${CMD_DIR} ${CURRENT_IP} ]"
      eval "${EXEC_CMD}" && {
        #echo "Job finished: [${EXEC_CMD}]"
        inc_job_result "success" "${HOST_FILE} ${CMD_DIR} ${CURRENT_IP}"
      } || {
        #echo "Job failed: [${EXEC_CMD}]"
        inc_job_result "fail" "${HOST_FILE} ${CMD_DIR} ${CURRENT_IP}"
      }
      #delay
      #echo "delay '${DELAY_SEC}' seconds"
      sleep ${DELAY_SEC}
      #give back token to pipe
      echo >&6 #fd6
    }&
  done < host/${HOST_FILE}.lst
  #wait for all task finish
  wait

  #read counter
  JOB_SUCCESS=$(cat ${FILE_SUCCESS})
  JOB_FAIL=$(cat ${FILE_FAIL})

  #delete file descriptor
  exec 6>&- #fd6
  exec 7>&-
  exec 8>&-

  rm -f ${FILE_SUCCESS}
  rm -f ${FILE_FAIL}

  cat <<EOF

================================================================================
To process result, please run:
  ./run.sh process                                 # always process 'log/latest'
  or
  ./run.sh process ${HOST_FILE} ${CMD_DIR}

To view raw result in web browser, please run:
  ./run.sh web
  or
  ./run.sh web ${HOST_FILE} ${CMD_DIR}
================================================================================

EOF

END_TS=$(date +"%s")
END_TIME=$(date +"%F %T")
cat <<EOF
############### Summary ###############
HOST LIST : host/${HOST_FILE}.lst
CMD FILE  : cmd/${CMD_DIR}/cmd.exp
---------------------------------------
MAX_NPROC : ${MAX_NPROC}
DELAY_SEC : ${DELAY_SEC}
---------------------------------------
START_TIME: ${START_TIME}
END_TIME  : ${END_TIME}
DURATION  : $((END_TS - START_TS)) (seconds)
---------------------------------------
JOB_TOTAL(HOSTS) : ${JOB_TOTAL}
  SUCCESS : ${JOB_SUCCESS}
  FAIL    : ${JOB_FAIL}
#######################################
EOF
}

function do_handle_result() {
  if [ $# -eq 1 ];then
    LOG_DIR=$(ls -l log | grep latest | awk '{print $NF}')
    echo -e "\nprocess log/latest -> ${LOG_DIR}"
    HOST_FILE=$( echo ${LOG_DIR} | awk -F"[@/]" '{print $1}')
    CMD_DIR=$( echo ${LOG_DIR} | awk -F"[@/]" '{print $2}')
    LOG_DIR=$( echo ${LOG_DIR} | awk -F"[@/]" '{print $3}')
  else
    HOST_FILE=$2
    CMD_DIR=$3
    LOG_DIR=$4
  fi
  LOG_FULLPATH=${WORKDIR}/log/${HOST_FILE}@${CMD_DIR}/${LOG_DIR}
  CMD_HANDLER=${WORKDIR}/cmd/${CMD_DIR}/handler.sh

  #print var
  cat <<EOF
==============================================================================
LOG_FULLPATH : ${LOG_FULLPATH}
CMD_HANDLER  : ${CMD_HANDLER}
LOG_FILES_CNT: $(ls ${LOG_FULLPATH}/*.log | wc -l)
==============================================================================

EOF

  case $1 in
    process)
      echo "------------------------------------ result ----------------------------------"
      for f in $(ls ${LOG_FULLPATH}/*.log)
      do
        ${CMD_HANDLER} $f
      done
      echo "------------------------------------------------------------------------------"
      ;;
    web)
      ${WORKDIR}/script/start_webui.sh ${LOG_FULLPATH}
      ;;
  esac
}

#############################################################
#                        main                               #
#############################################################
###### check config file ######
check_config
check_jumper

case "$1" in
  exec)
    check_argument $@
    do_exec $@
    ;;
  process|web)
    if [ $# -ne 1 ];then
      check_argument $@
      check_log $@
    fi
    do_handle_result $@
    ;;
  *)
    [ $# -ge 1 ] && MSG="'$1' is a unknown action, action must be 'exec', 'process' or 'web'"
    show_usage ${MSG}
esac

echo -e "\nAll Done!\n"


# TOTO
#get all netcard and ip
