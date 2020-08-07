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

> **NOTE:** The options listed below that indicate a **Generic Installation**
> will deploy a cluster that does not have cloud provider integration. The
> underlying cloud platform will be treated as generic compute from the
> viewpoint of the OpenShift cluster. More specifically, the "bare metal"
> method of installation is used for these options.

- **Amazon Web Services (AWS)**
  - [Generic Installation][aws_generic]
- **Amazon Web Services GovCloud (AWS GovCloud)**
  - [Generic Installation][aws_govcloud_generic]
  - [Generic Installation - Air-gapped][aws_govcloud_generic_airgapped]

For documentation on how to use this repository for a given platform, click the
links for the platform you want to use above.


[aws_generic]: docs/install/aws_generic.md
[aws_govcloud_generic]: docs/install/aws_govcloud_generic.md
[aws_govcloud_generic_airgapped]: docs/install/aws_govcloud_generic_airgapped.md
