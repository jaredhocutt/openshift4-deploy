# OpenShift 4 Deploy

Deploy OpenShift 4 on the following platforms:

- AWS

**IMPORTANT**

This project uses the **bare metal** method of installation on all platforms
listed above. This translates to there being **NO** integration with the underlying
infrastructure provider.

**TODO: Describe what you're giving up (e.g. machine sets, load balancer, **

If you would like a cluster that provides integration with the underlying
infrastructure provider, please see the built-in installation methods provided
with the OpenShift installer:
https://docs.openshift.com/container-platform/latest/welcome/index.html

## Getting Started

This project uses `pipenv` to create an isolated Python environment for running
the automation. If you do not already have `pipenv` installed on your system,
follow the instructions here:
https://pipenv.pypa.io/en/latest/install/#installing-pipenv

Clone this repository.

```bash
git clone https://github.com/jaredhocutt/openshift4-deploy.git
```

Change your current directory to the cloned repository.

```bash
cd openshift4-deploy/
```

Create the `pipenv` environment and install the dependencies.

```bash
pipenv install
```

## Running The Automation

### AWS

#### Step 1

Change your current directory to the cloned repository.

```bash
cd openshift4-deploy/
```

Activate the `pipenv` environment.

```bash
pipenv shell
```

#### Step 2

Export your AWS credentials and the region to use.

If you already have a profile setup using the
`awscli`, you can export `AWS_PROFILE`.

```bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
```

Otherwise, export `AWS_ACCESS_KEY_ID`
and `AWS_SECRET_ACCESS_KEY`.

```bash
export AWS_ACCESS_KEY_ID=access_key
export AWS_SECRET_ACCESS_KEY=secret=key
export AWS_REGION=us-east-1
```

#### Step 3

*If you already have an AWS key pair that you would like to use, you can skip
this step.*

If you do not have an AWS key pair or would like to create one specific to this
environment, log into the AWS console and create one in the region where you
will be deploying OpenShift 4.

Be sure to remember the **name** of the key pair and the **path** where you
saved the private key file as you will need them in the next step.

#### Step 4

Create a variable file at `<openshift4-deploy>/vars/ocp4.yml`.

```yaml
---

cloud: aws

openshift_version: 4.3.18

cluster_name: ocp4
base_domain: example.com

rhcos_ami: ami-123456789
keypair_name: mykeypair
keypair_path: ~/.ssh/mykeypair.pem

pull_secret: ''
```

Edit the variable file to contain the information specific to your
environment.

| Variable            | Required           | Default | Description                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ------------------- | ------------------ | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `base_domain`       | :heavy_check_mark: |         | The base domain of the cluster.<br><br>All DNS will be sub-domains of this base and include the `cluster_name`.                                                                                                                                                                                                                                                                                                                        |
| `cloud`             | :heavy_check_mark: |         | The cloud provider to deploy to.<br><br>You should set this to `aws` to deploy to AWS.                                                                                                                                                                                                                                                                                                                                                 |
| `cluster_name`      | :heavy_check_mark: |         | The cluster name.<br><br>This value will be in your DNS entries and should conform to valid DNS characters.                                                                                                                                                                                                                                                                                                                            |
| `keypair_name`      | :heavy_check_mark: |         | The name of the AWS key pair to use for the bastion host.                                                                                                                                                                                                                                                                                                                                                                              |
| `keypair_path`      | :heavy_check_mark: |         | The path to the private key for your AWS key pair.                                                                                                                                                                                                                                                                                                                                                                                     |
| `openshift_version` | :heavy_check_mark: |         | The OpenShift version to install.                                                                                                                                                                                                                                                                                                                                                                                                      |
| `pull_secret`       | :heavy_check_mark: |         | The content of your pull secret, which can be found [here][pull_secret]. Be sure to wrap its value in single quotes.                                                                                                                                                                                                                                                                                                                   |
| `rhcos_ami`         | :heavy_check_mark: |         | The AMI ID for RHCOS.<br><br>If you are deploying into a commercial AWS region, the AMI ID can be found [here][rhcos_ami_ids]. Be sure to the documentation you are looking at matches the version of OpenShift you are deploying to get the correct AMI IDs.<br><br>If you are deploying in AWS GovCloud, you will need to upload the RHCOS image and create your own AMI. After doing so, you can use that AMI ID for this variable. |

[pull_secret]: https://cloud.redhat.com/openshift/install/metal/user-provisioned
[rhcos_ami_ids]: https://docs.openshift.com/container-platform/latest/installing/installing_aws/installing-aws-user-infra.html#installation-aws-user-infra-rhcos-ami_installing-aws-user-infra

#### Step 5

Log into the AWS console and create a public Route53 hosted zone for your
cluster. The name **must** match the format `{{ cluster_name }}.{{ base_domain }}`
using the values you specified for those in your variable file.

Be sure to create `NS` records on the base domain to point to your new hosted
zone. You can grab the values for the `NS` record by viewing your hosted zone.

![Route53 NS Record](docs/images/route53_ns.png)

#### Step 5

Execute the automation while passing in your variable file.

```bash
ansible-playbook -e @vars/ocp4.yml playbooks/create_cluster.yml -v
```
