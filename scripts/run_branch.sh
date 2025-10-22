#!/bin/bash
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
TODAY=$(date +"%Y-%m-%d")
#AUTOPKGTEST_DIR="/root/perfsonar-autopkgtest"
#AUTOPKGTEST_DIR="/home/ppedersen/git/perfsonar-autopkgtest"
OS_LIST=( debian-{11,12} ubuntu-{22,24} )
BASE_DIR=$(dirname $0)
CONF_DIR=${BASE_DIR}/../conf
BRANCH_LIST=( `grep -v '^#' ${CONF_DIR}/repo.list` )
WWW_REPORTS=/var/www/html/reports

branch=$1
check="\<${branch}\>"
if [[ ${BRANCH_LIST[@]} =~ ${check} ]]
then
  echo -e "##starting branch : ${branch}\n"
  PACKAGE_LIST=( `cat ${CONF_DIR}/${branch}.list` )
  echo -e "* list of distributions: ${OS_LIST[*]}\n"
  # loop to do the processing of all the containers
  # ------------------------------------------------
  for OS in ${OS_LIST[*]}
  do
    echo -e "### ${OS}\n"
    LOG_DIR="${WWW_REPORTS}/$TODAY/${branch}/${OS}"
    mkdir -p ${LOG_DIR}
    os_version=${OS/*-/}
    if [ "${OS/-*/}" == "ubuntu" ] 
     then
         os_version="${os_version}.04"
    fi
    IMAGE_ALIAS="${branch}-autopkgtest-${OS//\.*}"
    #echo -ne "    $(date -u '+%Y/%m/%d %H:%M') creating base image ${IMAGE_ALIAS}"
    echo -ne "* Creating base image ${IMAGE_ALIAS}"
    bash ${BASE_DIR}/create_template.sh ${OS/-*/} ${os_version} ${branch} &>> /dev/null
    if [ $? -ne 0 ]; then
      echo -e "\t\tFAILED more info in /tmp/create_template.sh.out\n"
       #exit 10
       continue # skip this one do next OS
    else
      echo -e "\t\tDONE\n"
    fi
    package_loop_start="`date -u '+%Y/%m/%d %H:%M'`"
    #echo "    starting ${OS}"
    # loop to do each package from list
    # ---------------------------------
    PCOUNT=${#PACKAGE_LIST[*]}
    PROGRESS_COUNT=0
    for PACKAGE in ${PACKAGE_LIST[*]}
    do
      #echo -e "\t`date -u '+%Y/%m/%d %H:%M'` autopkgtest ${PACKAGE} using image ${IMAGE_ALIAS}"
      ((PROGRESS_COUNT=$PROGRESS_COUNT+1))
      echo -en "#### ${PROGRESS_COUNT}/${PCOUNT} ${PACKAGE} using image ${IMAGE_ALIAS}"
      autopkgtest -d -U --summary-file=${LOG_DIR}/autopkgtest_${PACKAGE}_summary.txt ${PACKAGE} -- lxd local:${IMAGE_ALIAS} &>> ${LOG_DIR}/autopkgtest_${PACKAGE}_debug.log
      echo -e "\t\tDONE\n"
      sed -e 's/^/            /' ${LOG_DIR}/autopkgtest_${PACKAGE}_summary.txt | grep -v PASS
      echo
    done # for all package list
    echo 
  done # for all OS list
else
  echo "ERROR: unknown branch '${branch}' it needs to be one of this:"
  # ${BRANCH_LIST[@]}"
  for i in ${BRANCH_LIST[@]}
  do
    echo -e "\t${i}"
  done
  exit 100
fi

markdown2 -x toc /var/www/html/reports/screen_output_${branch}_$(date +'%Y-%m-%d').log > /var/www/html/reports/screen_output_${branch}_$(date +'%Y-%m-%d').html
