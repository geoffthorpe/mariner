include mariner_v2.mk
DEFAULT_SHELL := /bin/bash
TRACEFILE := $(DEFAULT_CRUD)/TRACE.unique
$(eval $(call do_mariner_prep))

# Load the features we'll need
features_path := $(strip $(TOPDIR)/features)
features_list := $(strip \
	debian/apt_is_usable \
	debian/embed_me \
	mount/x11_socket \
	mount/docker_socket \
	sys/null_passwd \
	sys/nada \
	app/make)
include $(foreach i,$(features_list),$(features_path)/$i.mk)

# Special, construct a "terminator" image around upstream "debian:latest", and
# layer everything else around that (using _EXTENDS). This allows for a bunch
# of special handling to support proxying, changes to roots-of-trust (CA
# certificates), bootstrapping from behind-the-firewall images (rather than
# external dockerhub), etc.
$(eval $(call make_mariner_terminator,doobie,debian:latest))

# We'll build two images;
#
# - vmrootfs
#     This container image installs packages for systemd, linux kernel, etc,
#     and other initialization is done to make the filesystem viable as a
#     bootable root file-system.
#
# - try-qemu
#     This container image has Qemu and related tools installed, and it is set
#     to require "extra privs" when containers are created from this image to
#     run verbs. (Extra privs are currently necessary because loopback-mounting
#     is involved in creating disk images. There is no logical reason why that
#     should be necessary. In principle, file-system-aware tools could build
#     the disk image and filesystem without special privilege, in exactly the
#     same way that tar doesn't require special privilege to extract filesystem
#     contents from a tarball. The problem is difficulty, time, and probably my
#     deplorable ignorance in such matters. Loopback mounting gets me to the
#     finish line, and it takes privilege, so we allow it.)
#     This container provides two verbs;
#     - mkdiskimage
#         This runs as root within the spawned container, extracts a tarball
#         from the docker daemon for some user-specified choice of container
#         image (we'll use "vmrootfs"), and converts it into a bootable disk
#         image. The resulting artifacts are stored at a user-specified path,
#         which needs to be in a persistent mount to be of any use (otherwise
#         all the work vanishes when the verb completes and the container
#         exits). Those artifacts are root-owned as seen from within the
#         container, so they are read-only from the perspective of the user
#         account in the container.
#         (HINT/MOTIVATION: the root-owned, read-only disk image is like a
#         container image, it doesn't change even if you run containers using
#         it, derive other containers from it, etc.)
#     - launch
#         This runs as the user account (not root) within the spawned
#         container, and launches a Qemu VM using one of the root-owned
#         artifacts produced by mkdiskimage. The VM's need for a mutable
#         (read-write) filesystem is resolved by creating a user-owned CoW file
#         that overlays the read-only disk image, and boots Qemu using
#         that overlay. The CoW file is in the user's home account in the container,
#         so when the VM shuts down and Qemu exits, the container exits too and
#         the CoW file disappears like all other filesystem modifications made
#         during the lifetime of the container (that aren't inside persistent
#         mounts).
#
# HINT/MOTIVATION: consider, the container running the launch verb is 1:1 with
# the Qemu VM that it spins up, as it is with the CoW file created in that
# container. All those things represent a local, private, read-writable context
# that vanishes when "the job is done". Though underlying that, there was a
# persistent and immutable filesystem image that is like a bootable blue-print,
# serving as a repeatable template for spinning up per-job, mutable copies of
# itself to run short-lived VMs, that vanish thereafter. The comparison between
# a converted, bootable diskimage (static, read-only), and a running Qemu VM
# with a throwaway CoW layer (ephemeral, read-write) is spookily similar to the
# comparison between a container image and a container instance, in
# Docker-speak. This was my evil plan all along!
#
# If Mariner workflows can be built out of modular workflow components,
# themselves built out of images, verbs, and dependencies, _and if this can be
# done in a hierarchical way_, then certain components of that could be hosted
# in full-blown virtual machines rather than just containers within containers.
# I.e. having some VM turtles in the stack, rather than it being "docker
# turtles all the way down".
#
# Please also see the user-mode-linux example for a half-way alternative. Qemu
# is a full-blown machine emulator (and we're not even letting it use kvm, so
# it's virtualising full-throttle), whereas user-mode-linux is a
# syscall-intercepting user-space emulator. Docker is a step further, it
# doesn't even pretend to have an OS instance with its own drivers or system
# services. If one measures the time and resource consumption of launching,
# running a command, and shutting down, the order of magnitude delta going from
# Docker containers to UML-VMs is similar to the delta from UML-VMs to
# Qemu-VMs. (There's a similar observation to be made about how closely the
# system environment mimics a "normal, native, physical O/S" - it gets closer
# as you progress from Docker to UML to Qemu.)

