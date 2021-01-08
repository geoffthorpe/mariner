# Haul in the obscure magic that processes the configuration and generates all
# the rules and dependencies to make it work. NB: we include it at the top and
# invoke it at the bottom (calling "do_mariner()") so that we can override some
# of the global settings.
include mariner_v1.mk

# mariner_v1.mk sets TOP_deps to the list of top-level files that all container
# image builds should be dependent on. Namely, this GNUmakefile and the
# included mariner code. If you do anything funky (like include other
# sub-makefiles into this one) that give rise to new files that have global
# influence on the build, let the build system know;
#TOP_deps += my-special-sauce.inc

# mariner_v1.mk also sets /bin/sh as the default shell when running
# "make <image>_shell". Let's globally override that to /bin/bash
DEFAULT_shell := /bin/bash

# By default, mariner expects the source/context (incl. Dockerfile) for
# container image foo to be in $(TOPDIR)/c_foo. We can override this for foo by
# setting foo_PATH to something else. However, let's override the default
# mapping itself, so that our replacement mapping gets used when a container
# image does _not_ explicitly set the _PATH attribute. We expect the directory
# for foo to be in ./examples/foo (i.e. in the examples sub-directory and
# without any "c_" prefix).
DEFAULT_map := example_map
define example_map
$(eval $(strip $1)_PATH := $(TOPDIR)/examples/$(strip $1))
endef

# Declare the docker images we want. NB: everything hangs off what do_mariner()
# finds in this IMAGES variable.
IMAGES := basedev vde user-mode-linux
basedev_DESCRIPTION := 'debian:latest' plus some common dev packages
vde_DESCRIPTION := 'basedev' tuned for VDE2, plus 'source' and 'install' volumes.
user-mode-linux_DESCRIPTION := 'basedev' tuned for UML, w/ source + install

# Declare dependencies between image types. In this way, the up-to-dateness for
# a given container image is not just dependent on its own Dockerfile and
# related context, but on the up-to-dateness for container images it depends
# on. Two forms;
#   <name>_EXTENDS := <other in-tree docker image>
#   <name>_TERMINATES := <external docker base image>
basedev_TERMINATES := debian:latest
vde_EXTENDS := basedev
user-mode-linux_EXTENDS := basedev

# Unlike old-school C builds, where you can get the compiler to spew out all
# the file dependencies as it compiles, we have to figure out for ourselves
# when "docker build" does or doesn't need to be rerun. Of course, we can
# invoke "docker build" redundantly, and it does a decent job of skipping steps
# that are cached, but it still slows things down, increases the s2n ratio when
# we're watching out for warnings or errors, and in any case, we want to force
# inter-container dependencies to use _EXTENDS and _TERMINATES, so why ignore
# it in the build dependencies?
#
# By default, the rebuilding of a container image "foo" will occur if the
# modification time of "c_foo/" or any file or directory within it is more
# recent than the last successful build, or if any in-tree container images
# that "foo" extends are more up to date or in need of rebuilding. This
# behavior can be fine-tuned by setting the _find_deps attributes to any valid
# sequence of expression flags to GNU find.
# I.e. by default, the source dependencies for image "foo" are;
#    find c_foo/
# which returns "c_foo/" and all files/sub-directories beneath it. If you
# wanted the build to ignore the modification time of any path that contains
# the word "ignore";
#    foo_find_deps := ! -regex ".*ignore.*"
# will result in the build system creating dependencies using;
#    find c_foo/ ! -regex ".*ignore.*"
#
# NB: unless you really know what you're doing, make sure that whatever you set
# this to will continue to include "Dockerfile" in the list of files it matches
# on!!
#
# E.g. uncomment to make the build ignore changes to any file called TODO.
#vde_find_deps := ! -name "TODO"

