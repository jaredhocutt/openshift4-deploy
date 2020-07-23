FROM registry.access.redhat.com/ubi8/ubi:8.2

ENV PYCURL_SSL_LIBRARY=openssl

ENV LC_CTYPE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

LABEL \
    name="openshift4-deploy" \
    description="OpenShift 4 deployment tool" \
    maintainer="Jared Hocutt (@jaredhocutt)"

USER root

RUN \
    yum install -y \
        git \
        openssh-clients \
        python3 \
        python3-pip \
        unzip \
        vim \
        which \
    && yum clean all \
    && pip3 install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir pipenv==2018.11.26 \
    && echo 'export PS1="\n\[\e[34m\]\u\[\e[m\] at \[\e[32m\]\h\[\e[m\] in \[\e[33m\]\w\[\e[m\] \[\e[31m\]\n\\$\[\e[m\] "' >> /root/.bashrc

# Install AWS CLI
RUN \
    cd /tmp \
    && curl -O https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    && unzip awscli-exe-linux-x86_64.zip \
    && ./aws/install \
    && rm -f awscli-exe-linux-x86_64.zip \
    && rm -rf ./aws

# Install Python dependencies
WORKDIR /app
COPY Pipfile Pipfile.lock entrypoint.sh ./
RUN pipenv install --system --deploy

# Install OpenShift client
ARG OPENSHIFT_VERSION
RUN \
    cd /tmp \
    && if [[ ${OPENSHIFT_VERSION} =~ "nightly" ]] ; \
    then curl -O http://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/${OPENSHIFT_VERSION}/openshift-client-linux-${OPENSHIFT_VERSION}.tar.gz ; \
    else curl -O http://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OPENSHIFT_VERSION}/openshift-client-linux-${OPENSHIFT_VERSION}.tar.gz ; fi \
    && tar xvf openshift-client-linux-${OPENSHIFT_VERSION}.tar.gz oc kubectl \
    && mv oc /usr/local/bin \
    && mv kubectl /usr/local/bin \
    && chmod +x /usr/local/bin/oc \
    && chmod +x /usr/local/bin/kubectl \
    && rm -f openshift-client-linux-${OPENSHIFT_VERSION}.tar.gz

ENTRYPOINT ["/app/entrypoint.sh"]
