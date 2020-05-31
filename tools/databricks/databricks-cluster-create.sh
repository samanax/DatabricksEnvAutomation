#!/bin/bash

CLUSTER_NAME=$1
[[ -z "$CLUSTER_NAME" ]] && exit 1
# cluster name must be passed as parameter

# creating the pool-instance
#echo "Creating Pool"
#cat config.pool.json | sed "s/CLUSTER_NAME/$CLUSTER_NAME/g" > /tmp/pool.conf.json
#POOL_ID=$(databricks instance-pools create --json-file /tmp/pool.conf.json | jq -r  '.instance_pool_id')
#echo "Pool Creation done!"

cat config.cluster.json | sed "s/CLUSTER_NAME/$CLUSTER_NAME/g" | sed "s/POOL_ID/$POOL_ID/g" > /tmp/conf.json
#cat config.cluster.json | sed "s/CLUSTER_NAME/$CLUSTER_NAME/g" | sed "s/POOL_ID/$POOL_ID/g" > /tmp/conf.json

echo "Creating Cluster"
CLUSTER_ID=$(databricks clusters create --json-file /tmp/conf.json | jq -r '.cluster_id')

STATE=$(databricks clusters list --output json | jq -r --arg I "$CLUSTER_ID" '.clusters[] | select(.cluster_id == $I) | .state')

echo "Wait for cluster to be PENDING"
while [[ "$STATE" != "PENDING" ]]
do
    STATE=$(databricks clusters list --output json | jq -r --arg I "$CLUSTER_ID" '.clusters[] | select(.cluster_name == $I) | .state')
done

# the API is flaky and the library install complains about terminated clusters
# so wait a bit more before continuing task
sleep 10

echo "Cluster $CLUSTER_ID is pending"
