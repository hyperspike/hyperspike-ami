
K8S_VERSION=$(shell cat VERSIONS|grep KUBERNETES|sed -e 's/KUBERNETES[\ \t]*=[\ \t]*//' )
CONMON_VERSION=$(shell cat VERSIONS|grep CONMON|sed -e 's/CONMON[\ \t]*=[\ \t]*//' )
CRIO_VERSION=$(shell cat VERSIONS|grep CRIO|sed -e 's/CRIO[\ \t]*=[\ \t]*//' )
CRUN_VERSION=$(shell cat VERSIONS|grep CRUN|sed -e 's/CRUN[\ \t]*=[\ \t]*//' )
CRICTL_VERSION=$(shell cat VERSIONS|grep CRICTL|sed -e 's/CRICTL[\ \t]*=[\ \t]*//' )
SIGNING_KEY="$(shell if [ -d repo ] ; then cat repo/*.rsa |base64 -w 0; fi)"
SIGNING_PUB="$(shell if [ -d repo ] ; then cat repo/*.rsa.pub|base64 -w 0 ; fi)"

default: all

.PHONY: clean real-clean


all: Dockerfile pkg/cri-o/APKBUILD pkg/kubelet/APKBUILD pkg/kubectl/APKBUILD pkg/kubeadm/APKBUILD pkg/crun/APKBUILD pkg/conmon/APKBUILD pkg/crictl/APKBUILD
	if [ -d repo ] ; then \
		echo "using existing keys" ; \
		docker build --build-arg SIGNING_KEY --build-arg SIGNING_PUB -t dan/alpine-repo:latest . ; \
	else \
		docker build -t dan/alpine-repo:latest . ; \
	fi
	docker ps -a |grep alpine-repo && docker rm $$(docker ps -a | awk '$$NF ~ /alpine-repo/ {print $$1}') || true
	docker create --name alpine-repo dan/alpine-repo
	rm -rf ./repo
	docker cp alpine-repo:/root/packages/pkg ./repo

version:
	@echo "Kubernetes: ${K8S_VERSION}"
	@echo "Crun:       ${CRUN_VERSION}"
	@echo "Conmon:     ${CONMON_VERSION}"
	@echo "Cri-o:      ${CRIO_VERSION}"
	@echo "Crictl:     ${CRICTL_VERSION}"

Dockerfile: Dockerfile.in
	sed -e "s/@CRIO_VERSION@/$(CRIO_VERSION)/g" \
		-e "s/@K8S_VERSION@/$(K8S_VERSION)/g" \
		-e "s/@CRUN_VERSION@/$(CRUN_VERSION)/g" \
		-e "s/@CRICTL_VERSION@/$(CRICTL_VERSION)/g" \
		-e "s/@CONMON_VERSION@/$(CONMON_VERSION)/g" \
			$^ > $@

pkg/%/APKBUILD: pkg/%/APKBUILD.in
	sed -e "s/@CRIO_VERSION@/$(CRIO_VERSION)/g" \
		-e "s/@K8S_VERSION@/$(K8S_VERSION)/g" \
		-e "s/@CRUN_VERSION@/$(CRUN_VERSION)/g" \
		-e "s/@CRICTL_VERSION@/$(CRICTL_VERSION)/g" \
		-e "s/@CONMON_VERSION@/$(CONMON_VERSION)/g" \
			$^ > $@


clean:
	rm -f pkg/*/APKBUILD Dockerfile

real-clean: clean
	rm -rf repo
