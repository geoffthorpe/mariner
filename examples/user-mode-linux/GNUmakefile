include mariner_v2.mk
DEFAULT_SHELL := /bin/bash
TRACEFILE := $(DEFAULT_CRUD)/TRACE.unique
$(eval $(call do_mariner_prep))

# Special, construct a "terminator" image around upstream "debian:latest", and
# layer everything else around that (using _EXTENDS). This allows for a bunch
# of special handling to support proxying, changes to roots-of-trust (CA
# certificates), bootstrapping from behind-the-firewall images (rather than
# external dockerhub), etc.
$(eval $(call make_mariner_terminator,debbie,debian:latest))


# Load the features we'll need
features_path := $(strip $(TOPDIR)/features)
features_list := $(strip \
	debian/apt_is_usable \
	debian/embed_me \
	debian/typical_devel \
	user/as_me \
	mount/docker_socket \
	app/make \
	app/vde \
	app/uml)
include $(foreach i,$(features_list),$(features_path)/$i.mk)

$(eval $(call make_feature_layer,step1,debbie,$(features_path),debian/apt_is_usable))
$(eval $(call make_feature_layer,step2,step1,$(features_path),debian/embed_me))
$(eval $(call make_feature_layer,step3,step2,$(features_path),user/as_me))
$(eval $(call make_feature_layer,step4,step3,$(features_path),mount/docker_socket))
$(eval $(call make_feature_layer,step5,step4,$(features_path),debian/typical_devel))
$(eval $(call make_feature_layer,vde,step5,$(features_path),app/vde))
$(eval $(call make_feature_layer,uml,step5,$(features_path),app/uml))

VOLUMES += mariner_home mariner_install
mariner_home_DEST := /home/$(shell whoami)
mariner_install_DEST := /install

vde_VOLUMES += mariner_home mariner_install
uml_VOLUMES += mariner_home mariner_install

# The UML build depends on the VDE build (i.e. VDE artifacts are installed to
# the mariner_install volume). However, the "make_feature_layer" stuff can't
# know what we've decided to call our VDE-producing container image, and in
# fact we might be relying on it being external to this context. In short, we
# need to specify the dependency ourselves, which is a simple matter;
# "uml_build" depends on "vde_build".
uml_build: vde_build

IMAGES += rootfs
rootfs_EXTENDS := step3
rootfs_NOPATH := true
rootfs_DOCKERFILE := rootfs.Dockerfile

$(eval $(call do_mariner))

$(TOPDIR)/uml-rootfs-tarball.tar: rootfs_create
	CID=$$(docker run -d rootfs /bin/true) && \
	    docker export -o $(TOPDIR)/uml-rootfs-tarball.tar $${CID} && \
	    docker container rm $${CID}

$(TOPDIR)/uml-touch-bigzero:
	dd if=/dev/zero of=$(TOPDIR)/uml-rootfs.ext4 bs=1G count=1
	touch $(TOPDIR)/uml-touch-bigzero

$(TOPDIR)/uml-touch-mkfs: $(TOPDIR)/uml-touch-bigzero
	mkfs.ext4 $(TOPDIR)/uml-rootfs.ext4
	touch $(TOPDIR)/uml-touch-mkfs

$(TOPDIR)/uml-touch-done: $(TOPDIR)/uml-rootfs-tarball.tar $(TOPDIR)/uml-touch-mkfs
	mkdir -p $(TOPDIR)/uml-tmp-mount
	sudo mount -t auto $(TOPDIR)/uml-rootfs.ext4 $(TOPDIR)/uml-tmp-mount
	sudo rm -rf $(TOPDIR)/uml-tmp-mount/*
	sudo tar -xf $(TOPDIR)/uml-rootfs-tarball.tar -C $(TOPDIR)/uml-tmp-mount/
	sudo umount $(TOPDIR)/uml-tmp-mount
	rm -f uml-cow.cow
	touch $(TOPDIR)/uml-touch-done

run_uml: uml_build $(TOPDIR)/uml-touch-done
	$(TOPDIR)/vol_mariner_install/bin/linux \
		ubd0=uml-cow.cow,$(TOPDIR)/uml-rootfs.ext4 root=/dev/ubda
