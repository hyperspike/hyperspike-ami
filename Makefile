
K8S_VERSION=$(shell cat VERSIONS|grep KUBERNETES|sed -e 's/KUBERNETES[\ \t]*=[\ \t]*//' )
CONMON_VERSION=$(shell cat VERSIONS|grep CONMON|sed -e 's/CONMON[\ \t]*=[\ \t]*//' )
CRIO_VERSION=$(shell cat VERSIONS|grep CRIO|sed -e 's/CRIO[\ \t]*=[\ \t]*//' )
GO_VERSION=$(shell cat VERSIONS|grep GO|sed -e 's/GO[\ \t]*=[\ \t]*//' )
CRUN_VERSION=$(shell cat VERSIONS|grep CRUN|sed -e 's/CRUN[\ \t]*=[\ \t]*//' )
CRICTL_VERSION=$(shell cat VERSIONS|grep CRICTL|sed -e 's/CRICTL[\ \t]*=[\ \t]*//' )
LINUX_VERSION=$(shell cat VERSIONS|grep LINUX|sed -e 's/LINUX[\ \t]*=[\ \t]*//' )
ALPINE_VERSION=$(shell cat VERSIONS|grep ALPINE|sed -e 's/ALPINE[\ \t]*=[\ \t]*//' )
ALPINE_MINOR=$(shell cat VERSIONS|grep ALPINE|sed -e 's/ALPINE[\ \t]*=[\ \t]*//' -e 's/\.[0-9]\+$$//' )
HYPERSPIKE_VERSION=$(shell cat VERSIONS|grep HYPERSPIKE|sed -e 's/HYPERSPIKE[\ \t]*=[\ \t]*//' )
CILIUM_VERSION=$(shell cat VERSIONS|grep CILIUM|sed -e 's/CILIUM[\ \t]*=[\ \t]*//' )
SIGNING_KEY="$(shell if [ -d repo ] ; then cat repo/*.rsa |base64 -w 0; fi)"
SIGNING_PUB="$(shell if [ -d repo ] ; then cat repo/*.rsa.pub|base64 -w 0 ; fi)"
DISTRO=$(shell eval $$(cat /etc/os-release); echo $$ID )

default: all

.PHONY: clean real-clean

all: pkgs ami

pkgs: repo/pkg/x86_64/cri-o-$(CRIO_VERSION)-r0.apk repo/pkg/x86_64/kubernetes-$(K8S_VERSION)-r0.apk \
	repo/pkg/x86_64/conmon-$(CONMON_VERSION)-r0.apk repo/pkg/x86_64/linux-hyperspike-$(LINUX_VERSION)-r0.apk \
	repo/pkg/x86_64/crun-$(CRUN_VERSION)-r0.apk repo/pkg/x86_64/crictl-$(CRICTL_VERSION)-r0.apk \
	repo/pkg/x86_64/hyperctl-$(HYPERSPIKE_VERSION)-r0.apk

ami:
	aws ec2 describe-images --owner self   --filters 'Name=name,Values=hyperspike-*' | jq -Mr '.Images[] | .Name ' | grep -x hyperspike-$(HYPERSPIKE_VERSION) \
		|| HYPERSPIKE_VERSION=$(HYPERSPIKE_VERSION) \
		K8S_VERSION=$(K8S_VERSION) \
		ALPINE_VERSION=$(ALPINE_VERSION) \
		KERNEL_VERSION=$(LINUX_VERSION) \
		CILIUM_VERSION=$(CILIUM_VERSION) \
		packer build ami.json

version:
	@echo "Kubernetes: ${K8S_VERSION}"
	@echo "Crun:       ${CRUN_VERSION}"
	@echo "Conmon:     ${CONMON_VERSION}"
	@echo "Cri-o:      ${CRIO_VERSION}"
	@echo "Crictl:     ${CRICTL_VERSION}"
	@echo "Go:         ${GO_VERSION}"
	@echo "Linux:      ${LINUX_VERSION}"

pkg/%/APKBUILD: pkg/%/APKBUILD.in VERSIONS
	sed -e "s/@CRIO_VERSION@/$(CRIO_VERSION)/g" \
		-e "s/@GO_VERSION@/$(GO_VERSION)/g" \
		-e "s/@K8S_VERSION@/$(K8S_VERSION)/g" \
		-e "s/@CRUN_VERSION@/$(CRUN_VERSION)/g" \
		-e "s/@CRICTL_VERSION@/$(CRICTL_VERSION)/g" \
		-e "s/@HYPERSPIKE_VERSION@/$(HYPERSPIKE_VERSION)/g" \
		-e "s/@CONMON_VERSION@/$(CONMON_VERSION)/g" \
		-e "s/@LINUX_VERSION@/$(LINUX_VERSION)/g" \
			$< > $@

