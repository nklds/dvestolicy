#!/bin/sh
#docker pull images
docker pull nginx:alpine
docker pull node:14-alpine3.17
#end docker pull images
#set variables
cp .env.example .env
sed -ri -e "s!domainhere!${DOMAIN}!g" .env
#end set variables
#Docker build project
docker compose -f docker-compose-server.yml build
if [ $? -eq 0 ] 
then 
  echo "Successfully build" 
else 
  echo "Could not create build, ERROR, see Errors" >&2
  exit 1
fi
#Docker login to docker registry
echo ${DOCKER_REGISTRY_PWD} | docker login ${DOCKER_REGISTRY_SITE} -u ${DOCKER_REGISTRY_USER} --password-stdin
#Docker push image
docker compose -f docker-compose-server.yml push
#Docker delete images after build on Jenkins slave
docker rmi -f ${DockerRegistryURL}/dve-stolicy:${BranchName}-${BuildTimestamp}-${HashCommit}