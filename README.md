# Hyperspike AMI Builder

[![Build Status](https://ci.hyperspike.io/api/badges/Hyperspike/ami/status.svg)](https://ci.hyperspike.io/Hyperspike/ami)

This repo is here to facilitate the creation of Hyperspike nodes. You'll find the Kubernetes node binaries (kubelet, kubeadm, and kubectl) along with a container stack (crun, cri-o, and crictl).

If you don't want to host the packages yourself you can use official repo at `https://alpine.hyperspike.io`. If you do choose this route I recommend you trust the signing key, and add it to /etc/apk/repositories.

    wget https://alpine.hyperspike.io/alpine-devel@danmolik.com.rsa.pub -P /etc/apk/keys
    echo https://alpine.hyperspike.io >> /etc/apk/repositories

AMIs are available in us-east 1 and 2. Simply search for hyperspike.

    us-east-1: ami-0c8d30fee3454bab0
    us-east-2: ami-004a4406fef940ebd
