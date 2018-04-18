#!/bin/bash 
set -eou pipefail

. utils.sh

announce "Configuring followers."

set_namespace $CONJUR_NAMESPACE_NAME

master_pod_name=$(get_master_pod_name)

echo "Preparing follower seed files..."

kubectl exec $master_pod_name evoke seed follower conjur-follower > ./build/conjur/follower-seed.tar

pushd build/conjur
  ./build_follower.sh
popd

rm ./build/conjur/follower-seed.tar

docker_tag_and_push "conjur-appliance-follower"

echo "Follower image built."

conjur_appliance_image=$DOCKER_REGISTRY_PATH/conjur-appliance-follower:$CONJUR_NAMESPACE_NAME

echo "deploying followers"
sed -e "s#{{ CONJUR_APPLIANCE_IMAGE }}#$conjur_appliance_image#g" ./manifests/conjur-follower.yaml |
  sed -e "s#{{ AUTHENTICATOR_SERVICE_ID }}#$AUTHENTICATOR_SERVICE_ID#g" |
  kubectl create -f -

echo "Followers deployed."
