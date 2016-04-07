#!/bin/bash
#usage: ./dump.sh


###############################################################################################
WORKDIR=$(cd `dirname $0`; pwd)
cd ${WORKDIR}

###############################################################################################
CONF_FILE="${WORKDIR}/etc/config"
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

function load_config() {
  if [ ! -s ${CONF_FILE} ];then
    quit 1 "Can not find config file ${CONF_FILE}, please create it ,then try again"
  fi

  source ${CONF_FILE}

  cat <<EOF
=====================================================================
MGO_HOST          : "${MGO_HOST}"
MGO_PORT          : "${MGO_PORT}"
MGO_BACKUPDIR     : "${MGO_BACKUPDIR}"
MGO_REPLICAONSLAVE: "${MGO_REPLICAONSLAVE}"
MGO_OPLOG         : "${MGO_OPLOG}"
=====================================================================
EOF
}

function check_config() {
  [ "${MGO_HOST}" == "" ] && quit 1 "missing config parameter : ${MGO_HOST}"
  [ "${MGO_PORT}" == "" ] && quit 1 "missing config parameter : ${MGO_PORT}"
  [ "${MGO_BACKUPDIR}" == "" ] && quit 1 "missing config parameter : ${MGO_BACKUPDIR}"
  [ "${MGO_REPLICAONSLAVE}" == "" ] && quit 1 "missing config parameter : ${MGO_REPLICAONSLAVE}"
  [ "${MGO_OPLOG}" == "" ] && quit 1 "missing config parameter : ${MGO_OPLOG}"
  log "check_config" "check config pass:)"
}

function clone_repo(){
  fn_name="clone_repo"
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

function start_backup() {
  fn_name="start_backup"
  echo "${fn_name}"

  log "${fn_name}" "update ${BACKUP_SCRIPT}"

  #mongo parameter
  sed -i "s%^DBHOST=.*%DBHOST=\"${MGO_HOST}\"%g" ${BACKUP_SCRIPT}
  sed -i "s%^PORT=.*%PORT=\"${MGO_PORT}\"%g" ${BACKUP_SCRIPT}
  sed -i "s%^BACKUPDIR=.*%BACKUPDIR=\"${MGO_BACKUPDIR}\"%g" ${BACKUP_SCRIPT}
  sed -i "s%^REPLICAONSLAVE=.*%REPLICAONSLAVE=\"${MGO_REPLICAONSLAVE}\"%g" ${BACKUP_SCRIPT}
  sed -i "s%^OPLOG=.*%OPLOG=\"${MGO_OPLOG}\"%g" ${BACKUP_SCRIPT}

  #avoid mongodump write stderr
  sed -i 's%mongodump --host=.*%& >/dev/null 2>\&1%g' ${BACKUP_SCRIPT}

  #modify exit of script
  sed -i 's%rm -f "$LOGFILE" "$LOGERR".*%[ -f $LOGFILE ] \&\& rm -rf $LOGFILE\n[ -f $LOGERR ] \&\& rm -rf $LOGERR%g' ${BACKUP_SCRIPT}
  sed -i 's%STATUS=1%STATUS=1;exit $STATUS%g' ${BACKUP_SCRIPT}

  log "${fn_name}" "check modify result"
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  cd ${TARGET_DIR} && (git diff | head -n 100) && cd -
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

  log "${fn_name}" "ensure MGO_BACKUPDIR"
  mkdir -p ${MGO_BACKUPDIR}

  log "${fn_name}" "ensure mode of ${BACKUP_SCRIPT}"
  chmod +x ${BACKUP_SCRIPT}

  log "${fn_name}" "ensure mongodump exist"
  which mongodump >/dev/null 2>&1
  quit $? "mongodump not found, please install first"

  log "${fn_name}" "start execute ${BACKUP_SCRIPT}"
  bash ${BACKUP_SCRIPT}
  quit $? "automongobackup failed"
}

###############################################################################################
load_config

check_config

clone_repo

start_backup

echo "Done!"
