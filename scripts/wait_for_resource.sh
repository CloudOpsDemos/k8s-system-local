#!/bin/bash

# This script waits for a resource to be available before proceeding.
# Usage: ./wait_for_resource.sh <resource_name> <timeout_in_seconds> <namespace> <OPT:resource_type>
# Example: ./wait_for_resource.sh my_resource 300 my_namespace ingress
# Check if the correct number of arguments is provided

RESOURCE_NAME=$1
TIMEOUT=$2
NAMESPACE=$3
RESOURCE_TYPE="${4:-"pods"}"
TIME_COUNTER=0
STEP=3

echo "Waiting for ${RESOURCE_NAME} to be available..."
while ! kubectl get ${RESOURCE_TYPE} -n $NAMESPACE | grep -q "${RESOURCE_NAME}"
do
    sleep ${STEP}
    TIME_COUNTER=$[$TIME_COUNTER + $STEP]
    if [ $TIME_COUNTER -ge $TIMEOUT ]; then
        echo "Timeout ${TIMEOUT} seconds waiting for ${RESOURCE_NAME}"
        exit 1
    fi
done

echo "${RESOURCE_NAME} is now available in namespace ${NAMESPACE}."