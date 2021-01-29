#####################
# TABLE OF CONTENTS #
#####################
#
# First a note about synthetic values for Docker options. The way in which
# settings can be overriden and re-overriden in Mariner runs into trouble for
# boolean properties where one of the boolean values is represented by an empty
# value. E.g. in specifying bind-mount options to "docker run", the opposite of
# "readonly" is to not specify "readwrite". Similarly, a volume must either be
# "managed" and "unmanaged". As settings are inherited from defaults, between
# images, and overriden on the basis of 2-tuple and 3-tuple matches, it needs
# to be possible to replace one value by its opposite, so Mariner implements
# synthetic values so that (a) both sides of the boolean are represented by
# non-empty textual values, and (b) setting one of the values causes the other
# to disappear or error out.
#
# DEFAULTS
#   Global settings. Mostly overridable. Default behavior controls.
#
# OBJECTS
#   Global state, declared by the user, declares the use-case. All subsequent
#   sections serve (only) to layer properties on these objects and their
#   interrelationships. Note, these global settings (VOLUMES, COMMANDS, IMAGES)
#   are not to be confused with attributes that use the singular and/or plural
#   form of the same words (_VOLUME, _COMMANDS, etc).
#
#  -> VOLUMES, lists the distinct "volumes" on the host (either
#     preexisting/unmanaged, or that should be dynamically managed). These
#     are just host directories that bind-mount, not "docker volume"-style
#     volumes. Mariner is (so far) about developer workflows and KISS, it
#     is not (yet) about being a general-purpose Docker wrapper.
#
#  -> COMMANDS, lists all the custom/user-defined verbs that can subsequently
#     be associated with container images. E.g. if a container image
#     "acme-project" supports a verb "update-sourcecode", it's invoked by;
#
#         make acme-project_update-sourcecode
#
#     (Tab-completion works on the Mariner-generated makefile rules, and is
#     recommended, as it allows you to use long but explicative names like
#     these, rather than being cryptic in order to be concise and typeable.
#     That's just my opinion.)
#
#     By the way, there are also generic/builtin commands that are
#     automatically supported by all container images. Most notably the "shell"
#     command, which launches a container using the given image, bind-mounts
#     the relevant volumes to support persistant state that shouldn't be thrown
#     away when the container exits, and opens an interactive shell in that
#     container.)
#
#     Commands also support "profiles", that allows them to be started in
#     different ways. E.g. interactive, batch, ... (eventually, async). They
#     can be started explicitly, otherwise the first profile listed for a
#     command is its default. E.g. the following two may be equivalent;
#
#         make acme-project_update-sourcecode
#         make acme-project_update-sourcecode_interactive
#
#  -> IMAGES, lists all the container image objects that should be produced and
#     kept updated, against which various generic and custom commands can be
#     issued, by spinning up ephemeral/throwaway container instances _using_
#     these container images.
#
# VOLUME attributes
#   Describes each of the volumes declared in the VOLUMES global variable.
#   I.e. is the volume managed/unmanaged, where in the host VFS the "volume"
#   (read: directory) either is (for unmanaged volumes) or where it should be
#   created (for managed volumes), where by default the volume should get
#   mounted into the VFS of any containers that mount it, and any Docker
#   options to pass to the bind-mount arguments.
#
# COMMAND attributes
#   Describes each of the commands declared in COMMANDS. I.e. when a container
#   is spun up to execute the given command (on whichever image the command is
#   acting on), what is the command-line (inside the container) that should be
#   executed, whether the container instance should get a well-defined name
#   (which prevents multiple instances of the command running in parallel),
#   what stdio/TTY behavior is expected of the container, etc.
#
# IMAGE attributes
#   Describes each of the container images declared in IMAGES. I.e. what
#   upstream/underlying container image to derive from, where in the host
#   filesystem the Dockerfile and other context is found, what name to give the
#   container image within the Docker tools, what commands the container image
#   should support, default choices of volumes to mount for commands that
#   execute on the container image, etc.
#
# IMAGE_COMMAND 2-tuples
#   The commands that can be executed against a given container image are
#   determined by IMAGE attributes (_COMMANDS, _UNCOMMANDS, inheritence between
#   images). The settings that apply to such IMAGE/COMMAND pairs are determined
#   by the following order of considerations;
#   1. IMAGE attributes (volumes to mount).
#   2. COMMAND attributes (command-line to execute within the container, Docker
#      naming for the container instance that runs the command).
#   3. VOLUME attributes (where in the container VFS to mount the volume,
#      Docker options for the bind-mount arguments).
#   4. These IMAGE_COMMAND 2-tuples, which can override the settings derived
#      from the previous considerations.
#   5. IMAGE_VOLUME 2-tuples, which can override how volumes are mounted for
#      whichever container image the command is executed against.
#   6. IMAGE_VOLUME_COMMAND 3-tuples, which have a final opportunity to
#      override specific combinations from inheriting the underlying, more
#      coarse-grained 1- and 2-tuple settings.
#
# IMAGE_VOLUME 2-tuples
#   Whenever a container is spun up to execute a command against a container
#   image, a configurable set of volumes get mounted. These 2-tuples allow
#   certain settings (specifically, at what path in the container VFS to mount
#   those volumes, and what bind-mount options to pass to Docker to alter the
#   nature of the mount) to be applied whenever the given combination of IMAGE
#   and VOLUME are matched.
#
# IMAGE_VOLUME_COMMAND 3-tuples
#   Similar to IMAGE_VOLUME 2-tuples, but these provide another (final) way
#   to override mounting options only when the 3-tuple is matched.

