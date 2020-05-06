#!/usr/bin/env bash
type -p unzip  >/dev/null || bash -c 'echo "Please install unzip" && exit 1'
type -p pipenv >/dev/null || bash -c 'echo "Please install pipenv" && exit 1'

PARENT_DIR="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
mkdir -p ${PARENT_DIR}/bin
export PATH=$PATH:${PARENT_DIR}/bin
cd ${PARENT_DIR}/bin

echo "Download and configuring dependencies..."
echo "Downloading Terraform"
curl -O https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
unzip -u terraform_0.12.24_linux_amd64.zip
rm -f terraform_0.12.24_linux_amd64.zip
cd -

echo
echo "Installing Python environment (pipenv)"
echo
pipenv install

echo
echo
echo
echo "The required dependencies have been installed!"
echo "##########################################################################"
echo
echo "Keep your PATH environment variable up to date to use them:"
echo "export PATH=\$PATH:${PARENT_DIR}/bin"
echo "New/current PATH is \"${PATH}\""
echo
echo
echo "Now is the time to export your AWS profile/region. For example..."
echo "export AWS_PROFILE=default"
echo "export AWS_REGION=us-east-1"
echo
echo "Or you can export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY. Like this:"
echo "export AWS_ACCESS_KEY_ID=AKIA.............XYZ"
echo "export AWS_SECRET_ACCESS_KEY='+akraJ/x.............................XYZ'"
echo
echo "Current AWS_ environment variables are:"
printenv | grep -e 'AWS_' | sort
echo "##########################################################################"
echo

echo "Entering pipenv shell..."
pipenv shell
