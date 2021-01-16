#!/bin/sh

sudo su -c 'echo http://dl-cdn.alpinelinux.org/alpine/edge/main/ >> /etc/apk/repositories'
sudo su -c 'echo http://dl-cdn.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories'
sudo su -c 'echo @hyperspike https://alpine.hyperspike.io/ >> /etc/apk/repositories'
sudo su -c 'wget https://alpine.hyperspike.io/alpine-devel@danmolik.com.rsa.pub -P /etc/apk/keys'
sudo modprobe overlay
sudo modprobe ext4
sudo modprobe ip_tables
sudo apk update
sudo apk del linux-virt
sudo apk --no-cache add linux-hyperspike@hyperspike
sudo apk --no-cache add util-linux conmon@hyperspike
sudo apk --no-cache add socat ethtool ipvsadm iproute2 iptables ebtables coreutils findutils
sudo apk --no-cache upgrade

sudo apk --no-cache add kubectl@hyperspike hyperctl@hyperspike kubeadm@hyperspike kubelet@hyperspike cri-o@hyperspike crun@hyperspike crictl@hyperspike ca-certificates ipset conntrack-tools openssl jq
sudo rm -rf /var/cache/apk/*
#sudo mount -t tmpfs cgroup_root /sys/fs/cgroup
#for d in cpuset memory cpu cpuacct blkio devices freezer net_cls perf_event net_prio hugetlb pids; do
#	sudo mkdir /sys/fs/cgroup/$d
#	sudo mount -t cgroup $d -o $d /sys/fs/cgroup/$d
#done
# sudo sed -i -e 's/^#\?\(rc_controller_cgroups=\).*/\1"YES"/' /etc/rc.conf
sudo sed -i -e 's/^#\?\(rc_logger\)\=.*/\1\="YES"/' /etc/rc.conf
sudo sed -i -e 's/^#\?\(rc_parallel\)\=.*/\1\="YES"/' /etc/rc.conf
sudo rc-update add cgroups sysinit
sudo rc-service cgroups start
sudo su -c 'echo "bpffs       /sys/fs/bpf    bpf      defaults,shared     0 0" >> /etc/fstab'
# sudo su -c 'echo "  ip link set dev eth0 mtu 9001" >> /etc/network/interfaces'
sudo su -c 'echo br_netfilter >> /etc/modules'
sudo su -c 'echo -e "NAME=Hyperspike\nID=hyperspike\nPRETTY_NAME=\"Hyperspike/Linux\"\nANSI_COLOR=\"0;35\"\nHOME_URL=\"https://hyperspike.io\"\nSUPPORT_URL=\"https://www.hyperspike.io/support\"\nBUG_REPORT_URL=\"https://bugs.hyperspike.io/\"" > /etc/os-release'
sudo su -c 'echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.ip_local_port_range=1024 65000" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.tcp_tw_reuse=1" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.tcp_fin_timeout=15" >> /etc/sysctl.conf'
sudo su -c 'echo "net.core.somaxconn=4096" >> /etc/sysctl.conf'
sudo su -c 'echo "net.core.netdev_max_backlog=4096" >> /etc/sysctl.conf'
sudo su -c 'echo "net.core.rmem_max=16777216" >> /etc/sysctl.conf'
sudo su -c 'echo "net.core.wmem_max=16777216" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.tcp_max_syn_backlog=20480" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.tcp_max_tw_buckets=400000" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.tcp_no_metrics_save=1" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.tcp_rmem=4096 87380 16777216" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.tcp_syn_retries=2" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.tcp_synack_retries=2" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.tcp_wmem=4096 65536 16777216" >> /etc/sysctl.conf'
sudo su -c 'echo "#vm.min_free_kbytes=65536" >> /etc/sysctl.conf'
sudo su -c 'echo "net.netfilter.nf_conntrack_max=262144" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.netfilter.ip_conntrack_generic_timeout=120" >> /etc/sysctl.conf'
sudo su -c 'echo "net.netfilter.nf_conntrack_tcp_timeout_established=86400" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.neigh.default.gc_thresh1=8096" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.neigh.default.gc_thresh2=12288" >> /etc/sysctl.conf'
sudo su -c 'echo "net.ipv4.neigh.default.gc_thresh3=16384" >> /etc/sysctl.conf'

sudo su -c 'echo -e "ipost-up ip link set dev eth0 mtu 9000" >> /etc/network/interfaces'

sudo sed -i -e 's/\(ip\ -[46]\ route\ add\ default.*\)/#\1/'/etc/udhcpc/post-bound/eth-eni-hook 
grep default /etc/udhcpc/post-bound/eth-eni-hook
sudo mkdir -p /etc/cni/net.d
sudo mkdir -p /opt/cni/bin
sudo su -c 'echo "runtime-endpoint: unix:///run/crio/crio.sock" >> /etc/crictl.yaml'
sudo cp /tmp/crio.conf /etc/crio/crio.conf
sudo mkdir /etc/containers
sudo cp /tmp/policy.json /etc/containers
sudo rm -rfv /tmp/*
sudo rm -rfv /var/tmp/*
sudo rc-service crio start
sudo rc-update add crio default
sleep 5
sudo rc-service crio restart
sudo kubeadm config images pull --cri-socket /run/crio/crio.sock
sudo cat /var/log/crio/crio.log
sudo crictl pull docker.io/cilium/cilium:v${CILIUM_VERSION}
# sudo crictl -i /run/containerd/containerd.sock pull gcr.io/google-containers/startup-script:v1

# sudo rc-update add kubelet default
#df -h
#sudo su -c 'find / -maxdepth 1 -mindepth 1 -type d | xargs du -sh'
#sudo su -c 'find /usr -maxdepth 1 -mindepth 1 -type d | xargs du -sh'
#sudo su -c 'find /usr/bin -maxdepth 1 -mindepth 1 -type d | xargs du -sh'

sudo rm /var/lib/cloud/.bootstrap-complete
