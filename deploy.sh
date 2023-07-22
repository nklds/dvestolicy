#!/bin/sh
eval `ssh-agent -s`
ssh-add ~/.ssh/dockerremote
docker -H "ssh://${DOCKER_SWARM_HOST}" network create --driver=overlay traefik-public || true
sleep 5
docker -H "ssh://${DOCKER_SWARM_HOST}" pull ${DockerRegistryURL}/dve-stolicy:${BranchName}-${BuildTimestamp}-${HashCommit}
sleep 5
env $(cat .env | grep ^[A-Z] | xargs) docker -H "ssh://${DOCKER_SWARM_HOST}" stack deploy -c docker-compose-server.yml dve-stolicy --with-registry-auth