############
# DEFAULTS #
############

# TODO: oops, I forgot FIND_DEPS handling!!

# Concise pre-listing (used to cross-check completeness, code, etc)
#   TOPDIR
#   TOP_DEPS
#   DEFAULT_SHELL
#   DEFAULT_ARGS_FIND_DEPS
#   DEFAULT_ARGS_DOCKER_RUN
#   DEFAULT_VOLUME_SOURCE_MAP
#   DEFAULT_VOLUME_DEST_MAP
#   DEFAULT_VOLUME_OPTIONS
#   DEFAULT_IMAGE_PATH_MAP
#   DEFAULT_IMAGE_DNAME_MAP

# Records the top-level directory, where "make" is invoked from.
#TOPDIR := $(shell pwd)

# For container images that are not dependent on other, Mariner-managed imagers,
# we consider them dependent on these "global" files. I.e. if any of these
# files change, we assume that the dependent "docker build"s should be rerun.
# For images that _do_ depend on Mariner-managed images, they will get these
# same dependencies transitively, so don't need them explicitly. The defaults
# assume the mariner_v2.mk code plus the user's GNUmakefile. Override if
# appropriate.
#TOP_DEPS := mariner_v2.mk GNUmakefile

# Default shell, when not otherwise specified
#DEFAULT_SHELL := /bin/sh

# Default arguments to pass to "find $(<img>_PATH) [...]", which determines the
# files/directories that the container image's up-to-dateness should depend on.
# (If the image depends on other mariner-managed images, it will transitively
# depend on those too.) The default value is empty, such that the "find"
# command returns the image's "_PATH" attribute and every file and directory
# within it.
#undefine DEFAULT_ARGS_FIND_DEPS

# Default arguments to pass to "docker build". E.g. --build-arg can be used to
# pass parameters to ARG directives in the Dockerfile.
#DEFAULT_ARGS_DOCKER_BUILD := --build-arg=where_to_put_junk=/a/path

# Default arguments to pass to "docker run". E.g. --env can be used to preset
# environment variables in the containerized process.
#DEFAULT_ARGS_DOCKER_RUN := --env=AN_ENV_VAR="whatever value you want"

# Default arguments to "docker run". In keeping with the spirit of Mariner's
# "fire-and-forget" model, we recommend "--rm" so that container instances are
# ephemeral and garbage-collected.
#DEFAULT_RUNARGS_interactive := --rm -a stdin -a stdout -a stderr -i -t
#DEFAULT_RUNARGS_batch := --rm -i
#DEFAULT_COMMAND_PROFILES := interactive batch

