#!/bin/bash
REPO_URL="172.22.237.61:5000"

REPO_NAME="dev06/testimage-02"

IMAGE_TAGS=$(curl --location http://${REPO_URL}/v2/${REPO_NAME}/tags/list | jq -r '.tags[]')

for tag in $IMAGE_TAGS
do
  DIGEST=$(curl -i http://${REPO_URL}/v2/${REPO_NAME}/manifests/${tag} --header 'Accept: application/vnd.docker.distribution.manifest.v2+json' | grep 'Docker-Content-Digest' | awk {'print $2'} )
  echo "${tag}: ${DIGEST}"
done