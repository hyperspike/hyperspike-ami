
K8S_VERSION=$(shell cat VERSIONS|grep KUBERNETES|sed -e 's/KUBERNETES[\ \t]*=[\ \t]*//' )
CONMON_VERSION=$(shell cat VERSIONS|grep CONMON|sed -e 's/CONMON[\ \t]*=[\ \t]*//' )
CRIO_VERSION=$(shell cat VERSIONS|grep CRIO|sed -e 's/CRIO[\ \t]*=[\ \t]*//' )
CRUN_VERSION=$(shell cat VERSIONS|grep CRUN|sed -e 's/CRUN[\ \t]*=[\ \t]*//' )

all: Dockerfile pkg/%/APKBUILD
	@if [ -d repo ] ; then \
		docker build --build-arg signing_key=$(cat repo/*.rsa) --build-arg signing_pub=$(cat repo/*.rsa.pub) -t dan/alpine-repo:latest . ; \
	else \
		docker build -t dan/alpine-repo:latest . ; \
	fi
	docker ps -a |grep /repo/ && docker rm $$(docker ps -a | awk '$$NF ~ /repo/ {print $$1}') || true
	docker create --name repo dan/alpine-repo
	rm -rf ./repo
	docker cp repo:/root/packages/pkg ./repo

version:
	@echo "Kubernetes: ${K8S_VERSION}"
	@echo "Crun:       ${CRUN_VERSION}"
	@echo "Conmon:     ${CONMON_VERSION}"
	@echo "Cri-o:      ${CRIO_VERSION}"

Dockerfile: Dockerfile.in
	sed -e "s/@CRIO_VERSION@/$(CRIO_VERSION)/g" \
		-e "s/@K8S_VERSION@/$(K8S_VERSION)/g" \
		-e "s/@CRUN_VERSION@/$(CRUN_VERSION)/g" \
		-e "s/@CONMON_VERSION@/$(CONMON_VERSION)/g" \
			$^ > $@

pkg/%/APKBUILD: pkg/%/APKBUILD.in
	sed -e "s/@CRIO_VERSION@/$(CRIO_VERSION)/g" \
		-e "s/@K8S_VERSION@/$(K8S_VERSION)/g" \
		-e "s/@CRUN_VERSION@/$(CRUN_VERSION)/g" \
		-e "s/@CONMON_VERSION@/$(CONMON_VERSION)/g" \
			$^ > $@