# Set of comma-separated options that should be added to the "--mount
# type=bind,[...]" argument to "docker run". Currently, as we only support
# bind-mounts, this means either the presence or absence of "readonly", and, if
# you're particularly exotic, "bind-propagation", "consistency", and/or
# "bind-nonrecursive". I'm punting on all this and advising you to console
# Docker docs if you care.
# SPECIAL NOTE: Docker's peculiar choice of not having an explicit "readwrite"
# option, means that there's no value you can specify to indicate you wish
# to override a readonly default with a readwrite value, because setting an
# empty override means "don't override". We therefore support a virtual
# "readwrite" option to handle this, and deal with the messy conversion at
# the lowest level of Mariner code. (Cue annoyed grumbling.)
# Default: volumes are mounted readwrite.
#DEFAULT_VOLUME_OPTIONS := readwrite

#DEFAULT_VOLUME_MANAGED := true

# Name of a mapping function that takes a volume name (in Mariner-speak) and
# sets its _SOURCE attribute to a default choice of path for where the volume's
# directory (on the host) should be.
# Default: the source for volume "foo" is at "$(TOPDIR)/vol_foo"
#DEFAULT_VOLUME_SOURCE_MAP := mariner_default_volume_source_map
#define mariner_default_volume_source_map
#	$(eval $(strip $1)_SOURCE := $(TOPDIR)/vol_$(strip $1))
#endef

# Name of a mapping function that takes a volume name (in Mariner-speak) and
# sets its _DEST attribute to a default choice of path for where the volume's
# directory should be bind-mounted (in containers).
# Default: the destination for volume "foo" is at "/vol_foo"
#DEFAULT_VOLUME_DEST_MAP := mariner_default_volume_dest_map
#define mariner_default_volume_dest_map
#	$(eval $(strip $1)_DEST := /vol_$(strip $1))
#endef

# Name of a mapping function that takes an image name (in Mariner-speak) and
# sets its _PATH attribute to a default choice of path for where the image's
# source/context should be.
# Default: the source for "foo" is at "$(TOPDIR)/c_foo"
#DEFAULT_IMAGE_PATH_MAP := mariner_default_image_path_map
#define mariner_default_image_path_map
#	$(eval $(strip $1)_PATH := $(TOPDIR)/c_$(strip $1))
#endef

# Name of a mapping function that takes an image name (in Mariner-speak) and
# sets its _DNAME attribute to a default choice of what the underlying Docker
# container image should be called.
# Default: the dname for "foo" is "foo".
#DEFAULT_IMAGE_DNAME_MAP := mariner_default_image_dname_map
#mariner_default_image_dname_map
#	$(eval $(strip $1)_DNAME := $(strip $1))
#endef

###########
# OBJECTS #
###########

# Concise pre-listing (used to cross-check completeness, code, etc)
#   VOLUMES
#   COMMANDS
#   IMAGES

# A volume is simply the Mariner term for non-ephemeral storage. In
# Docker-speak, we use bind-mounts to map host directories into containers.
# We're not using Docker volumes in the heavy-weight sense. (There are no
# "volume drivers" involved.)
#
# VOLUMES specifies the names of volumes that Mariner should know about (and
# optionally manage).

VOLUMES := \
	scratch \
	some-source-checkout \
	my-handy-scripts

# This lists the _names_ (i.e. abstract handles) of particular commands that
# can be implemented and supported for various container images. The actual
# _command line_ for these abstract commands is provided by their corresponding
# COMMAND attribute (note that COMMANDS != COMMAND), which can in turn be
# overriden on a per-container-image basis if required. Note, the user can not
# supply the "create" or "delete" commands, as they are constructor/destructor
# generics that get automatically generated for all images. If the user doesn't
# define the "shell" command here, it will also be autogenerated for all
# _TERMINATES images, so that its inheritence (and handling of _UNCOMMANDS
# attributes) get respected in the usual way.

COMMANDS := \
	run-daily-tasks \
	git-fetch-all-clones

# This lists the _names_ (i.e. abstract handles) of container images this
# system will implement. The concept is that these things are defined in an
# object-oriented fashion, with hierarchical relationships, as per the
# Dockerfile "FROM" directive. When an interactive shell or an automated
# command is started against a given image, a new and ephemeral container
# instance is launched for it, using the given image.

IMAGES := \
	daily-tasks \
	dev-baseline \
	webserver-optimization \
	mariner-dev \
	handy-scripts-hacking

