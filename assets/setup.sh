#!/bin/bash
set -e

CLUSTER_JSON_FILE="./cluster.json"
INSTANCE_POOL_JSON_FILE="./instance-pool.json"
WAIT_TIME=10

wait_for_cluster_running_state () {
  while true; do
    CLUSTER_STATUS=$(databricks clusters get --cluster-id $CLUSTER_ID | jq -r '.state')
    if [[ $CLUSTER_STATUS == "RUNNING" ]]; then
        echo "Operation ready."
        break
    fi
    echo "Cluster is still in pending state, waiting $WAIT_TIME sec.."
    sleep $WAIT_TIME
  done
}

wait_for_pool_running_state () {
  while true; do
    POOL_STATUS=$(databricks instance-pools get --instance-pool-id $POOL_INSTANCE_ID | jq -r '.state')
    if [[ $POOL_STATUS == "ACTIVE" ]]; then
        echo "Operation ready."
        break
    fi
    echo "Pool instance is still in not ready yet, waiting $WAIT_TIME sec.."
    sleep $WAIT_TIME
  done
}

arr=( $(databricks clusters list --output JSON | jq -r '.clusters[].cluster_name'))
echo "Current clusters:"
echo "${arr[@]}"

CLUSTER_NAME=$(cat $CLUSTER_JSON_FILE | jq -r  '.cluster_name')

# Cluster already exists
if [[ " ${arr[@]} " =~ $CLUSTER_NAME ]]; then
    echo 'The cluster is already created for Planmeca, skipping the cluster operation.'
    exit 0
fi

# Cluster does not exist
if [[-z "$arr" || ! " ${arr[@]} " =~ $CLUSTER_NAME ]]; then
  printf "Setting up the databricks environment. Cluster name: %s\n" $CLUSTER_NAME

  #Fetching pool-instances
  POOL_INSTANCES=( $(databricks instance-pools list --output JSON | jq -r 'select(.instance_pools != null) | .instance_pools[].instance_pool_name'))
  POOL_NAME=$(cat $INSTANCE_POOL_JSON_FILE | jq -r  '.instance_pool_name')
  if [[ -z "$POOL_INSTANCES" || ! " ${POOL_INSTANCES[@]} " =~ $POOL_NAME ]]; then
    # Creating the pool-instance
    printf 'Creating new Instance-Pool: %s\n' $POOL_NAME
    POOL_INSTANCE_ID=$(databricks instance-pools create --json-file $INSTANCE_POOL_JSON_FILE | jq -r '.instance_pool_id')
    wait_for_pool_running_state
  fi

  if [[ " ${POOL_INSTANCES[@]} " =~ $POOL_NAME ]]; then
    POOL_INSTANCE_ID=$(databricks instance-pools list --output JSON | jq -r --arg I "$POOL_NAME" '.instance_pools[] | select(.instance_pool_name == $I) | .instance_pool_id')
    printf 'The Pool already exists with id: %s\n' $POOL_INSTANCE_ID
  fi

  # Transforming the cluster json
  NEW_CLUSTER_CONFIG=$(cat $CLUSTER_JSON_FILE | jq -r --arg var $POOL_INSTANCE_ID '.instance_pool_id = $var')

  # Creating databricks cluster with the cluster.json values
  printf 'Creating cluster: %s\n' $CLUSTER_NAME

  CLUSTER_ID=$(databricks clusters create --json "$NEW_CLUSTER_CONFIG" | jq -r '.cluster_id')
  wait_for_cluster_running_state

  # Adding cosmosdb Library to the cluster
  printf 'Adding the cosmosdb library to the cluster %s\n' $CLUSTER_ID
  databricks libraries install \
    --cluster-id $CLUSTER_ID \
    --maven-coordinates "com.microsoft.azure:azure-cosmosdb-spark_2.4.0_2.11:1.3.5"
  wait_for_cluster_running_state
  echo 'CosmosDB-Spark -library added successfully.'
  
  echo "Databricks setupped successfully."
fi
