#!/bin/bash
#usage: ./dump.sh


###############################################################################################
WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

###############################################################################################
SRC_CONF_FILE="${WORKDIR}/etc/automongobackup.template"
TGT_CONF_FILE="/etc/default/automongobackup"
#automongobackup repo config
REPO_NAME="automongobackup"
REPO_URL="https://github.com/micahwedemeyer/automongobackup.git"
BRANCH="35ff02e6f412f9d471cc14148bbb20df5c96f8df"
TARGET_DIR="${WORKDIR}/automongobackup"
BACKUP_SCRIPT="${TARGET_DIR}/src/automongobackup.sh"

###############################################################################################
function quit() {
  EXIT_CODE=$1
  ERR_MSG=$2
  if [ ${EXIT_CODE} -ne 0 ];then
    echo "[ERROR] - ${EXIT_CODE} - ${ERR_MSG}:("
    exit 1
  fi
}

function log(){
  module=$1
  log_msg=$2
  echo "[$(date +'%F %T')] - (${module}) : ${log_msg}"
}

function deploy_config() {
  fn_name="deploy_config"
  echo
  echo "//////////////////////////////${fn_name}//////////////////////////////"
  if [ ! -s ${TGT_CONF_FILE} ];then
    cp ${SRC_CONF_FILE} ${TGT_CONF_FILE}
    log "${fn_name}" "create ${TGT_CONF_FILE} success"
  else
    log "${fn_name}" "${TGT_CONF_FILE} already exist"
  fi

  log "${fn_name}" "show current config"

  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "+                                ${TGT_CONF_FILE}                             +"
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  grep -vE "(^#|^$)" ${TGT_CONF_FILE} | awk -F"=" '{printf "%-18s: %s\n",$1,$2}'
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
}

function clone_repo(){
  fn_name="clone_repo"
  echo
  echo "//////////////////////////////${fn_name}//////////////////////////////"
  cd ${WORKDIR}
  if [ -d ${TARGET_DIR}/.git ];then
    log "${fn_name}" "${TARGET_DIR} found"
    cd ${TARGET_DIR}
    CUR_BRANCH=$(git rev-parse HEAD)
    if [ "${BRANCH}" == "${CUR_BRANCH}" ];then
      log "${fn_name}" "${REPO_NAME} no need update"
    else
      git checkout master -f && git reset --hard HEAD && git pull
      quit $? "${REPO_NAME} need update, but git pull failed"
    fi
  else
    git clone ${REPO_URL} ${TARGET_DIR}
    quit $? "${REPO_NAME} not exist, and git clone failed"
  fi
  cd ${WORKDIR}/${REPO_NAME} && git checkout ${BRANCH} -f >/dev/null 2>&1
  quit $? "check out to specified commit '${BRANCH}'"

  log "${fn_name}" "${REPO_NAME} repo is ready:)"
}

function send_email() {
  echo "TODO"
}

function start_backup() {
  fn_name="start_backup"
  echo
  echo "//////////////////////////////${fn_name}//////////////////////////////"
  log "${fn_name}" "update ${BACKUP_SCRIPT}"

  #avoid mongodump write stderr
  sed -i 's%mongodump --host=.*%& >/dev/null 2>\&1%g' ${BACKUP_SCRIPT}

  #modify exit of script
  sed -i 's%rm -f "$LOGFILE" "$LOGERR".*%[ -f $LOGFILE ] \&\& rm -rf $LOGFILE\n[ -f $LOGERR ] \&\& rm -rf $LOGERR%g' ${BACKUP_SCRIPT}
  sed -i 's%STATUS=1%STATUS=1;exit $STATUS%g' ${BACKUP_SCRIPT}

  # log "${fn_name}" "check modify result"
  # echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  # cd ${TARGET_DIR} && (git diff | head -n 100) && cd -
  # echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

  log "${fn_name}" "ensure mode of ${BACKUP_SCRIPT}"
  chmod +x ${BACKUP_SCRIPT}

  log "${fn_name}" "ensure mongodump exist"
  which mongodump >/dev/null 2>&1
  quit $? "mongodump not found, please install first"

  log "${fn_name}" "start execute ${BACKUP_SCRIPT}"
  ${BACKUP_SCRIPT}

  send_email "$?"
}

###############################################################################################
deploy_config

clone_repo

start_backup

echo "Done!"
