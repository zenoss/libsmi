NAME        := libsmi
VERSION     := 0.5.0
RELEASE     := 1
CATEGORY    := System Environment/Libraries
SUMMARY     := A library to access SMI MIB information
URL         := https://www.ibr.cs.tu-bs.de/projects/libsmi/index.html
LICENSE     := BSD
PACKAGER    := Zenoss, Inc. <http://zenoss.com>
DESCRIPTION := Libsmi is a library and set of tools for checking, dumping, and converting MIB definitions.

PKG_NAME    := $(NAME)-$(VERSION)
PWD         := $(shell pwd)
BUILD_DIR   := $(PWD)/build
PKG_DIR     := $(PWD)/pkg
USR_DIR     := $(PKG_DIR)/usr
BIN_DIR     := $(USR_DIR)/bin
LIB_DIR     := $(USR_DIR)/lib64
DOC_DIR     := $(USR_DIR)/share/doc/$(PKG_NAME)
ETC_DIR     := $(PKG_DIR)/etc

SOURCE      := $(PKG_NAME).tar.gz
SOURCE_DIR  := $(BUILD_DIR)/$(PKG_NAME)

RPM         := $(NAME)-$(VERSION)-$(RELEASE).x86_64.rpm
DEB         := $(NAME)_$(VERISON)-$(RELEASE)_amd64.deb

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

.PHONY: rpm deb

rpm: $(RPM)

deb: $(DEB)

clean:
	rm -f $(RPM) $(DEB)
	rm -rf $(BUILD_DIR) $(PKG_DIR)

$(BUILD_DIR) $(PKG_DIR) $(ETC_DIR) $(DOC_DIR):
	mkdir -p $@

$(BUILD_DIR)/$(SOURCE): $(BUILD_DIR)
	cd $< && wget --no-verbose --output-document $@ http://zenpip.zenoss.eng/packages/$(notdir $@)

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

$(DEB): $(BIN_DIR)/smidump $(ETC_DIR)/smi.conf $(DOCS)
	fpm \
		--verbose \
		-t deb \
		-s dir \
		-C $(PKG_DIR) \
		-n $(NAME) \
		-v $(VERSION) \
		--iteration $(RELEASE) \
		-m '$(PACKAGER)' \
		-p ./ \
		-x \*pkgconfig\* \
		-x \*libsmi.la \
		--category 'misc' \
		--description '$(DESCRIPTION)' \
		--license '$(LICENSE)' \
		--vendor '$(VENDOR)' \
		--url '$(URL)' \
		--provides $(NAME) \
		--deb-user root \
		--deb-group root \
		$(INCLUDE_PATHS)
