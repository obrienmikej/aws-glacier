#!/usr/bin/env bash

file='./YOUR_VAULT_NAME.json'
id_file='./YOUR_VAULT_NAME.txt'

if [[ -z ${AWS_ACCOUNT_ID} ]] || [[ -z ${AWS_REGION} ]] || [[ -z ${AWS_VAULT_NAME} ]]; then
        echo "Please set the following environment variables: "
        echo "AWS_ACCOUNT_ID"
        echo "AWS_REGION"
        echo "AWS_VAULT_NAME"
        exit 1
fi

echo "Started at $(date)"

echo -n "Getting archive ids from $file..."
if [[ ! -f $id_file ]]; then
  cat $file | jq -r --stream ". | { (.[0][2]): .[1]} | select(.ArchiveId) | .ArchiveId" > $id_file 2> /dev/null
fi
total=$(wc -l $id_file | awk '{print $1}')
echo "got $total"

num=0
while read -r archive_id; do
  num=$((num+1))
  echo "Deleting archive $num/$total at $(date)"
  aws glacier delete-archive --archive-id=${archive_id} --vault-name ${AWS_VAULT_NAME} --account-id ${AWS_ACCOUNT_ID} --region ${AWS_REGION} &
  [ $( jobs | wc -l ) -ge $( nproc ) ] && wait
done < "$id_file"

wait
echo "Finished at $(date)"
echo "Deleted archive ids are in $id_file"