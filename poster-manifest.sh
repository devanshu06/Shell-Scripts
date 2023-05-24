#!/bin/bash
exec 5>&1
# Requirement Download the sshpass in ubuntu: sudo apt update && sudo apt install sshpass -y
#Created Variable to SSH into the Swarm Master and get the details 
USER="administrator"
MASTER_SWARM_IP=""
PASSWORD=""

#Created these variable to confirm the Files are created or not
folder_path="/mnt/fsvol0/poster-arts/manifest"
current_date=$(sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no "${USER}"@"${MASTER_SWARM_IP}" "date +%Y-%m-%d")

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
    "node ./commands.js createManifest ccap --type logo"
    "node ./commands.js createManifest nwtel --type logo"
    "node ./commands.js createManifest ccap --type back-splash --assetType LIVE --selectionType primary --aspectRatio 16:9"
    "node ./commands.js createManifest ccap --type back-splash --assetType VOD  --aspectRatio 16:9"
    "node ./commands.js createManifest ccap --type poster --assetType VOD --aspectRatio 2:3"
    "node ./commands.js createManifest ccap --type genre"
    "node ./commands.js createManifest nwtel --type back-splash --assetType LIVE --selectionType primary --aspectRatio 16:9"
    "node ./commands.js createManifest nwtel --type back-splash --assetType VOD  --aspectRatio 16:9"
    "node ./commands.js createManifest nwtel --type poster --assetType VOD --aspectRatio 2:3"
    "node ./commands.js createManifest nwtel --type genre"
    "node ./commands.js createManifest ozarksgo --type back-splash --assetType LIVE --selectionType primary --aspectRatio 16:9"
    "node ./commands.js createManifest farmerssc --type back-splash --assetType LIVE --selectionType primary --aspectRatio 16:9"
    )

#Files are mapped with the above commands if you change the command then change the files also with the approriate name and path 
FILES=(
    "$folder_path/test.json"
    # "$folder_path/ccap_channel_logo.json"
    "$folder_path/nwtel_channel_logo.json"
    "$folder_path/ccap_LIVE_primary_back-splash_16:9.json"
    "$folder_path/ccap_VOD_back-splash_16:9.json"
    "$folder_path/ccap_VOD_poster_2:3.json"
    "$folder_path/ccap_LIVE_genre.json"
    "$folder_path/nwtel_LIVE_primary_back-splash_16:9.json"
    "$folder_path/nwtel_VOD_back-splash_16:9.json"
    "$folder_path/nwtel_VOD_poster_2:3.json"
    "$folder_path/nwtel_LIVE_genre.json"
    "$folder_path/ozarksgo_LIVE_primary_back-splash_16:9.json"
    "$folder_path/farmerssc_LIVE_primary_back-splash_16:9.json"
)

# Added the varibales to get the details in for loop and able to execute the conditions
counter=0 
error=0
failed_values=() #adding the error commands in this variable to get the exact commands that don't run successfully

for operators in "${MANIFESTS[@]}"; do
    echo "==================================================================================="
    echo "Running the Command: ${operators}"
    RESPONE=$(sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no "${USER}"@"${NODE_IP}" "docker exec ${CONTAINER_ID} ${operators}" | tee /dev/fd/5)
    last_modified=$(sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no "${USER}"@"${MASTER_SWARM_IP}" "date -r "${FILES[$counter]}" +%Y-%m-%d")
    file_size=$(sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no "${USER}"@"${MASTER_SWARM_IP}" " du -sh "${FILES[$counter]}" | awk '{print \$1}'")
    echo "The file ${FILES[$counter]} was last modified on: ${last_modified}"
    echo "Checking File Modification Date and File Size"
    # Compare the last modified date with the current date
    if [ "$last_modified" != "$current_date" ] || [ "$file_size" == 0 ]; then
        echo "The file '${FILES[$counter]}' has not been updated today or the file size is not appropriate."
        echo "${FILES[$counter]} Size: ${file_size}"
        failed_values+=("$operators")
        ((counter++))
        ((error++))
    else
        echo "${FILES[$counter]} Size: ${file_size}"
        echo "Command ran successfully: ${operators}" 
        echo "File Created: ${FILES[$counter]}"
        echo "==================================================================================="
        ((counter++))
    fi
done

if [ $error -gt 0 ]; then
	echo "Number of failed Commands: $error"
    #echo "Failed commands: ${failed_values[@]}"
    echo "Failed Commands:"
    for value in "${failed_values[@]}"; do
        echo "$value"
    done
    exit 1
fi