#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
BASE_DIR=$(dirname $0)
CONF_DIR=${BASE_DIR}/../conf
BRANCH_LIST=( `grep -v '^#' ${CONF_DIR}/repo.list` )
WWW_REPORTS=/var/www/html/reports

# loop for looping over the different release branch
# --------------------------------------------------
for branch in ${BRANCH_LIST[*]}
do
  bash ${BASE_DIR}/run_branch ${branch}
done # for all branchs
#exit 1


