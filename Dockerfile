FROM ubuntu:21.04

RUN apt-get update -y && \
    apt-get install tmate \
    apt-transport-https ca-certificates curl gnupg2 git python -y

RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

RUN apt-get update -y && \
    apt-get install -y kubectl

COPY . /root/

WORKDIR /root/
