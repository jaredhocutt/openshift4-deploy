# Amazon Web Services GovCloud (Generic Installation) - Air-gapped

In order to deploy OpenShift 4 in an air-gapped environment, there are a few
stages to the process when using the automation in this repository.

The high-level workflow is:

- Create bundle of content required to deploy OpenShift from an internet
  connected machine
- Copy bundle of content to air-gapped environment
- Unpack bundle of content and deploy support infrastructure to host content in
  air-gapped environment
- Deploy OpenShift 4 cluster using content hosted in air-gapped environment


## Create Bundle

In order to deploy OpenShift 4 in an air-gapped environment, you will need to
bring the content required to perform the install into that environment.

You will need a machine to use for running the automation that will bundle the
content you need. This machine has the following requirements:

- Exists **outside** of the air-gapped environment
- Has access to the internet
- Has at least 30 GB of free space
- Has at least 4 GB of RAM

> This automation is developed, tested, and documented with the assumption that
> the machine being used to run the automation is RHEL 8.2. While it may run on
> other versions or other distributions, it is not tested or documented.

Enable the required repositories.

```bash
# If you are running on RHEL 8.2 in AWS
sudo yum-config-manager \
    --enable rhel-8-baseos-rhui-rpms \
    --enable rhel-8-appstream-rhui-rpms

# If you are running on RHEL 8.2 elsewhere
sudo yum-config-manager \
    --enable rhel-8-for-x86_64-baseos-rpms \
    --enable rhel-8-for-x86_64-appstream-rpms
```

Install the required packages.

```bash
sudo yum module enable -y \
    python36 \
    container-tools

sudo yum install -y \
    python36 \
    podman \
    skopeo \
    git \
    tar
```

Clone this repository.

```bash
git clone https://github.com/jaredhocutt/openshift4-deploy.git
```

**Step 3**

Change your current directory to the cloned repository.

```bash
cd openshift4-deploy/
```

> **NOTE:** The following sections of documentation will assume that you are in
> the root directory of the clone repository.

Create a variable file at `vars/bundle.yml`.

```yaml
---

# The OpenShift version to install.
#
# The version must include the z-stream (e.g.4.4.3)
#
# The list of versions can be found at
# http://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/
openshift_version: 4.5.2

# The content of your pull secret, which can be found at
# https://cloud.redhat.com/openshift/install/pull-secret.
#
# Be sure to wrap its value in single quotes.
pull_secret: ''
```

Execute the automation to create the bundle.

By default the content will be storage in a `bundle` directory of your local
copy of this repository. If you would like for the bundle to be downloaded
somewhere else, use the `--bundle-dir` option in the command below.

```bash
./openshift-deploy bundle export --vars-file vars/bundle.yml
```

After the bundle export is complete, you will have a `bundle` directory.

```text
» tree --filelimit 10 --noreport bundle
bundle
└── 4.5.1
    ├── images
    │   ├── docker-io-library-registry-2.tar
    │   └── localhost-openshift4-bundle-4-5-1.tar
    ├── release
    │   ├── config
    │   │   └── signature-sha256-a656048696e79a30.yaml
    │   └── v2
    │       └── openshift
    │           └── release
    │               ├── blobs [339 entries exceeds filelimit, not opening dir]
    │               └── manifests [220 entries exceeds filelimit, not opening dir]
    └── rhcos
        ├── rhcos-45.82.202007141718-0-aws.x86_64.vmdk.gz
        └── rhcos-4.5.json
```

Inside of the `bundle` directory, you will have an archive file located at
`bundle/{{ openshift_version }}/bundle.tar`.

You will need this archive file in a later step.


## Air-gapped Environment Setup

This repository assume that you have a minimal initial setup for your
air-gapped environment.

The reason for this is mostly due to each organization uses their own unique
rules for how the network is configured to be air-gapped. Therefore, they
usually already have an existing environment that must be used for deployment.

In the air-gapped environment, you must have:

- An existing VPC
  - `enableDnsSupport` must be enabled
  - `enableDnsHostnames` must be enabled
- At least three (3) private subnets
  - Each subnet is _ideally_ in a different availability zone, but not required
- A bastion host
  - Running RHEL 8.2
  - Have at least 30 GB of free space
  - Have access to the VPC network in order to connect to instances that will
    be created by the automation
  - Have access to the AWS API endpoints
  - Have access to RHEL 8 repositories to install the following packages (or
    already have the packages installed):
    - python3
    - podman
    - skopeo
    - git
    - tar

As stated above, it's highly likely in a production environment to already have
the items listed above in place or the infrastructure to create them.

However, the above is not always true in a development environment. To make it
easier to deploy in such environments, a CloudFormation template is provided to
assist in creating this minimal setup for use during development of this
automation.

> **IMPORTANT:** The CloudFormation template linked below will create a public
> subnet and a bastion host that has a public IP address. The bastion host does
> not have access to the internet except for to access to RHUI repositories in
> AWS. This is _not_ a true air-gapped box and is just a simulated air-gapped
> bastion to use in development.

[CloudFormation Template](../assets/cf-initial-infra.yaml)

If you are setting up a development environment, deploy the CloudFormation
template replacing the parameter values to match your environment.

```bash
export AWS_PROFILE=govcloud
export AWS_DEFAULT_REGION=us-gov-east-1

export CLUSTER_NAME=ocp4
export BASE_DOMAIN=example.com
export RHEL8_AMI=ami-07cd882114d14e9f4
export KEYPAIR=mykeypair

aws cloudformation create-stack \
  --stack-name $(echo "${CLUSTER_NAME}.${BASE_DOMAIN}" | sed "s/\./-/g") \
  --template-body file://docs/assets/cf-initial-infra.yaml \
  --parameters \
    ParameterKey=ClusterName,ParameterValue=${CLUSTER_NAME} \
    ParameterKey=BaseDomain,ParameterValue=${BASE_DOMAIN} \
    ParameterKey=Rhel8Ami,ParameterValue=${RHEL8_AMI} \
    ParameterKey=KeyPairName,ParameterValue=${KEYPAIR}
```

## Copy Bundle

You will need to copy the bundle archive file to air-gapped environment.

> You can find the bundle archive file inside of the `bundle` directory located
> at `bundle/{{openshift_version }}/bundle.tar`.

This document will not cover the details of _how_ to move the content as that
is unique to each environment. **You will need to use the approved method of
transfer to bring the bundle into the air-gapped environment.**

If you are setting up a development environment and used the CloudFormation
template above, you can use the `hack/dev-copy-bundle.sh` script to copy the
bundle archive to your bastion host.

```bash
# Interactive method
./hack/dev-copy-bundle.sh
Bastion Public IP: 18.253.219.185
SSH Private Key File: ~/.ssh/aws/govcloud/default.pem
Bundle Archive File: bundle/bundle-4.5.0.tar

# Non-interactive method
./hack/dev-copy-bundle.sh 18.253.219.185 ~/.ssh/aws/govcloud/default.pem bundle/bundle-4.5.0.tar
```
