###############################
# Makefile for mariner/examples
#
# This makefile ties together a hodge-podge of environments for building
# things, installing things, building and linking things against other things
# that were already built and installed, and generally showing the workflow of
# using mariner to keep some kind of reproducible discipline while hacking on
# distinct codebases.
#
# We also try to generalize between two very different environments, which I've
# called "standard" and "corporate". The latter does various gymnastics to
# deal with things like;
# - having to use web proxies (requiring env-vars like http_proxy, etc),
# - those web proxies doing TLS MITM (requiring messing round with
#   ca-certificates),
# - native docker daemons that won't directly use proxies, requiring you to
#   bootstrap via an internal docker registry/mirror, etc.
# We do this to illustrate a contortion that Mariner can perform, namely we
# will have the Dockerfile and context for our basedev container automatically
# generated, by Makefile dependency, before Mariner builds the basedev image.
# If DO_CORPORATE is not defined, the "basedev" image is defined "as-is", per
# the context and Dockerfile in ./basedev/. Otherwise, it is mutated into a
# context and Dockerfile sitting in the ephemeral ("crud") path.

#DO_CORPORATE := 1

############
# DEFAULTS #

# We will always have /bin/bash, which is nicer than /bin/sh
DEFAULT_SHELL := /bin/bash

# Mariner defaults to expecting to find source/context (incl. Dockerfile) for
# container image "foo" in $(TOPDIR)/c_foo. Ours don't have the "c_" prefix,
# so change the mapping.
DEFAULT_IMAGE_PATH_MAP := example_path_map
define example_path_map
$(eval $(strip $1)_PATH := $(TOPDIR)/$(strip $1))
endef

include mariner_v2.mk

# If TRACE is set, we get a TRACE file in the crud directory each time "make"
# is run. The default is to generate a file based on date+time+PID, so they
# accumulate quickly. If you want each "make" run to reset and rewrite the same
# TRACE file, this will do it. Note, because I want this to be relative to the
# crud directory, which is set by inclusion of mariner_v2.mk, we define this
# after inclusion but before calling do_mariner_prep.
TRACEFILE := $(DEFAULT_CRUD)/TRACE.unique

$(eval $(call do_mariner_prep))

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
delete-install_COMMAND := bash -c "rm -rf /install/*"
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

#######################
# Ad-hoc dependencies #

# Because the build of UML links against the installed VDE2 artifacts (which
# are installed in the same "install" volume that UML installs to), we make
# sure that vde_build is a dependency on user-mode-linux_build. Note, these
# kind of dependencies are _NOT_ consumed by Mariner, they live entirely and
# natively in GNU make. They can be defined perfectly well after the call to
# do_mariner(), but I have put this here to illustrate that it is part of the
# use-case, but thought it worthwhile explaining that Mariner generates make
# rules _PRECISELY_ so you can leverage them directly. (Mariner is a good
# citizen of gmake, not an all-consuming wrapper of it.)
user-mode-linux_build: vde_build

#################
# Customization #
#################

# We source this hook after;
# - sourcing mariner_v2.mk (so that its defaults have had their effect), and
# - after our DEFAULTS overrides and do_mariner_prep() (so that our overriding
#   of defaults has also had its effect, especially for creating the crud
#   directory in the preferred location, initializing tracing, etc), and
# - after defining our OBJECTS and use-case,
# But we source it _BEFORE_ calling do_mariner(). In this way, it can twiddle
# with what has been defined so far, knowing that the crud directory exists and
# the "standard" basedev case has been defined (so we can modify it rather than
# having to reproduce) but prior to Mariner processing it and churning out the
# resulting dependency system.

# It turns out that using $(file<) requires gmake >= v4.2. If you don't like
# that and you're OK with turning on the corporate overrides unconditionally,
# replace all this with "include do-corporate.mk".
$(eval $(if $(or $(DO_CORPORATE),$(shell stat $(DEFAULT_CRUD)/ztouch.do-corporate > /dev/null 2>&1 && echo YES)),\
	$(if $(shell dpkg --compare-versions 4.2 \<= $(MAKE_VERSION) > /dev/null 2>&1 && echo YES),,\
		$(error "Bad: GNU make 4.2 or later is required"))\
	$(file < do-corporate.mk)\
	$(eval TOP_DEPS += do-corporate.mk)))

#################
# Run "mariner" #

$(eval $(call do_mariner))
