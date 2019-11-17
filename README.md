# Alpine Container Packages Repo

This repo is here to facilitate the creation of Kubernetes Nodes built on Alpine. You'll find the Kubernetes node binaries (kubelet, kubeadm, and kubectl) along with a container stack (crun, cri-o).

If you don't want to host the packages yourself you can use my repo at `https://danmolik.com/alpine`. If you do choose this route I recommend you trust the signing key, and add it to /etc/apk/repositories.

    wget https://danmolik.com/alpine/alpine-devel@danmolik.com.rsa.pub -P /etc/apk/keys
    echo https://danmolik.com/alpine/ >> /etc/apk/repositories
