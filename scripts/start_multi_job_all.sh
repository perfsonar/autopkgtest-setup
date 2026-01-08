#!/usr/bin/bash
# This scrip only function is to spawn a detched screen session for each branch  
# it now limit the number of concurrent jobs
# you can see the progress with:
#   ps -u $USER 

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
BASE_DIR=$(dirname $0)
CONF_DIR=${BASE_DIR}/../conf
BRANCH_LIST=( `grep -v '^#' ${CONF_DIR}/repo.list` )
WWW_REPORTS=/var/www/html/reports
MAX_JOBS=3
WAIT_SLEEP=60
JOB_TOTAL=${#BRANCH_LIST[*]}
JOB_COUNT=0
MYNAME=`cat /proc/$$/comm`
LOG_KEEP=60
WWW_REPORTS=/var/www/html/reports

# this function will count the number of screen session 
# and will wait for the count to be bellow ${MAX_JOB}
# before returning
function wait_for_job(){
    # get scree session cound
    SCREEN_COUNT=`screen -list |awk -v 'c=0'  '{if($2 ~ /Socket/){if($1 == "No"){c=0}else{c=$1}}};END{print c}'`
    while [ ${SCREEN_COUNT} -ge ${MAX_JOBS} ]
    do
        sleep ${WAIT_SLEEP}
        SCREEN_COUNT=`screen -list |awk -v 'c=0'  '{if($2 ~ /Socket/){if($1 == "No"){c=0}else{c=$1}}};END{print c}'`
    done
}

# loop for looping over the different release branch
# --------------------------------------------------
for branch in ${BRANCH_LIST[*]}
do
  wait_for_job
  # spawn screen detached session for current branch of loop 
  echo starting ${branch} screen session ...
  screen -t ${branch} -L -Logfile /var/www/html/reports/screen_output_${branch}_$(date +'%Y-%m-%d').log -d -m bash ${BASE_DIR}/run_branch.sh ${branch}
  echo "${MYNAME} progress: $JOB_COUNT/${JOB_TOTAL}" > /proc/$$/comm
done # for all branchs
#exit 1

# clean-up old directories and file 
# ----------------------------------

OLD_LIST=( $(ls -d ${WWW_REPORTS}/20*|sed -e 's:.*/::' | sort -rh | tail -n +${LOG_KEEP}  | sort -h ) )

for l in ${OLD_LIST[*]}
do
  echo "Removing $l"
  rm -r ${WWW_REPORTS}/${l} ${WWW_REPORTS}/screen*${l}.{log,html}
done