# The following settings would ideally be placed further down "as they become
# relevant". However, because of how/when things get expanded, these variables
# need to be set before they get incorporated (e.g. into an ARGS_DOCKER_RUN
# attribute). Oh well, another item for the when-I-rewrite-all-this TODO list.
ARG_DOCKERIMAGE := vmrootfs
ARG_DISKIMAGE := tmp.diskimg
ARG_DISKSIZE := 1500M
ARG_DISKPATH := /hostdir
ARG_LOOPDEV := $(shell losetup --find)
#ARG_NOGRAPHIC := 1 # Let the caller choose to set or not set this.

# Common;
$(eval $(call make_feature_layer,d1,doobie,$(features_path),debian/apt_is_usable))
$(eval $(call make_feature_layer,d2,d1,$(features_path),app/make))

# Specific to vmrootfs
$(eval $(call make_feature_layer,v1,d2,$(features_path),sys/null_passwd))

IMAGES += vmrootfs
vmrootfs_EXTENDS := v1
vmrootfs_NOPATH := true
vmrootfs_DOCKERFILE := $(TOPDIR)/docker-ctx/vmrootfs.Dockerfile

# Specific to try-qemu
$(eval $(call make_feature_layer,q1,d2,$(features_path),mount/docker_socket))
$(eval $(call make_feature_layer,q2,q1,$(features_path),debian/embed_me))
$(if $(ARG_NOGRAPHIC),\
	$(eval $(call make_feature_layer,q3,q2,$(features_path),sys/nada))\
,\
	$(eval $(call make_feature_layer,q3,q2,$(features_path),mount/x11_socket))\
)

IMAGES += try-qemu
try-qemu_EXTENDS := q3
try-qemu_PATH := $(TOPDIR)/docker-ctx
try-qemu_DOCKERFILE := $(TOPDIR)/docker-ctx/try-qemu.Dockerfile
try-qemu_COMMANDS := shell
try-qemu_ARGS_DOCKER_RUN := --cap-add SYS_ADMIN --device=$(ARG_LOOPDEV) --privileged \
	--env=ARG_DOCKERIMAGE=$(ARG_DOCKERIMAGE) \
	--env=ARG_DISKIMAGE=$(ARG_DISKIMAGE) \
	--env=ARG_DISKSIZE=$(ARG_DISKSIZE) \
	--env=ARG_DISKPATH=$(ARG_DISKPATH) \
	--env=ARG_LOOPDEV=$(ARG_LOOPDEV) \
	--env=ARG_NOGRAPHIC=$(ARG_NOGRAPHIC) \
	$(q3_ARGS_DOCKER_RUN)

VOLUMES += hostdir
hostdir_MANAGED := false
hostdir_SOURCE := $(shell pwd)
hostdir_DEST := /hostdir
try-qemu_VOLUMES += hostdir

COMMANDS += mkdiskimage
try-qemu_COMMANDS += mkdiskimage
mkdiskimage_COMMAND := /mkdiskimage.sh

COMMANDS += launch
try-qemu_COMMANDS += launch
launch_COMMAND := su --whitelist-environment=ARG_DISKIMAGE,ARG_DISKPATH,ARG_NOGRAPHIC \
		--login $(shell whoami) /launch.sh

$(eval $(call do_mariner))
