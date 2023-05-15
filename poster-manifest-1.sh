#!/bin/bash
exec 5>&1
# Requirement Download the sshpass in ubuntu: sudo apt update && sudo apt install sshpass -y
USER="administrator"
MASTER_SWARM_IP="10.50.11.51"
PASSWORD="Admin01!"

echo "Fetching the Node Name..." 
NODE_NAME=$(sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no "${USER}"@"${MASTER_SWARM_IP}" "docker service ps tv2-poster-arts-v2-prod_poster-manifest | grep Runn | awk '{print \$4}'")
echo "NodeName: ${NODE_NAME}"

echo "Fetching the Node IP..." 
NODE_IP=$(sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no "${USER}"@"${MASTER_SWARM_IP}" " docker node inspect --format '{{ .Status.Addr }}' ${NODE_NAME}") 
echo "NodeIP: ${NODE_IP}"

#Fetching the Docker Container ID

echo "Fetching the poster-manifest ContainerID on ${NODE_IP}"
CONTAINER_ID=$(sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no "${USER}"@"${NODE_IP}" "docker ps | grep tv2-poster-arts-v2-prod_poster-manifest | awk '{print \$1}'") 
echo "ContainerID: ${CONTAINER_ID}"

#Manifests Running Code Below:
MANIFESTS=(
    "node ./commands.js createManifest nwtel --type back-splash --assetType VOD  --aspectRatio 16:9"
    "node ./commands.js createManifest nwtel --type poster --assetType VOD --aspectRatio 2:3"
    "node ./commands.js createManifest nwtel --type logo"
    "node ./commands.js createManifest ccap --type logo"
    "node ./commands.js createManifest ccap --type genre"
    "node ./commands.js createManifest nwtel --type genre"
    ) 

for operators in "${MANIFESTS[@]}"; do
    echo "Running the Command: ${operators}"
    RESPONSE=$(sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no "${USER}"@"${NODE_IP}" "docker exec ${CONTAINER_ID} ${operators}" | tee /dev/fd/5)
    echo "${RESPONSE}" 
    echo "Command ran successfully: ${operators}" 
done



# echo "All commands completed"

#     if [ $? -eq 0 ]; then
#         echo "${RESPONSE}"
#         echo "Command ran successfully: ${operator}"
#     else
#         echo "Command failed: ${operator}"
#         echo "Check You VPN Connection It maybe down"
#         echo "Retrying command: ${operator}"
#         RESPONSE=$(sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no "${USER}"@"${NODE_IP}" "docker exec ${CONTAINER_ID} ${operator}" | tee /dev/fd/5)
#     fi
# done