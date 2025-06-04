#!/usr/bin/bash

if [[ "$#" -le 2 ]]; then
    echo "ERROR: please provide distribution name and realase"
    echo "example: $0 ubuntu 24.04i repo-branch" 
    exit 1
fi
DISTNAME="${1:-ubuntu}"
DISTVER="${2:-24.04}"
BRANCH="${3:perfsonar-release}"
BRANCH_LIST=( `cat repo.list` )
# check we know the branch exists
if ! grep -E -- "^${BRANCH}$" repo.list > /dev/null
 then
     echo "'${BRANCH}' is not in repo.list"
     exit 1 
fi 
REPO_NAME="${BRANCH}"
REPO_NAME_GPG="${BRANCH/-[a-z]*-/-}"
ALIAS="tmp-base-${REPO_NAME}-${DISTNAME}-${DISTVER//\.*}"
IMAGE_ALIAS="${REPO_NAME}-autopkgtest-${DISTNAME}-${DISTVER//\.*}"

# launch a base OS image 
if [ ${DISTNAME} == 'ubuntu' ]
 then
     IMAGE_NAME="${DISTNAME}:${DISTVER}"
elif [ ${DISTNAME} == 'debian' ] 
 then
     IMAGE_NAME="images:${DISTNAME}/${DISTVER}"
fi

if ! lxc launch ${IMAGE_NAME} ${ALIAS}
  then
      echo "ERROR: failed to launch image ${DISTNAME}:${DISTVER} "
      exit 2
fi

# customise it ready for perfsonar
lxc exec ${ALIAS} -- bash <<!
sleep 5
ping -c5 downloads.perfsonar.net
DEBIAN_FRONTEND=noninteractive apt update && apt install -y lsb-release ca-certificates curl gnupg
cat >/etc/apt/sources.list.d/perfsonar-release.list  <<EOF
deb https://downloads.perfsonar.net/debian/ ${REPO_NAME} main
deb-src https://downloads.perfsonar.net/debian/ ${REPO_NAME} main
EOF
curl -s -o /etc/apt/trusted.gpg.d/${REPO_NAME_GPG}.gpg.asc https://downloads.perfsonar.net/debian/${REPO_NAME_GPG}.gpg.key

#curl -o- https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg --dearmor --batch --yes -o /usr/share/keyrings/opensearch-keyring
#echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | tee /etc/apt/sources.list.d/opensearch-2.x.list
#DEBIAN_FRONTEND=noninteractive apt update && OPENSEARCH_INITIAL_ADMIN_PASSWORD=perfSONAR-123 apt install -y opensearch

DEBIAN_FRONTEND=noninteractive apt clean
!

# stop the container
lxc stop ${ALIAS}

# cleanup old image 
lxc image delete ${IMAGE_ALIAS}
# pubblish new image to local repo 
lxc publish ${ALIAS} --alias ${IMAGE_ALIAS}
lxc image set-property ${IMAGE_ALIAS} description "${DISTNAME} ${DISTVER} with preconfigured ${REPO_NAME} repository"

# cleanup tmp container, ready for next run 
lxc delete ${ALIAS}

echo -e "\n\n\t\tdone creating ${IMAGE_ALIAS}\n"

