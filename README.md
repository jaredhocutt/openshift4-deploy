# OpenShift 4 Deploy

This repository contains a set of tools and automation for deploying OpenShift
4 in various environments.

It is primarily focused on depolyments in situations that would require using
the User-Provisioned Infrastructure (UPI) method to perform the installation.
This includes environments where you are unable to provide administrator access
to the installer, are deploying in an air-gapped environment, do not wish to
have OpenShift 4 integreate with the cloud provider APIs, etc.

> If you are deploying in an environment where there already exists an
> Installer-Provisioned Infrastructure (IPI) method of installation and your
> security posture allows for the use of it, we highly recommend using that
> method of installation.
>
> https://docs.openshift.com/container-platform/latest/welcome/index.html

## Platforms

Deploy OpenShift 4 on the following platforms:

- **Amazon Web Services (AWS)**
  - [Generic Installation (no cloud provider integration)][1]
- **Amazon Web Services GovCloud (AWS GovCloud)**
  - [Generic Installation (no cloud provider integration)][2]

For documentation on how to use this repository for a given platform, click the
links for the platform you want to use above.

## Earlier Version

If you used an earlier version of this repository and have a cluster deployed
that used Terraform to create the infrastructure, a tag was created named
`terraform` that points to the last commit that contains the Terraform
artifacts. You will need to use this branch to destroy any clusters you have
deployed that used Terraform. This branch will not be updated with any new
code, but will be kept around to ensure that existing clusters can easily be
destroyed if there were created with an earlier version of this repository.


[1]: docs/install/aws_generic.md
[2]: docs/install/aws_govcloud_generic.md
