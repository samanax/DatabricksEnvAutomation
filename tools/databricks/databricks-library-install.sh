#!/bin/bash
CLUSTER_NAME=$1

if [[ -z "$CLUSTER_NAME" ]]
then
    echo 'The cluster name must be passed as parameter'
    exit 1
fi

CLUSTER_ID=$(databricks clusters list --output json | jq -r --arg N "$CLUSTER_NAME" '.clusters[] | select(.cluster_name == $N) | .cluster_id')

databricks libraries install --cluster-id $CLUSTER_ID --maven-coordinates "com.microsoft.azure:azure-cosmosdb-spark_2.4.0_2.11:1.3.5"
# databricks libraries install --cluster-id $CLUSTER_ID --pypi-package azure
# databricks libraries install --cluster-id $CLUSTER_ID --pypi-package googlemaps
# databricks libraries install --cluster-id $CLUSTER_ID --pypi-package python-tds
# databricks libraries install --cluster-id $CLUSTER_ID --cran-package tidyverse


