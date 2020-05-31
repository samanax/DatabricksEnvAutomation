#!/bin/bash
CLUSTER_NAME=$1
[[ -z "$CLUSTER_NAME" ]] && exit 1  # cluster name must be passed as parameter

CLUSTER_ID=$(databricks clusters list --output json | jq -r --arg N "$CLUSTER_NAME" '.clusters[] | select(.cluster_name == $N) | .cluster_id')

# It is possible to create multiple clusters with the same name
# therefor looping
for ID in $CLUSTER_ID
do
    echo "Deleting $ID"
    databricks clusters permanent-delete --cluster-id $ID
done