#!/bin/bash
set -eou pipefail

. utils.sh

announce "Retrieving secret using Conjur access token."

set_project $TEST_APP_PROJECT_NAME

test_app_pod=$(kubectl get pods --no-headers | awk '{ print $1 }')

kubectl exec -c test-app $test_app_pod -- curl -s localhost