#####################
# VOLUME attributes #
#####################

# Concise pre-listing (used to cross-check completeness, code, etc)
#   DESCRIPTION
#   SOURCE
#   DEST
#   OPTIONS
#   MANAGED

# _DESCRIPTION provides a short, human-readable description of the command
# and/or it's purpose. It is recommended for this to be ~50 characters or less.
# Optional, the default is an empty description.
scratch_DESCRIPTION := temporary storage in a high-speed filesystem
some-source-checkout_DESCRIPTION := git clone of linux-stable
my-handy-scripts_DESCRIPTION := my home-grown go-to set of utils and wrappers

# _SOURCE specifies the host paths for the named volumes. I.e. the directory
# where the actual data is stored.
# Optional, the default for foo is;
#       $(eval $(call $(DEFAULT_VOLUME_SOURCE_MAP),foo))
scratch_SOURCE := $(TOPDIR)/fast-storage/$(USER)/mariner-tmp
some-source-checkout_SOURCE := $(HOME)/devel/linux-stable
my-handy-scripts_SOURCE := $(HOME)/handy-scripts

# _DEST specifies the destination paths for the named volumes. I.e.  the path
# inside containers where the volume should be mounted.
# Optional, the default for foo is;
#       $(eval $(call $(DEFAULT_VOLUME_DEST_MAP),foo))
scratch_DEST := /fast-tmp
some-source-checkout_DEST := /devel/linux-stable

# _OPTIONS specifies the default mount options. I.e. a comma-separated list of
# options that should be appended to the "--mount
# type=bind,source=<...>,dest=<...>[,...]" argument that is passed to "docker
# run".
# Optional, the default is $(DEFAULT_VOLUME_OPTIONS)
my-handy-scripts_OPTIONS := readonly

# There are two modes of usage for volumes, to cater to two kinds of use-case
# requirements. "Unmanaged" amounts to saying that the volume "simply exists,
# and fail if it doesn't" - no attempt is made to automatically create the
# volume, and no support is given to cleaning up let alone deleting the volume.
# "Managed" on the other hand assumes that Mariner is expected to create and
# manage the lifetime of the volume, just as it does with container images.
#
# The "unmanaged" case is generally used when Mariner is a drop-in for
# providing environments (container images) for working with existing data,
# and/or data that in someway "outlives" (or "lives outside") the Mariner
# configuration.
#
# The "managed" case is generally used when volumes are required to have data
# persist across individual commands, especially when such data is exchanged
# between different logic embedded in distinct container images, and extra
# especially when the data is produced and consumed by automated tooling
# (rather than, say, human editing). E.g. a CI/CD pipeline. Containers are
# intentionally kept very ephemeral and lose all their state as soon as the
# commands they run complete, so persistent storage is necessary, but if the
# usefulness and lifetime of the storage is still closely tied to the workflow,
# it can make sense to have Mariner manage the spinning up and tearing down of
# volumes much as it does the building and cleaning up of container images.
#
# If the _MANAGED attribute isn't defined, the volume is presumed to be
# unmanaged. Setting it to an empty value can force it to be unmanaged, e.g.
# if the default is for volumes to be managed.
# Optional, the default is $(DEFAULT_VOLUME_MANAGED)
scratch_MANAGED := true
undefine some-source-checkout_MANAGED
undefine my-handy-scripts_MANAGED

# For managed volumes, the lifecycle management works as follows. If a
# container image depends on a volume, what that means is that every command on
# that container image depends on that volume, including the generic commands
# (_create, _shell, and _delete). As a consequence, such a container image must
# be deleted before any volume it depends on can be deleted, which in turn
# means that any cleanup required in the volume before it can be deleted must
# either be (a) performed by the container before it is deleted (such as in its
# _delete command), or (b) performed by another container image/command.
# Alternatively, you can avoid having a dependency on the volume by the
# container image itself, and make only specific commands dependent on the
# image.

######################
# COMMAND attributes #
######################

# Concise pre-listing (used to cross-check completeness, code, etc)
#   DESCRIPTION
#   COMMAND
#   DNAME
#   PROFILES
#   ARGS_DOCKER_RUN

