# OpenShift 4 Deploy

## Table of Contents

- [OpenShift 4 Deploy](#openshift-4-deploy)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Initial Setup](#initial-setup)
  - [Running The Automation](#running-the-automation)
    - [AWS / AWS GovCloud](#aws--aws-govcloud)
      - [Create](#create)
      - [Destroy](#destroy)

## Description

Deploy OpenShift 4 on the following platforms:

- AWS
- AWS GovCloud

:warning:	**IMPORTANT** :warning:

This project uses the **bare metal** method of installation on all platforms
listed above. This translates to there being **NO** integration with the underlying
infrastructure provider.

This means that OpenShift will not be able to:

- Autoscale using `MachineSets`
- Create load balancers automatically for your ingress routers
- Provision storage via the cloud provider plugin (e.g. EBS volumes)

If you would like a cluster that provides integration with the underlying
infrastructure provider, please see the built-in installation methods provided
with the OpenShift installer:
https://docs.openshift.com/container-platform/latest/welcome/index.html

## Initial Setup

**Step 1**

This project provides a container image that includes all of the dependencies
required to run the automation. To run the container image, you will need
either `podman` or `docker` installed on your system.

To install `podman`, follow the instructions here: https://podman.io/getting-started/installation.html

To install `docker`, follow the instructions here: https://docs.docker.com/get-docker/

**Step 2**

Clone this repository.

```bash
git clone https://github.com/jaredhocutt/openshift4-deploy.git
```

## Running The Automation

### AWS / AWS GovCloud

#### Create

**Step 1: Enter the container environment**

Change your current directory to the cloned repository.

```bash
cd openshift4-deploy/
```

Activate a shell inside the container image provided.

```bash
./openshift-deploy shell
```

**Step 2: Export your environment variables**

Export your AWS credentials and the region to use.

If you already have a profile setup using the `awscli`, you can export
`AWS_PROFILE`. Your `~/.aws` directory will already be mounted to the
environment for you.

```bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
```

Otherwise, export `AWS_ACCESS_KEY_ID`
and `AWS_SECRET_ACCESS_KEY`.

```bash
export AWS_ACCESS_KEY_ID=access_key
export AWS_SECRET_ACCESS_KEY=secret-key
export AWS_REGION=us-east-1
```

**Step 3: Create/Identify the SSH keypair for the Bastion host**

*If you already have an AWS key pair that you would like to use, you can skip
this step.*

If you do not have an AWS key pair or would like to create one specific to this
environment, log into the AWS console and create one in the region where you
will be deploying OpenShift 4.

Be sure to remember the **name** of the key pair and the **path** where you
saved the private key file (this is the `.pem` file that you download when
creating your AWS key pair) as you will need them in the next step.

IMPORTANT: The key pair `.pem` file should be in `~/.ssh` as this directory
gets mounted to the environment for you.

**Step 4: Create your variable file**

There are several variables that you will need to define before running the
deployment that are specific to your environment.

| Variable            | Required           | Default | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------- | ------------------ | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `base_domain`       | :heavy_check_mark: |         | The base domain of the cluster.<br><br>All DNS will be sub-domains of this `base_domain` and include the `cluster_name`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `cloud`             | :heavy_check_mark: |         | The cloud provider to deploy to.<br><br>You should set this to `aws` to deploy to AWS and `aws_govcloud` to deploy to AWS GovCloud.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `cluster_name`      | :heavy_check_mark: |         | The cluster name.<br><br>This value will be in your DNS entries and should conform to valid DNS characters.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `keypair_name`      | :heavy_check_mark: |         | The name of the AWS key pair to use for the bastion host.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `keypair_path`      | :heavy_check_mark: |         | The path to the private key for your AWS key pair.<br><br>Note: The private key's integrity will be maintained. It is only used by Ansible to connect to the bastion host.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `openshift_version` | :heavy_check_mark: |         | The OpenShift version to install.<br><br>The version must include the z-stream (e.g. 4.3.18)  The list of versions can be found [here][openshift_versions]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `pull_secret`       | :heavy_check_mark: |         | The content of your pull secret, which can be found [here][pull_secret]. Be sure to wrap its value in single quotes.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `rhcos_ami`         | :heavy_check_mark: |         | The AMI ID for RHCOS.<br><br>If you are deploying into a commercial AWS region, the AMI ID can be found [here][rhcos_ami_ids]. Be sure the documentation you are looking at matches the version of OpenShift you are deploying to get the correct AMI IDs.<br><br>If you are deploying in AWS GovCloud, you will need to upload the RHCOS image and create your own AMI. After doing so, you can use that AMI ID for this variable. You can find details for creating a RHCOS AMI [here](docs/rhcos.md).<br><br>The intention is to add support to have this variable default to a sensible value, but at the moment you will need to provide the AMI ID. |

[pull_secret]: https://cloud.redhat.com/openshift/install/pull-secret
[openshift_versions]: http://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/
[rhcos_ami_ids]: https://docs.openshift.com/container-platform/latest/installing/installing_aws/installing-aws-user-infra.html#installation-aws-user-infra-rhcos-ami_installing-aws-user-infra

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

**Step 5: Create your DNS records (Public Zone and NS record)**

> If you are running in **AWS GovCloud**, you can't create a public
> zone because public zones are not supported yet. The automation will create a
> private zone for you. Proceed to the next step.

Log into the AWS console and create a public Route53 Hosted Zone for your
cluster.

The name **MUST** match the format `{{ cluster_name }}.{{ base_domain }}` using
the values you specified for those in your variable file. For example, if
`cluster_name` is `ocp4` and `base_domain` is `cloud.example.com`, then your
hosted zone should be `ocp4.cloud.example.com`.

After you create your hosted zone, you should see something similar to:

![](docs/images/route53_hosted_zone.png)

Copy the value for the `NS` record to your clipboard.

Go to your primary Route53 hosted zone for your domain (or subdomain), click
**Create Record Set** and add an `NS` record pointing to your new hosted zone.

![](docs/images/route53_add_ns_record.png)

After clicking **Create**, your primary Route53 hosted zone should look similar
to:

![](docs/images/route53_ns.png)

**Step 6: Run the Ansible playbook**

Execute the automation while passing in your variable file.

```bash
ansible-playbook -e @vars/ocp4.yml playbooks/create_cluster.yml -v
```

#### Destroy

Once you no longer need your cluster, you can use the automation to destroy
your cluster.

Be sure to execute the automation from the same machine where you created the
cluster as there is Terraform state data that is required to clean up all of
the resources previously created.

**Step 1: Enter the container environment**

Change your current directory to the cloned repository.

```bash
cd openshift4-deploy/
```

Activate a shell inside the container image provided.

```bash
./openshift-deploy shell
```

**Step 6: Run the Ansible playbook**

Execute the automation while passing in your variable file.


```bash
ansible-playbook -e @vars/ocp4.yml playbooks/destroy_cluster.yml -v
```
