include mariner_v2.mk

############
# DEFAULTS #

# We will always have /bin/bash, which is nicer than /bin/sh
DEFAULT_SHELL := /bin/bash

# Mariner defaults to expecting to find source/context (incl. Dockerfile) for
# container image "foo" in $(TOPDIR)/c_foo. Here we replace that with a default
# to look in ./examples/foo.
DEFAULT_IMAGE_PATH_MAP := example_path_map
define example_path_map
$(eval $(strip $1)_PATH := $(TOPDIR)/examples/$(strip $1))
endef

###########
# OBJECTS #

VOLUMES := \
	source_vde \
	source_uml \
	install
IMAGES := \
	basedev \
	vde \
	user-mode-linux
COMMANDS := \
	build \
	delete-install \
	delete-source

#####################
# VOLUME attributes #

# source_vde
source_vde_DESCRIPTION := contains a git clone of the VDE2 source-code

# source_uml
source_uml_DESCRIPTION := contains a git clone of linux-stable.git

# install
install_DESCRIPTION := where compiled VDE2/UML/[...] code gets installed

######################
# COMMAND attributes #

# build
build_DESCRIPTION := configure and build the source code
build_COMMAND := /bin/false  # Useless unless overriden

# delete-install
delete-install_DESCRIPTION := empty the installation volume
delete-install_COMMAND := rm -rf /install/*
delete-install_DNAME := uniqueInstallVolumeDeleter

# delete-source
delete-source_DESCRIPTION := empty the source volume
delete-source_COMMAND := /bin/false  # Useless unless overriden

####################
# IMAGE attributes #

# basedev
basedev_TERMINATES := debian:latest
basedev_DESCRIPTION := 'debian:latest' plus some common dev packages
basedev_VOLUMES := install
basedev_COMMANDS := \
	build \
	delete-install \
	delete-source

# vde (Virtual Distributed Ethernet)
vde_EXTENDS := basedev
vde_DESCRIPTION := 'basedev' tuned for VDE2
vde_VOLUMES := source_vde $(basedev_VOLUMES)
vde_UNCOMMANDS := delete-install  # Do this from 'basedev' only

# uml (user mode linux)
user-mode-linux_EXTENDS := basedev
user-mode-linux_DESCRIPTION := 'basedev' tuned for User-Mode Linux
user-mode-linux_VOLUMES := source_uml $(basedev_VOLUMES)
user-mode-linux_UNCOMMANDS := delete-install  # Do this from 'basedev' only

##########################
# IMAGE/COMMAND 2-tuples #

# "build" is inherited from basedev and MUST to be customized per-image
vde_build_COMMAND := /script.sh
vde_build_DESCRIPTION := Run my magic VDE2 build script in a 'vde' container
user-mode-linux_build_COMMAND := /script.sh
#user-mode-linux_build_DESCRIPTION := # The inherited description isn't bad...

# "delete-install" is only in 'basedev', nothing to tweak

# "delete-source" is like "build", we must override it
vde_delete-source_COMMAND := /delete-source.sh
user-mode-linux_delete-source_COMMAND := /delete-source.sh

############################
# A bunch of testing stuff #

IMAGES += testing-base timage1
MYTESTS := tcmd1 tcmd2 tcmd3
COMMANDS += $(MYTESTS)
testing-base_TERMINATES := debian:latest
testing-base_PATH_MAP := testing_path_map
define testing_path_map
	$(eval $(strip $1)_PATH := $(TOPDIR)/testing/$(strip $1))
endef
timage1_EXTENDS := testing-base
timage1_COMMANDS := tcmd1 tcmd2 tcmd3
tcmd1_PROFILES := batch
tcmd2_PROFILES := batch
tcmd3_PROFILES := batch
tcmd1_COMMAND := /bin/bash -c \
"echo OUT1 && sleep 1 && echo OUT1 && sleep 1 && echo OUT1 && sleep 1 && echo OUT1"
tcmd2_COMMAND := /bin/bash -c \
"echo OUT2 && sleep 1 && echo OUT2 && sleep 1 && echo OUT2 && sleep 1 && echo OUT2"
tcmd3_COMMAND := /bin/bash -c \
"echo OUT3 && sleep 1 && echo OUT3 && sleep 1 && echo OUT3 && sleep 1 && echo OUT3"

# This is where we can test parallel make. Everything has to be launched in
# batch mode, otherwise they compete for stdin.
all-tests: $(foreach i,$(MYTESTS),timage1_$i_batch)
	$(Q)echo "My tests went just fine, thanks"

#################
# Run "mariner" #

$(eval $(call do_mariner))

#######################
# Ad-hoc dependencies #

# Here, because the build of UML links against the installed VDE2 artifacts
# (which are installed in the same "install" volume that UML installs to), we
# make sure that vde_build is a dependency on user-mode-linux_build.
user-mode-linux_build: vde_build
