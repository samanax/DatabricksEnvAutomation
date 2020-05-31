#!/bin/bash

HOST=$1
TOKEN=$2
if [[ -z $HOST || -z $TOKEN ]]
then
    echo 'The Databricks host URL and secret access token must be passed from job VM'
    exit 1
fi

python -m pip install databricks-cli
echo $HOME
echo -e "[DEFAULT]\nhost: $HOST\ntoken: $TOKEN" > $HOME/.databrickscfg
echo -e "Testing the conncection - listing dbfs:/"
dbfs ls