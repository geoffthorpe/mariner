include mariner_v2.mk
DEFAULT_SHELL := /bin/bash
TRACEFILE := $(DEFAULT_CRUD)/TRACE.unique
$(eval $(call do_mariner_prep))

# Special, construct a "terminator" image around upstream "debian:latest", and
# layer everything else around that (using _EXTENDS). This allows for a bunch
# of special handling to support proxying, changes to roots-of-trust (CA
# certificates), bootstrapping from behind-the-firewall images (rather than
# external dockerhub), etc.
$(eval $(call make_mariner_terminator,doobie,debian:latest))


# Load the features we'll need
features_path := $(strip $(TOPDIR)/features)
features_list := $(strip \
	debian/apt_is_usable \
	debian/embed_me \
	debian/typical_devel \
	mount/docker_socket \
	app/make \
	app/vde \
	app/uml)
include $(foreach i,$(features_list),$(features_path)/$i.mk)

$(eval $(call make_feature_layer,step1,doobie,$(features_path),debian/apt_is_usable))
$(eval $(call make_feature_layer,step2,step1,$(features_path),debian/embed_me))
$(eval $(call make_feature_layer,step3,step2,$(features_path),mount/docker_socket))
$(eval $(call make_feature_layer,step4,step3,$(features_path),debian/typical_devel))
$(eval $(call make_feature_layer,vde,step4,$(features_path),app/vde))
$(eval $(call make_feature_layer,uml,step4,$(features_path),app/uml))

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

# Now, produce a container image, "rootfs", that will serve as the root FS for
# a UML kernel (which will be launched from a "uml" container). The dockerfile
# will write out a /myinit.sh script that prints some junk to the console and
# then tries to halt the kernel by calling /myshutdown.
IMAGES += rootfs
rootfs_EXTENDS := step4
rootfs_PATH := $(TOPDIR)/ctx_rootfs
rootfs_DOCKERFILE := $(rootfs_PATH)/Dockerfile

# The rules to convert the "rootfs" docker container image into a full-blown
# ext4 filesystem (for UML) are executed host-side, not in any container. This
# is sad, but at least it isolates the present ugliness of needing sudo privs
# (in order to loopback-mount and manipulate file-system images). There's no
# technical reason this should be the case, we're just writing a file we own,
# but finding a way that avoids using "mount" was beyond my constraints of time
# and patience.
#
# Note, the first two dependencies ensure the "myshutdown" binary is built
# (uml_build), and copies it from the install volume into the context area for
# the "rootfs" image, so that its Dockerfile can inject it into the, well, root
# FS. As a consequence, we need the third rule, to make sure that dance has
# occurred and the myshutdown binary is in place before the "rootfs" Dockerfile
# is run. (And the fact I need to manually specify $(DEFAULT_CRUD)/touch_rootfs
# rather than something symbolic, like $(rootfs_TOUCHFILE), is because I'm a
# terrible programmer.  "This will be resolved during the rewrite".)

$(TOPDIR)/vol_mariner_install/bin/myshutdown: uml_build

$(rootfs_PATH)/myshutdown: $(TOPDIR)/vol_mariner_install/bin/myshutdown
	cp $(TOPDIR)/vol_mariner_install/bin/myshutdown $(rootfs_PATH)/myshutdown

$(DEFAULT_CRUD)/touch_rootfs: $(rootfs_PATH)/myshutdown

$(TOPDIR)/vol_mariner_install/uml-rootfs-tarball.tar: $(DEFAULT_CRUD)/touch_rootfs
	CID=$$(docker run -d rootfs /bin/true) && \
	    docker export -o $(TOPDIR)/vol_mariner_install/uml-rootfs-tarball.tar $${CID} && \
	    docker container rm $${CID}

$(TOPDIR)/vol_mariner_install/uml-rootfs.ext4:
	dd if=/dev/zero of=$(TOPDIR)/vol_mariner_install/uml-rootfs.ext4 bs=1G count=1

$(TOPDIR)/vol_mariner_install/uml-touch-mkfs: $(TOPDIR)/vol_mariner_install/uml-rootfs.ext4
	/sbin/mkfs.ext4 -F $(TOPDIR)/vol_mariner_install/uml-rootfs.ext4
	touch $(TOPDIR)/vol_mariner_install/uml-touch-mkfs

$(TOPDIR)/vol_mariner_install/uml-touch-done: $(TOPDIR)/vol_mariner_install/uml-rootfs-tarball.tar $(TOPDIR)/vol_mariner_install/uml-touch-mkfs
	mkdir -p $(TOPDIR)/vol_mariner_install/uml-tmp-mount
	sudo mount -t auto $(TOPDIR)/vol_mariner_install/uml-rootfs.ext4 $(TOPDIR)/vol_mariner_install/uml-tmp-mount
	sudo rm -rf $(TOPDIR)/vol_mariner_install/uml-tmp-mount/*
	sudo tar -xf $(TOPDIR)/vol_mariner_install/uml-rootfs-tarball.tar -C $(TOPDIR)/vol_mariner_install/uml-tmp-mount/
	sudo umount $(TOPDIR)/vol_mariner_install/uml-tmp-mount
	rm -f $(TOPDIR)/vol_mariner_install/uml-cow.cow
	touch $(TOPDIR)/vol_mariner_install/uml-touch-done

# Add a command to the UML image to launch the UML kernel using the
# "rootfs"-originated, well, root FS.

COMMANDS += runuml
uml_COMMANDS += runuml
runuml_COMMAND := /install/bin/linux quiet \
		ubd0=/install/uml-cow.cow,/install/uml-rootfs.ext4 root=/dev/ubda \
		init=/myinit.sh

# Make sure the runuml command (for the uml container) is dependent on our
# manual, host-side rules.
uml_runuml: $(TOPDIR)/vol_mariner_install/uml-touch-done

$(eval $(call do_mariner))