# _DESCRIPTION provides a short, human-readable description of the command
# and/or it's purpose. It is recommended for this to be ~50 characters or less.
# Optional, the default is an empty description.
run-daily-tasks_DESCRIPTION := execute $(run-daily-tasks_COMMAND)
git-fetch-all-clones_DESCRIPTION := \
		Run "git fetch" in all paths listed in /clones.list

# _COMMAND specifes the path/command/arguments that should be passed to the
# "docker run" command that starts the (ephemeral) container that gets
# launched. Note that Mariner commands, like volumes, are defined independently
# of the container images that associate with them, and so they don't and can't
# explicitly declare dependencies on images (or volumes). If this attribute
# implicitly depends on the presence of certain supporting artifacts in the
# container image (and/or mounted volumes) that will spin up to execute them,
# that is ... well ... your problem. Note that this attribute can be overriden
# on a per-container-image basis, at the level of a {image,command} 2-tuple.
# Required, failure to specify a _COMMAND attribute is a fatal error.

# This example assumes that the Dockerfile (and context) for the container
# image that implements this command provides the given shell script at the
# given path.
run-daily-tasks_COMMAND := /run-all-tasks.sh

# TODO: untested whether this syntax is correct!
# This example assumes that a file in the root directory contains a list of
# git clones that should be fetched.
git-fetch-all-clones_COMMAND := /bin/bash -c \
	" \
		set -x ; \
		list=`cat /clones.list`; \
		for i in $list; do \
			(cd $$i && git fetch); \
		done \
	"

# _DNAME indicates that the container that is spun up with "docker run" to
# execute this command (using whatever container image) should be assigned the
# given name, rather than choosing something random. One consequence of using
# this option is that it will implicitly prevent more than one instance of the
# same command from being executed at a time (per docker/container daemon).
# Note that this attribute can be overriden on a per-container-image basis, at
# the level of a {image,command} 2-tuple.
# Optional, the default is empty (Docker chooses a DNAME dynamically).
run-daily-tasks_DNAME := daily-tasks

# All of these commands are non-interacive, don't bother exporting interactive
# variants.
run-daily-tasks_PROFILES := batch
git-fetch-all-clones_PROFILES := batch

# The default PROFILES setting for the shell command is interactive-only. Just
# for kicks, allow it to be run batch-only too.
shell_PROFILES := interactive batch

# _ARGS_DOCKER_RUN specifies any _command-specific_ options that should be
# passed to "docker run" when this command is launched against a container
# image. Note, if the image also defines _ARGS_DOCKER_RUN, the two are
# combined, unless they are both overriden by a 2-tuple IMAGE/COMMAND setting.
git-fetch-all-clones_ARGS_DOCKER_RUN := --env=GIT_ALTERNATE_OBJECT_DIRECTORIES=/mnt/obj-store

####################
# IMAGE attributes #
####################

# Concise pre-listing (used to cross-check docs, code, semantics, ...)
#   DESCRIPTION
#   TERMINATES
#   EXTENDS
#   PATH
#   NOPATH
#   DOCKERFILE
#   PATH_FILTER
#   DNAME
#   PATH_MAP
#   DNAME_MAP
#   VOLUMES
#   UNVOLUMES
#   COMMANDS
#   UNCOMMANDS
#   ARGS_DOCKER_BUILD
#   ARGS_DOCKER_RUN

# _DESCRIPTION provides a short, human-readable description of the image and/or
# it's purpose. It is recommended for this to be ~50 characters or less.
# Optional, the default is an empty description.
daily-tasks_DESCRIPTION := janitorial stuff, backups and so forth
dev-baseline_DESCRIPTION := Same base platform that colleagues are using
webserver-optimization_DESCRIPTION := \
			Hacking that nginx sidecar \
			thing that the boss asked for
mariner-dev_DESCRIPTION := Developing the code for Mariner using Mariner