# Declare the persistent volumes we want bind-mounted each time a container is
# launched to execute a command. (If not all commands require all the mounts,
# this can be overriden.) Corresponding host directories are auto-created (as
# "./vol_<name>") and auto-mounted (as "/vol_<name>") in the root directory of
# the container's VFS. Specifying the same volume name for more than one image
# results in a single volume that is shared between all container instances for
# those images. Notes;
# - user-mode-linux also mounts install_vde so that it can link against the
#   compiled VDE2 artifacts. That's also why we create an ad-hoc dependency, at
#   the bottom, for 'user-mode-linux_build' on 'vde_build'.
vde_VOLUMES := source_vde install_vde
user-mode-linux_VOLUMES := source_uml install_uml install_vde
source_vde_DESCRIPTION := contains a git clone of the VDE2 source-code
install_vde_DESCRIPTION := where the compiled VDE2 code gets installed
source_uml_DESCRIPTION := contains a git clone of linux-stable.git
install_uml-DESCRIPTION := where the compiled UML kernel and modules go

# The commands that the above images allow (beyond the _create, _delete, _shell
# generics that all images allow). Each time such a command is launched
# (through "make <image>_<command>"), an ephemeral container instance is spun
# up for it, using that docker image and executing the desired command.
vde_COMMANDS := build delete-install delete-source
user-mode-linux_COMMANDS := build delete-install delete-source
# Define and describe each of them (note, COMMAND != COMMANDS)
vde_build_COMMAND := /script.sh
vde_build_DESCRIPTION := Run my magic VDE2 build script in a 'vde' container
vde_delete-install_COMMAND := /delete-install.sh
vde_delete-install_DESCRIPTION := Clean out the install directory
vde_delete-source_COMMAND := /delete-source.sh
vde_delete-source_DESCRIPTION := Clean out the source directory
user-mode-linux_build_COMMAND := /script.sh
user-mode-linux_build_DESCRIPTION := Run my build script in a 'user-mode-linux' container
user-mode-linux_delete-install_COMMAND := /delete-install.sh
user-mode-linux_delete-install_DESCRIPTION := Clean out the install directory
user-mode-linux_delete-source_COMMAND := /delete-source.sh
user-mode-linux_delete-source_DESCRIPTION := Clean out the source directory

# Due to the way that (rootless) docker uses namespaces, cleaning up a
# persistent bind-mount can be tricky if it has already been populated by a
# container command. Some special handling exists to make this more
# user-friendly. If <vol>_WILDCARD is defined, then do_mariner() will run it
# inside the volume while figuring out what rule to generate for the
# <vol>_delete command. If the wildcard matches, it will assume that
# <vol>_CONTROL specifies a designated container image that is used to populate
# and delete that volume, and that <vol>_COMMAND is the command that needs to
# be executed in such a container to perform the requisite cleanup.  If that
# container image hasn't been (successfully) created (so the volume has been
# left lying around after cleaning up images), do_mariner() does not generate a
# dependency to create the container, as that would be bad UX and weird, but it
# will spit out something informative rather than failing in a cryptic way.
source_vde_WILDCARD := *
source_vde_CONTROL := vde
source_vde_COMMAND := delete-source
install_vde_WILDCARD := *
install_vde_CONTROL := vde
install_vde_COMMAND := delete-install
install_uml_WILDCARD := *
install_uml_CONTROL := user-mode-linux
install_uml_COMMAND := delete-install

# Now that our stuff is set, call that "obscure magic" to process it all. Note,
# this must occur after all the variables are set, but should ideally occur
# before any other rules get defined, because do_mariner() instantiates a
# "default:" rule that you probably want to come before anything else. E.g. see
# the ad-hoc dependencies below - if you move that/them above this call to
# do_mariner(), you will not get the expected behavior when you call "make"
# with no arguments.
$(eval $(call do_mariner))

# Ad-hoc dependencies. This allows you to ensure that certain commands force
# prior invocation of other, prerequisite commands. Here, because the build of
# user-mode-linux links against the installed VDE2 artifacts (which is also why
# they both mount 'install_vde'), we make sure that vde_build is run by
# dependency whenever user-mode-linux_build is run.
user-mode-linux_build: vde_build
