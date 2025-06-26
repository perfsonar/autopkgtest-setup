#!/usr/bin/bash
# This scrip only function is to spawn a detched screen session for each branch  

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
BASE_DIR=$(dirname $0)
CONF_DIR=${BASE_DIR}/../conf
BRANCH_LIST=( `grep -v '^#' ${CONF_DIR}/repo.list` )
WWW_REPORTS=/var/www/html/reports

# loop for looping over the different release branch
# --------------------------------------------------
for branch in ${BRANCH_LIST[*]}
do
  # spawn screen detached session for current branch of loop 
  echo starting ${branch} screen session ...
  screen -t ${branch} -L -Logfile /var/www/html/reports/screen_output_${branch}_$(date +'%Y-%m-%d').log -d -m bash ${BASE_DIR}/run_branch.sh ${branch}
done # for all branchs
#exit 1


