#!/bin/bash 
IFS=$' \t\r\n'

REPO_URL="172.22.237.61:5000"

REPO_NAME="dev06/testimage-02"

IMAGE_DIGEST=$(cat output.txt | sort -t '-' -k 2n | awk '{print $2}' )

for digest in $IMAGE_DIGEST
do
    DELETE=$(curl -i -X DELETE "http://${REPO_URL}/v2/${REPO_NAME}/manifests/${digest}" | grep HTTP/1.1)
    echo "Deleted: ${digest} - Response: ${DELETE}"
done