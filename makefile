#
# Makefile for building the libsmi 0.5.0 RPM dependency
#

PWD         := $(shell pwd)
UID         := $(shell id -u)
GID         := $(shell id -g)

NAME        := libsmi
VERSION     := 0.5.0
ARCH        := x86_64
RELEASE     := 1.el7
CATEGORY    := System Environment/Libraries
SUMMARY     := A library to access SMI MIB information
URL         := http://ww.ibr.cs.tu-bs.de/projects/libsmi/index.html
LICENSE     := BSD
PACKAGER    := Zenoss, Inc. <http://zenoss.com>
DESCRIPTION := Libsmi is a library and set of tools for checking, dumping, and converting MIB definitions.

PKG_NAME    := $(NAME)-$(VERSION)
BUILD_DIR   := $(PWD)/build
PKG_DIR     := $(PWD)/pkg
USR_DIR     := $(PKG_DIR)/usr
BIN_DIR     := $(USR_DIR)/bin
LIB_DIR     := $(USR_DIR)/lib64
DOC_DIR     := $(USR_DIR)/share/doc/$(PKG_NAME)
ETC_DIR     := $(PKG_DIR)/etc

SOURCE      := $(PKG_NAME).tar.gz
SOURCE_DIR  := $(BUILD_DIR)/$(PKG_NAME)

RPM         := $(NAME)-$(VERSION)-$(RELEASE).$(ARCH).rpm

BUILD_TOOLS_VERSION = 0.0.11  # Version of zenoss/build-tools image.
BUILD_IMAGE         = zenoss/build-libsmi

DOCS = $(DOC_DIR)/ANNOUNCE \
	   $(DOC_DIR)/ChangeLog \
	   $(DOC_DIR)/COPYING \
	   $(DOC_DIR)/draft-irtf-nmrg-sming-02.txt \
	   $(DOC_DIR)/draft-irtf-nmrg-smi-xml-00.txt \
	   $(DOC_DIR)/draft-irtf-nmrg-smi-xml-01.txt \
	   $(DOC_DIR)/ibrpib-assignments.txt \
	   $(DOC_DIR)/IETF-MIB-LICENSE.txt \
	   $(DOC_DIR)/README \
	   $(DOC_DIR)/smi.conf-example \
	   $(DOC_DIR)/THANKS \
	   $(DOC_DIR)/TODO

INCLUDE_PATHS = usr/bin \
				usr/lib64 \
				usr/share/man/man1 \
				usr/share/mibs \
				usr/share/pibs \
				usr/share/yang \
				usr/share/doc/$(PKG_NAME) \
				etc

.PHONY: build clean

build: Dockerfile
	docker build -t $(BUILD_IMAGE) .
	docker run --rm -v $${PWD}:/mnt -w /mnt $(BUILD_IMAGE) make $(RPM)

clean:
	rm -f Dockerfile $(RPM)
	rm -rf $(BUILD_DIR) $(PKG_DIR)
	-docker rmi -f $(BUILD_IMAGE) 2>/dev/null

Dockerfile: Dockerfile.in
	@sed \
		-e "s/%UID%/$(UID)/g" \
		-e "s/%GID%/$(GID)/g" \
		-e "s/%BUILD_TOOLS_VERSION%/$(BUILD_TOOLS_VERSION)/g" \
		$< > $@

$(BUILD_DIR) $(PKG_DIR) $(ETC_DIR) $(DOC_DIR):
	mkdir -p $@

$(BUILD_DIR)/$(SOURCE): $(BUILD_DIR)
	cd $< && curl -O http://zenpip.zenoss.eng/packages/$(notdir $@)

$(SOURCE_DIR): $(BUILD_DIR)/$(SOURCE)
	cd $(BUILD_DIR) && tar xf $(SOURCE)

$(SOURCE_DIR)/Makefile: $(SOURCE_DIR)
	cd $< && ./configure --disable-static --prefix=/usr --libdir=/usr/lib64

$(SOURCE_DIR)/tools/.libs/smidump: $(SOURCE_DIR)/Makefile
	make -C $(SOURCE_DIR)

$(BIN_DIR)/smidump: $(SOURCE_DIR)/tools/.libs/smidump
	make -C $(SOURCE_DIR) install DESTDIR=$(PKG_DIR)

$(ETC_DIR)/smi.conf: $(ETC_DIR)
	cp $(notdir $@) $<

$(DOCS): $(DOC_DIR)
	cp -fu `find ./ -path ./pkg -prune -o -name $(notdir $@) -print` $(DOC_DIR)

$(RPM): $(BIN_DIR)/smidump $(ETC_DIR)/smi.conf $(DOCS)
	fpm \
		--verbose \
		-t rpm \
		-s dir \
		-C $(PKG_DIR) \
		-n $(NAME) \
		-v $(VERSION) \
		--iteration $(RELEASE) \
		-m '$(PACKAGER)' \
		-p ./ \
		-x \*pkgconfig\* \
		-x \*libsmi.la \
		--category '$(CATEGORY)' \
		--description '$(DESCRIPTION)' \
		--license '$(LICENSE)' \
		--vendor '$(VENDOR)' \
		--url '$(URL)' \
		--provides $(NAME) \
		--rpm-summary '$(SUMMARY)' \
		--rpm-user root \
		--rpm-group root \
		$(INCLUDE_PATHS)