# _EXTENDS/_TERMINATES indicates what container image _this_ container image
# should be derived from. _EXTENDS gives the name of another image defined and
# managed by Mariner, whereas _TERMINATES gives the name of an
# external/upstream container image. This determines;
# - the way Mariner auto-prefixes each Dockerfile with a FROM directive,
# - the way Mariner handles build dependencies between container images (and
#   their sources),
# - some inheritence properties, in particular when _EXTENDS is used;
#   - any commands defined for the base image are inherited by the derived
#     image, unless the latter explicitly disinherits those commands (using
#     _UNCOMMANDS).
#   - any volumes the base image depends on are inherited as dependencies for
#     the derived image also, unless the latter explicitly disinherits those
#     volumes (using _UNVOLUMES).
# Required, each image must declare either _EXTENDS or _TERMINATES, but not
# both.
daily-tasks_TERMINATES := debian:latest
dev-baseline_TERMINATES := debian:buster
webserver-optimization_EXTENDS := dev-baseline
mariner-dev_EXTENDS := dev-baseline
handy-scripts-hacking_EXTENDS := dev-baseline

# _PATH indicates the location where the "source" (metadata) for a container
# image can be found. This is what Docker calls "context", which the image's
# Dockerfile can call upon when building the image. By default, Mariner expects
# to find the Dockerfile in this path also (unless overriden by the _DOCKERFILE
# attribute). In addition to the Docker significance of this directory, Mariner
# also creates build dependencies on the contents of this directory (subject to
# the _ARGS_FIND_DEPS attribute), in order to know when container images are out
# of date and in need of rebuild.
# Optional, otherwise the default for container image "foo" is;
#       $(eval $(call $(foo_PATH_MAP),foo))
daily-tasks_PATH := $(HOME)/secretaria/docker/
dev-baseline_PATH := $(HOME)/work/base-platform-docker
mariner-dev_PATH := /mariner/docker
# webserver-optimization_PATH := $(TOPDIR)/c_webserver-optimization

# _NOPATH is a BOOL-typed property (so it is "true" or "false"), which if TRUE
# means that the container image uses no context, and so _PATH should be
# ignored. If _NOPATH is set "true", _DOCKERFILE must be set.
# Optional, otherwise the default is "false".

# _DOCKERFILE indicates the location where the Dockerfile for the container
# image can be found. By default, this is assumed to be in the image's "_PATH",
# a.k.a. the "context". It doesn't need to be however.
# Optional, otherwise the default for container image "foo" is;
#       $(foo_PATH)/Dockerfile

# _PATH_FILTER allows the user to limit the search for files and directories
# within the image's _PATH (unless _NOPATH is set, in which case none of this
# applies). The search creates dependencies for regeneration of the container
# image, and by default it finds everything, using;
#       find -L $(foo_PATH) $(foo_PATH_FILTER)
# However the user may want to ignore some elements from the context area, e.g.
# because they are copied into place by some other automation but we don't use
# them, and/or because their absence should be tolerated and shouldn't trigger
# rules or failure, etc. E.g. to eliminate a particular log sub-directory from
# consideration, as well as anything beginning with "tmp_", one could set;
#       foo_PATH_FILTER := \
#               -path "*/logs-to-ignore" -prune \
#               -o ! -name "tmp_*"
# Optional, otherwise the default is empty.

# _DNAME allows the container image name in Mariner-speak (i.e. the text handle
# used in Mariner commands and makefle configuration) to be different from the
# name used in Docker commands.
# Optional, the default for "foo" is;
#       $(eval $(call $(foo_DNAME_MAP),foo))
webserver-optimization_DNAME := nginx-work-hacking

# _PATH_MAP tells Mariner how to set a container image's _PATH attribute if the
# user doesn't explicitly set/override it. The attribute is set to the name of
# a function that gets called to the _PATH attribute of the image object in
# question. Note that this _PATH_MAP attribute can _also_ be set by the user if
# desired. So the user has two ways of overriding how the _PATH attribute for a
# container image gets set (to a non-default value), and should probably choose
# based on whether they intend to derive other container images from this one.
# To override the _PATH for this specific image, simply set _PATH. To override
# the _way_ the _PATH gets set by default, for this image _and all others
# derived from it_ (unless they also make some override), set _PATH_MAP.
# Optional, otherwise it defaults to either;
# - the _PATH_MAP value of the image we are derived from, if _EXTENDS, else
# - the DEFAULT_IMAGE_PATH_MAP value, if _TERMINATES.
dev-baseline_PATH_MAP := work_image_path_map
# This example suggests that, unless overriden, dev-baseline and all images
# derived from it should have their _PATH default to directories called
# "docker_<foo>" (for a given image <foo>) inside $(HOME)/work.
define work_image_path_map
	$(eval $(strip $1)_PATH := $(HOME)/work/docker_$(strip $1))
