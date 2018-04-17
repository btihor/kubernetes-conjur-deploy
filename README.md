# kubernetes-conjur-deploy

This repository contains scripts for deploying a Conjur v4 cluster to a
Kubernetes environment.

# Setup

The Conjur deployment scripts pick up configuration details from local
environment variables. The setup instructions below walk you through the
necessary steps for configuring your Kubernetes environment and show you which
variables need to be set before deploying.

### Docker

[Install Docker](https://www.docker.com/get-docker) on your local machine if you
do not already have it.

You must have push access to a Docker registry in order to run these deploy
scripts. Provide the URL and full path of your registry:

```
export DOCKER_REGISTRY_URL=<registry-domain>
export DOCKER_REGISTRY_PATH=<registry-domain>/<additional-pathing>
```

If you are using a private registry, you will also need to provide login 
credentials that are used by the deployment scripts to create a [secret for
pulling images](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-in-the-cluster-that-holds-your-authorization-token):

```
export DOCKER_USERNAME=<your-username>
export DOCKER_PASSWORD=<your-password>
export DOCKER_EMAIL=<your-email>
```

Please make sure that you are logged in to the registry before deploying.

### Kubernetes

Before deploying Conjur, you must first use `kubectl` to connect to your
Kubernetes environment with a user that has the `cluster-admin` role. The user
must be able to create namespaces and cluster roles.

#### Conjur Namespace

Provide the name of a namespace in which to deploy Conjur:

```
export CONJUR_NAMESPACE_NAME=<my-namespace>
```

#### The `conjur-authenticator` Cluster Role

Conjur's Kubernetes authenticator requires the following privileges:

- [`"get"`, `"list"`] on `"pods"` for confirming a pod's namespace membership
- [`"create"`, `"get"`] on "pods/exec" for injecting a certificate into a pod

The deploy scripts include a manifest that defines the `conjur-authenticator`
cluster role, which grants these privileges. Create the role now (note that
your user will need to have the `cluster-admin` role to do so):

```
kubectl create -f ./manifests/conjur-authenticator-role.yaml
```

### Conjur

#### Appliance Image

You need to obtain a Docker image of the Conjur v4 appliance and push it to your
Docker registry with the tag:

```
$DOCKER_REGISTRY_PATH/conjur-appliance:$CONJUR_NAMESPACE_NAME
```

#### Appliance Configuration

When setting up a new Conjur installation, you must provide an account name and
a password for the admin account:

```
export CONJUR_ACCOUNT=<my_account_name>
export CONJUR_ADMIN_PASSWORD=<my_admin_password>
```

Conjur uses [declarative policy](https://developer.conjur.net/policy) to control
access to secrets. After deploying Conjur, you need to load a policy that
defines a `webservice` to represent the Kubernetes authenticator:

```
- !policy
id: conjur/authn-k8s/{{ SERVICE_ID }}
```

The `SERVICE_ID` should describe the Kubernetes cluster in which your Conjur
deployment resides. For example, it might be something like `kubernetes/prod`.
For Conjur configuration purposes, you need to provide this value to the Conjur
deploy scripts like so:

```
export AUTHENTICATOR_SERVICE_ID=<service_id>
```

This `service_id` can be anything you like, but it's important to make sure
that it matches the value that you intend to use in Conjur Policy.

# Usage

### Deploying Conjur

Run `./start` to deploy Conjur. This executes the numbered scripts in sequence
to create and configure a Conjur cluster comprised of one Master, two Standbys,
and two read-only Followers. The final step will print out the necessary info
for interacting with Conjur through the CLI or UI.

### Conjur CLI

The deploy scripts include a manifest for creating a Conjur CLI container within
the Kubernetes environment that can then be used to interact with Conjur. Deploy
the CLI pod and SSH into it:

```
kubectl create -f ./manifests/conjur-cli.yaml
kubectl exec -it [cli-pod-name] bash
```

Follow our [CLI instructions](https://developer.conjur.net/cli#quickstart)
to get started with the Conjur CLI. The hostname is `conjur-master`, which is a
service that can be used to access the Conjur Master.

### Conjur UI

Visit the Conjur UI URL in your browser and login with the admin credentials to
access the Conjur UI.

# Test App Demo

The [kubernetes-conjur-demo repo](https://github.com/conjurdemos/kubernetes-conjur-demo)
sets up test applications that retrieve secrets from Conjur and serves as a
useful reference when setting up your own applications to integrate with Conjur.
