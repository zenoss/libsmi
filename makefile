#
# Makefile for building the libsmi 0.5.0 dependency
#

PWD         := $(shell pwd)
UID         := $(shell id -u)
GID         := $(shell id -g)

BUILD_IMAGE := zenoss/build-libsmi

.PHONY: rpm deb clean

rpm: Dockerfile-rpm
	docker build --pull -f $< -t $(BUILD_IMAGE)-rpm .
	docker run --rm -v $${PWD}:/mnt -w /mnt $(BUILD_IMAGE)-rpm make -f build.mk rpm

deb: Dockerfile-deb
	docker build --pull -f $< -t $(BUILD_IMAGE)-deb .
	docker run --rm -v $${PWD}:/mnt -w /mnt $(BUILD_IMAGE)-deb make -f build.mk deb

clean:
	rm -f Dockerfile-rpm Dockerfile-deb
	make -f build.mk clean

Dockerfile-rpm: Dockerfile-rpm.in
	@sed -e "s/%UID%/$(UID)/g" -e "s/%GID%/$(GID)/g" $< > $@

Dockerfile-deb: Dockerfile-deb.in
	@sed -e "s/%UID%/$(UID)/g" -e "s/%GID%/$(GID)/g" $< > $@