endef

# _DNAME_MAP is to _DNAME exactly what _PATH_MAP is to _PATH.
dev-baseline_DNAME_MAP := prefix_with_work
# This example suggests that, unless overriden, dev-baseline and all images
# derived from it should have their image names _in Docker_ all prefixed by
# "work-". E.g. if you have multiple Mariner environments managing different
# _sets_ of workflows, and you need to avoid naming collision in Docker, this
# is one way to skin that feline.
define prefix_with_work
	$(eval $(strip $1)_DNAME := work-$(strip $1))
endef

# _VOLUMES specifies the volumes that this container image, and any commands
# against it, and any containers images derived from it (unless overriden by
# _UNVOLUMES), depend on. For those volumes that are managed, this creates a
# dependency on their creation, and prevents them from being deleted while
# dependent container images still exist.
# Optional, otherwise it defaults to either;
# - the _VOLUMES value of the image we are derived from, if _EXTENDS, else
# - empty, if _TERMINATES.
dev-baseline_VOLUMES := my-handy-scripts scratch

# _UNVOLUMES specifies volumes that this container should _not_ depend on, in
# case such a dependency would otherwise be inherited from another image
# (through _EXTENDS) or is otherwise set in _VOLUMES (e.g. because of unified
# definitions that we want to create exceptions to).
# Optional, otherwise it defaults to empty.
mariner-dev_UNVOLUMES := scratch

# _COMMANDS specifies the commands that this container image, and any container
# images derived from it (unless overriden by _UNCOMMANDS), support.
# Optional, otherwise it defaults to either;
# - the _COMMANDS value of the image we are derived from, if _EXTENDS, else
# - empty, if _TERMINATES.
daily-tasks_COMMANDS := run-daily-tasks
dev-baseline_COMMANDS := git-fetch-all-clones

# _UNCOMMANDS specifes commands that this container should _not_ support, in
# case such commands would otherwise be inherited from another image (through
# _EXTENDS) or is otherwise set in _COMMANDS (e.g. because of unified
# definitions that we want to create exceptions to).
# Optional, otherwise it defaults to empty.
mariner-dev_UNCOMMANDS := git-fetch-all-clones

# _ARGS_DOCKER_BUILD specifies options that should be passed to "docker build"
# when building this image.
# Optional, otherwise it defaults to either;
# - the _ARGS_DOCKER_BUILD of the image we are derived from, if _EXTENDS, else
# - DEFAULT_ARGS_DOCKER_BUILD, if _TERMINATES.
dev-baseline_ARGS_DOCKER_BUILD := --build-arg=CROSS_COMPILER_FOR="i386 x86_64"

# _ARGS_DOCKER_RUN specifies options that should be passed to "docker run" when
# launching containers using this image. If the command being launched also has
# an _ARGS_DOCKER_RUN attribute, the two will be combined (based on the
# rationale that one setting is image-specific and command-agnostic, and the
# other setting is image-agnostic and command-specific). On the other hand, if
# the corresponding IMAGE/COMMAND 2-tuple has an _ARGS_DOCKER_RUN attribute, it
# will override both (based on the rationale that a 2-tuple setting is specific
# to the combination of both).
# Optional, otherwise it defaults to either;
# - the _ARGS_DOCKER_RUN attribute of the image we are derived from, if
#   _EXTENDS, else
# - DEFAULT_ARGS_DOCKER_RUN, if _TERMINATES

##########################
# IMAGE_COMMAND 2-tuples #
##########################

# TODO: should we have UNDNAME attributes, to allow overrides that unset DNAME
# from defaults/inheritence?

# Concise pre-listing (used to cross-check completeness, code, etc)
#   COMMAND
#   DNAME
#   VOLUMES
#   UNVOLUMES
#   PROFILES
#   ARGS_DOCKER_RUN

# _COMMAND for a particular {image,command} 2-tuple overrides the _COMMAND
# attribute of the underlying command.

