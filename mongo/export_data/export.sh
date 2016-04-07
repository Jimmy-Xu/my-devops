#!/bin/bash
#usage: ./export.sh

##################################################################################
MGO_HOST="10.1.1.6" #select slave mongodb server
MGO_PORT="27017"
AWS_PROFILE="live"
S3_BUCKET="hyper-db-bak"

DB_NAME="hypernetes"
PREFIX="hyper"
PRODUCT="hypernetes"
COLL_LIST=(betausers cell charging container credentials exec network referrals resource_price resource_quota sessions tenant users volume)

##################################################################################
BASE_DIR=$(cd "$(dirname "$0")"; pwd)
cd ${BASE_DIR}

####################################################################################################################
echo "Stats collections..."
rm -rf /tmp/${DB_NAME}.stat >/dev/null 2>&1
echo "collection           primary    count   size(MB)  avgObjSize(KB) storageSize(MB)"
echo "--------------------------------------------------------------------------------"
for coll in ${COLL_LIST[@]}
do
	mongo ${MGO_HOST}:${MGO_PORT}/${DB_NAME} --eval "printjson(db."${coll}".stats())" | awk -v COL=${coll} '/primary/{RLT=$3}/count|size|storageSize/{RLT=RLT""$3}/avgObjSize/{RLT=sprintf("%s%d,",RLT,$3)}END{printf "%s,%s\n",COL,RLT}' >> /tmp/${DB_NAME}.stat
done
sort -n -t, -k 3 /tmp/${DB_NAME}.stat | awk -F"," '{printf "%-20s %5s %10d %10.1f %15.1f %15.1f\n", $1, $2, $3, $4/1024/1024, $5/1024, $6/1024/1024 }'


####################################################################################################################
TS=$(date +%F_%H-%M)
mkdir -p ${BASE_DIR}/db_bak/exported
echo "Export collections...(from small to large)"
for coll in $( sort -n -t, -k 3 /tmp/${DB_NAME}.stat | awk -F"," '{print $1}' )
do
	echo -e "\n > Start export ${coll} ..."
	time mongoexport -h ${MGO_HOST} --port ${MGO_PORT} --db ${DB_NAME} --collection ${coll} --out ${BASE_DIR}/db_bak/exported/${coll}.json
done
echo
echo "Exported dir: ${BASE_DIR}/db_bak/exported"

####################################################################################################################
echo "create tgz : ${BASE_DIR}/db_bak/${PREFIX}-${DB_NAME}-${TS}.tgz"
cd ${BASE_DIR}/db_bak
time tar czvf ${PREFIX}-${DB_NAME}-${TS}.tgz exported

####################################################################################################################
echo "upload to s3 db_bak/${PRODUCT}/exported/"
time aws --profile ${AWS_PROFILE} s3 cp ${PREFIX}-${DB_NAME}-${TS}.tgz s3://${S3_BUCKET}/${PRODUCT}/exported/

echo "Done"
