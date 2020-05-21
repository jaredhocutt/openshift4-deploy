FROM docker.io/library/fedora:32

ENV TERRAFORM_VERSION=0.12.24
ENV PYCURL_SSL_LIBRARY=openssl

LABEL \
    name="openshift4-deploy" \
    description="OpenShift 4 deployment tool that uses the bare metal method of installation" \
    maintainer="Jared Hocutt (@jaredhocutt)"

USER root

RUN \
    dnf install -y \
        git \
        openssh-clients \
        python3 \
        python3-pip \
        unzip \
        vim \
        which \
    && dnf clean all \
    && pip3 install --upgrade pip \
    && pip3 install pipenv \
    && echo 'export PS1="\[\e[34m\]\u\[\e[m\] at \[\e[32m\]\h\[\e[m\] in \[\e[33m\]\w\[\e[m\] \[\e[31m\]\n\\$\[\e[m\] "' >> /root/.bashrc

WORKDIR /tmp

RUN \
    curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin \
    && rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip

WORKDIR /app

COPY Pipfile Pipfile.lock entrypoint.sh ./

RUN pipenv install --system --deploy

ENTRYPOINT ["/app/entrypoint.sh"]