clean:
	rm -f pkg/*/APKBUILD Dockerfile

real-clean: clean
	rm -rf repo

.PHONY: utils apk-builder apk-fetcher apk-packer
utils: apk-builder apk-fetcher apk-packer

apk-builder:
	docker build -f utils/Dockerfile.apk-builder -t graytshirt/alpine-builder ./utils
apk-fetcher:
	docker build -f utils/Dockerfile.apk-fetcher -t graytshirt/alpine-fetcher ./utils
apk-packer:
	docker build -f utils/Dockerfile.packer      -t graytshirt/packer          ./utils

.PHONY: upload download
upload:
	@if [ "$(DISTRO)" = "alpine" ] ; then \
		mc cp --recursive repo/pkg/x86_64/ minio/alpine/x86_64/ ; \
	else \
		mc cp --recursive repo/x86_64/     minio/alpine/x86_64/ ; \
	fi
	@echo $(APK_KEY_PUB)|base64 -d > repo/alpine-devel@danmolik.com.rsa.pub
	@mc cp repo/*.pub          minio/alpine/
	@mc policy -r set download minio/alpine/

download:
	@if [ "$(DISTRO)" = "alpine" ] ; then \
		mc cp --recursive minio/alpine/x86_64/ repo/pkg/x86_64/ ; \
	else \
		mc cp --recursive minio/alpine/x86_64/ repo/x86_64/ ; \
	fi

.SECONDEXPANSION:
repo/pkg/x86_64/%-r0.apk: pkg/$$(shell echo $$*|sed -e 's/-[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\{0,1\}//')/APKBUILD
	@echo Building $(shell echo $(notdir $(@:-r0.apk='')) | sed -e 's/-[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\{0,1\}$$//')
	@if [ "$(DISTRO)" = "alpine" ] ; then \
		if [ -z $(APK_KEY) ] || [ -z $(APK_KEY_PUB) ] ; then \
			abuild-keygen -n \
			&& mv /root/.abuild/*.rsa /root/.abuild/alpine-devel@danmolik.com.rsa \
			&& mv /root/.abuild/*.rsa.pub /root/.abuild/alpine-devel@danmolik.com.rsa.pub \
			&& cp /root/.abuild/*.rsa* repo/ ; \
		else \
			mkdir -p /root/.abuild/ \
			&& echo $(APK_KEY)|base64 -d > /root/.abuild/alpine-devel@danmolik.com.rsa \
			&& echo $(APK_KEY_PUB)|base64 -d > /root/.abuild/alpine-devel@danmolik.com.rsa.pub ; \
		fi \
		&& echo "PACKAGER_PRIVKEY=\"/root/.abuild/alpine-devel@danmolik.com.rsa\"" > /root/.abuild/abuild.conf \
		&& cp /root/.abuild/alpine-devel@danmolik.com.rsa.pub /etc/apk/keys \
		&& cd $(shell echo $< | sed -e 's/\/APKBUILD//' ) \
		&& abuild -FRrk -P ${PWD}/repo fetch \
		&& abuild -FRrk -P ${PWD}/repo checksum \
		&& abuild -FRrk -P ${PWD}/repo \
		&& abuild -F -P ${PWD}/repo clean \
		&& abuild -FRrk -P ${PWD}/repo cleanoldpkg \
		&& cd ../../ \
		&& apk index -o repo/pkg/x86_64/APKINDEX.unsigned.tar.gz repo/pkg/x86_64/*.apk \
		&& cp repo/pkg/x86_64/APKINDEX.unsigned.tar.gz repo/pkg/x86_64/APKINDEX.tar.gz \
		&& abuild-sign -k /root/.abuild/*.rsa repo/pkg/x86_64/APKINDEX.tar.gz ; \
	else \
		docker run -it \
		-v $(PWD)/pkg/$(shell echo $(notdir $(@:-r0.apk='')) | sed -e 's/-[0-9]\+\.[0-9]\+\(\.[0-9]\+\)\{0,1\}$$//'):/build \
		-v $(PWD)/repo:/root/packages \
		graytshirt/alpine-builder \
		/bin/sh -c ' \
			if [ -f /root/packages/*.rsa ] && [ -f /root/packages/*.rsa.pub ] ; then \
				mkdir -p /root/.abuild \
				&& cp /root/packages/*.rsa /root/.abuild/alpine-devel@danmolik.com.rsa \
				&& cp /root/packages/*.rsa.pub /root/.abuild/alpine-devel@danmolik.com.rsa.pub ; \
			else \
				abuild-keygen -n \
				&& mv /root/.abuild/*.rsa /root/.abuild/alpine-devel@danmolik.com.rsa \
				&& mv /root/.abuild/*.rsa.pub /root/.abuild/alpine-devel@danmolik.com.rsa.pub ; \
			fi \
			&& echo "PACKAGER_PRIVKEY=\"/root/.abuild/alpine-devel@danmolik.com.rsa\"" > /root/.abuild/abuild.conf \
			&& cp /root/.abuild/alpine-devel@danmolik.com.rsa.pub /etc/apk/keys \
			&& cd /build \
			&& abuild -FRrk fetch \
			&& abuild -FRrk checksum \
			&& abuild -FRrk \
			&& abuild -F clean \
			&& abuild -FRrk cleanoldpkg \
			&& apk index -o /root/packages/x86_64/APKINDEX.unsigned.tar.gz /root/packages/x86_64/*.apk \
			&& cp /root/packages/x86_64/APKINDEX.unsigned.tar.gz /root/packages/x86_64/APKINDEX.tar.gz \
			&& abuild-sign -k /root/.abuild/*.rsa /root/packages/x86_64/APKINDEX.tar.gz \
			&& cp /root/.abuild/*.rsa* /root/packages/ ' ; \
	fi