# For this example, suppose that the webserver-optimization image have a
# different way of updating git clones, using a script contained in the image.
webserver-optimization_git-fetch-all-clones_COMMAND := /git-update.sh

# _DNAME for a 2-tuple overrides the _DNAME attribute of the underlying
# command.

# For this example, make sure git updates in different containers can occur in
# parallel to each other, but that only one update per-container at a time.
dev-baseline_git-fetch-all-clones_DNAME := update-dev-baseline
webserver-optimization_git-fetch-all-clones_DNAME := update-webserver-op
mariner-dev_git-fetch-all-clones_DNAME := update-webserver-mariner-dev
handy-scripts-hacking_git-fetch-all-clones_DNAME := update-handy-scripts-hack

# _VOLUMES allows a 2-tuple to mount volumes that aren't mounted by default for
# the underlying image.

# For this example, note that "dev-baseline" has "scratch" in its _VOLUMES
# attribute but the derived "mariner-dev" has "scratch" in its _UNVOLUMES
# attribute. The following re-adds "scratch" when the "git-fetch-all-clones"
# command is involved.
mariner-dev_git-fetch-all-clones_VOLUMES := scratch

# _UNVOLUMES allows a 2-tuple to eliminate volumes that would otherwise be
# mounted for the underlying image.

# _PROFILES allows a 2-tuple to change a command's profiles on a per-image
# basis.

# We allowed the "shell" command to be in both interactive and batch modes, so
# for kicks remove the batch mode from one of the image/command combinations.
handy-scripts-hacking_shell_PROFILES := interactive

# _ARGS_DOCKER_RUN allows a 2-tuple to specify the options that should be
# passed to "docker run" for this combination of image and command, overriding
# the default behavior, which is to combine the _ARGS_DOCKER_RUN attributes of
# the image _and_ the command.

#########################
# IMAGE_VOLUME 2-tuples #
#########################

# Concise pre-listing (used to cross-check completeness, code, etc)
#   DEST
#   OPTIONS

# _DEST allows a particular {image,volume} 2-tuple to set where the given
# volume should be mounted in any containers based on the given image.  (This
# can, in turn, be overriden on a per-command basis, at the level of a
# {image,volume,command} 3-tuple.)
# Optional, otherwise it defaults to;
# - if _EXTENDS, _DEST is inherited from the <base-image,volume> 2-tuple,
#   else
# - <volume>_DEST
# Note, as we progres down a dependency chain from a _TERMINATES image to all
# the images that extend it, the volumes that do and don't get mounted can
# change multiple times (through VOLUMES and/or UNVOLUMES attributes of the
# images). It is legit to provide attributes for an IMAGE/VOLUME 2-tuple where
# the image doesn't use the volume, because _derived images_ may use that
# volume, and you'd the corresponding 2-tuples (for derived images) to inherit
# attributes for ancestor 2-tuples.
mariner-dev_my-handy-scripts_DEST := /mariner/my-handy-scripts

# _OPTIONS is handled per the same semantics as _DEST
handy-scripts-hacking_my_handy-scripts_OPTIONS := readwrite

#################################
# IMAGE_VOLUME_COMMAND 3-tuples #
#################################

# Concise pre-listing (used to cross-check completeness, code, etc)
#   DEST
#   OPTIONS

# _DEST allows a particular {image,volume,command} 3-tuple to set where the
# given volume should be mounted in any containers based on the given image and
# executing the given command.
# Optional, otherwise it defaults to;
# - if _EXTENDS;
#   - _DEST is inherited from the <base-image,volume,command> 3-tuple (this
#     recurses, so that 3-tuple inheritence flows from the _TERMINATES case back
#     up the _EXTENDS chain).
#   - if that is empty, _DEST inherits from the <image,volume> 2-tuple (no need
#     to recurse, as image/volume 2-tuple recursion has occurred and defaults
#     have been filled in.
#   else
# - <image>_<volume>_DEST
# Similarly to the handling for IMAGE/VOLUME 2-tuples, we process 3-tuples all
# the way down the dependency chain without concern for whether those tuples
# are for volumes that are not mounted by that specific 3-tuple, because
# 3-tuples for derived images may mount those volumes and we'd want the default
# inheritence to work anyway.
