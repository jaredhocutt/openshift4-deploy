#!/usr/bin/env bash

PARENT_DIR="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" >/dev/null 2>&1 && pwd )"
KERNEL_NAME=$(uname -s)

function L() {
    local l=;

    builtin printf -vl "%${2:-${COLUMNS:-`tput cols 2>&-||echo 80`}}s\n" && echo -e "${l// /${1:-=}}";
}

mkdir -p ${PARENT_DIR}/bin

echo
echo "Dependencies will be downloaded to ${PARENT_DIR}/bin"
echo

cd ${PARENT_DIR}/bin

echo
echo "Downloading Terraform..."
echo

if [[ ${KERNEL_NAME} == "Linux" ]]; then
    curl -O https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
    unzip terraform_0.12.24_linux_amd64.zip
    rm -f terraform_0.12.24_linux_amd64.zip
elif [[ ${KERNEL_NAME} == "Darwin" ]]; then
    curl -O https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_darwin_amd64.zip
    unzip terraform_0.12.24_darwin_amd64.zip
    rm -f terraform_0.12.24_darwin_amd64.zip
else
    echo "Unable to determine if you're using Linux or MacOS. Exiting..."
    exit 1
fi

echo
echo
L '#'
echo "The required dependencies have been downloaded. Update your PATH to use them:"
echo
echo "export PATH=${PARENT_DIR}/bin:\$PATH"
echo
L '#'

