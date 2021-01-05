#############
# Table of contents:
#  - Intro
#  - Global setup
#  - Pre-processing
#  - Post-processing
#  - Rule-time functions
#############

#############
# Intro
#
# The user supplies a makefile that defines their use-case (typically
# GNUmakefle, seeing as this functionality is specific to GNU make), includes
# this file, and then invokes the do_mariner() API to produce all the rules,
# dependencies and other obscure machinery. If the user wishes to override some
# of the global settings, they should do so after including this file and
# before invoking the API.
#
# For more info, look at the example GNUmakefile(s) and the "documentation"
# therein. Also, "make" (i.e. the default rule) will spit out a list of the
# most important commands, and "make dump" can also provide some insights.
#############

#############
# Global setup
#
# These settings can be overriden by the user's makefile, if required, at their
# risk and peril. :-)
#############

# If V is defined, make a lot more noise
ifndef V
  Q := @
endif

# Passed to "docker run".
$(eval DEFAULT_docker_run_args := --rm -a stdin -a stdout -a stderr -i -t)

# This is the default shell to use for the generic "make <image>_shell"
# command.
$(eval DEFAULT_shell := /bin/sh)

# The user supplies IMAGES, upon which everything else hangs. I.e. do_mariner()
# processes this variable and what it finds there leads it to everything else.
# The build expects to find the path to each image's source/context directory
# via the <image>_PATH attribute. If the user does not set that attribute,
# do_mariner() will set it using the default map function as defined below.
# This default implementation assumes the source path for image "foo" will be
# in $(TOPDIR)/c_foo.
# The user can optionally set DEFAULT_map to use an alternative map function.
# Note the semantics: $1 is the name of the container (from IMAGES), and the
# resulting path should be put in $1_PATH.
$(eval DEFAULT_map := mariner_default_map)
define mariner_default_map
$(eval $(strip $1)_PATH := $(TOPDIR)/c_$(strip $1))
endef

# If a container image <foo> doesn't define <foo>_find_deps, this default will
# get used. This passes arguments to the "find $(foo_PATH)/ [...]" command, and
# whatever that returns is what we use as a dependency for rebuilding the
# container image, as well as dependencies on other container images (that we
# extend. (This command is evaluated inside the image's source directory, where
# its Dockerfile goes.)
$(eval DEFAULT_find_deps = )

# This is included by the top directory Makefile, so set a TOPDIR that can
# survive being passed around, fed into Dockerfiles, or whatever else.
$(eval TOPDIR := $(shell pwd))

# In addition to making container image builds dependent on each other and
# their respective source files (Dockerfile, etc), they should also be
# dependent on anything global at the top-level directory. This is the default
# list, it can be replaced or extended by the user in GNUmakefile.
$(eval TOP_deps := mariner_v1.mk GNUmakefile)

# VOLUMES is populated as each of the image types (and their "<foo>_VOLUMES"
# attributes) are processed. It's done this way to support the semantic whereby
# two images can specify the same volume to indicate sharing of a single
# volume.
$(eval VOLUMES := )

# Adding a directory to this variable causes a rule to be generated that allows
# the directory to be auto-created by declaring a dependency on it.
# NOTE: you usually want to specify such a dependency as _order-only_. E.g.
#
# MDIRS += $(TOPDIR)/output_dir
#
# $(TOPDIR)/output_dir/artifact: [...normal deps...] | $(TOPDIR)/output_dir
#         echo "Some output" > $(TOPDIR)/output_dir/artifact
#
# If the "|" isn't there, then "artifact" becomes dependent not just on whether
# the "output_dir" directory exists _but also on it's modification time_! If
# you don't want the "artifact" rule to fire when its normal deps are satisfied
# and the output directory exists, you need the "|". (Otherwise, if any
# unrelated activity updates the modification time of "output_dir", the
# "artifact" target will be automatically out-of-date and will fire
# needlessly.)
#
# For details, see;
# https://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html
#
# Our main use of this is for lazy-initialization of volumes for bind-mounting,
# but we create a rule to chain through that encapsulates this "|" usage. (See
# the gen_volume() function, which creates the "vol_$v_create" rule for each
# volume $v.)
$(eval MDIRS := )

#############
# API
#############

define do_mariner
$(eval $(call do_parse))
$(eval $(call do_gen))
$(eval $(call do_mdirs))
endef

#############
# Pre-processing (we use the verb: "parse")
#
# We consume IMAGES and follow our noses based on what we find there, producing
# all the internal data required to "know what to do", which is then consumed
# by the subsequent post-processing steps that produce all the actual rules
# and dependencies.
#
# Note, processing (in both phases!) is littered with "$(eval ...)" directives
# in order to force expansion and evaluation in-place.
# 
# GNU make is ... weird. But thank $(eval $(call choose_deity)) it exists!
#############

define do_parse
$(foreach i,$(IMAGES),$(eval $(call parse_image,$i,$($i_VOLUMES),$($i_COMMANDS))))
$(foreach i,$(VOLUMES),$(eval $(call parse_volume,$i)))
$(eval GEN_IMG_TARGETS += create)
$(eval GEN_IMG_TARGETS += delete)
$(eval GEN_IMG_TARGETS += shell)
$(eval gen_img_create_DESCRIPTION := create container image and anything it depends on)
$(eval gen_img_delete_DESCRIPTION := delete container image and anything that depends on it)
$(eval gen_img_shell_DESCRIPTION := start $(DEFAULT_shell) in a container)
$(eval GEN_VOL_TARGETS += create)
$(eval GEN_VOL_TARGETS += delete)
$(eval gen_vol_create_DESCRIPTION := create volume)
$(eval gen_vol_delete_DESCRIPTION := delete volume)
endef

# Called for each container image $1 in $(IMAGES).
#  $1 - name to give the container image
#  $2 - list of bind-mounts for containers using this image. For each 'i',
#       "$(TOPDIR)/vol_$i" is mounted in the root directory of the container,
#       at "/vol_$i".
#  $3 - list of commands that can be run against this image (inside ephemeral
#       containers). For each 'i';
#       - "make $1_$i" spins up a container to execute the command.
#       - the command to run (inside the container) must be specified in the
#         environment variable $1_$i_COMMAND.
# Also, update VOLUMES using $2, but only when we see a volume name we haven't
# seen before.
define parse_image
$(eval n := $(strip $1))
$(eval b := $(strip $2))
$(eval c := $(strip $3))
$(if $($n_PATH),,$(eval $(call $(DEFAULT_map),$n)))
$(if $($n_EXTENDS),$(eval $(call parse_image_EXTENDS,$n)),$(eval $(call parse_image_TERMINATES,$n)))
$(eval $n_find_deps ?= $(DEFAULT_find_deps))
$(eval $n_create_deps += $(shell find $($n_PATH)/ $($n_find_deps)))
$(eval $n_mountdeps := $(foreach i,$b,vol_$i_create))
$(eval $n_mountargs := $(foreach i,$b,--mount type=bind,source=$(TOPDIR)/vol_$i,destination=/$i))
$(foreach i,$c,$(eval $(call parse_image_cmd,$n,$i)))
$(foreach i,$b,$(eval VOLUMES += $(filter-out $(VOLUMES),$i)))
$(foreach i,$b,$(eval vol_$i_image_deps += $n))
endef
define parse_image_EXTENDS
$(eval n := $(strip $1))
$(eval $n_create_deps := .touch_c_$(strip $($n_EXTENDS)))
$(eval $n_delete_deps := $(strip $($n_EXTENDS))_delete)
$(eval $n_from := $($n_EXTENDS))
endef
define parse_image_TERMINATES
$(eval n := $(strip $1))
$(eval $n_create_deps := $(TOP_deps))
$(eval $n_delete_deps := )
$(eval $n_from := $($n_TERMINATES))
endef
define parse_image_cmd
$(eval n := $(strip $1))
$(eval c := $(strip $2))
$(eval $n_$c_deps := $n_create $($n_mountdeps))
$(eval $1_subcommands += $c)
endef

# Called for each volume in $(VOLUMES).
#  $1 - friendly name for the volume. The actual directory name will be
#       prefixed with "vol_<name>", and whenever the volume is bind-mounted to
#       a container, it will appear at "/vol_<name>", i.e. in the root
#       directory.
# Strictly speaking, dependencies on this volume could bypass the "$n_create"
# rule and declare an order-only dependency on the volume directory, as
# described for MDIRS above. Using this intermediate rule is preferable though
# for a couple of reasons;
# - this will detect any attempt to declare the same volume twice, which would
#   indicate a bug in do_image()'s use of the filter-out macro.
# - dependencies on the $n_create rule don't need the order-only "|" qualifier,
#   because it is handled here.
define parse_volume
$(eval n := $(strip $1))
$(eval MDIRS += $(TOPDIR)/vol_$n)
$(eval vol_$n_create_deps := $(TOPDIR)/vol_$n)
endef

#############
# Post-processing (we use the verb: "gen"erate)
#
# Generate rules and dependencies based on the state and understanding that was
# built up during pre-processing.
#############

# Special note for vol_all_delete, coz this is weird. Normally, the dependency
# of vol_all_delete on vol_<everything>_delete is fine. Except in a weird
# situation, where the volume has stuff that needs specialized cleanup
# (<vol>_WILDCARD matches), and so it will run a command (<vol>_COMMAND) in a
# container (using image <vol>_CONTROL) to do that, but that container/command
# 2-tuple has a dependency on a bind-mount that _we have already deleted_
# (because we're in vol_all_delete). In that case, the special work to
# eliminate one volume may recreate a volume we previously eliminated. (TODO:
# this probably means the vol_all_delete target isn't safe with parallel
# make??) Workaround: have vol_all_delete call itself a second time... erk.
define do_gen
$(eval $(call gen_default))
$(eval $(call gen_dump))
$(foreach c,$(GEN_IMG_TARGETS),$(eval $(call gen_all_img,$c)))
$(foreach c,$(GEN_VOL_TARGETS),$(eval $(call gen_all_vol,$c)))
$(foreach i,$(IMAGES),$(eval $(call gen_image,$i)))
$(foreach i,$(VOLUMES),$(eval $(call gen_volume,$i)))
vol_all_delete:
	$Q(if [ "v$(PASS2)" = "v" ]; then \
		PASS2=1 make vol_all_delete; \
	fi )
$(eval $(call gen_mdirs))
endef

# Produce the default rule. This provides "usage" and performs no operations.
# Note, 
define gen_default
default:
	$$Qecho
	$$Qecho "Specify a target! How many times do I have to tell you?"
	$$Qecho
	$$Qecho "Generic commands for all container images (you can use <image>=all);"
	$$(foreach i,$$(GEN_IMG_TARGETS),$$(call list_gen_img,$$i))
	$$Qecho
	$$Qecho "Container images;"
	$$(foreach i,$$(IMAGES),$$(call list_img,$$i))
	$$Qecho
	$$Qecho "Generic commands for all volumes (you can use <vol>=all);"
	$$(foreach c,$$(GEN_VOL_TARGETS),$$(call list_gen_vol,$$c))
	$$Qecho
	$$Qecho "Implied (and persistent) volumes;"
	$$(foreach v,$$(VOLUMES),$$(call list_vol,$$v))
	$$Qecho
endef

# Produce the "dump" rule. This pretty-prints out a bunch of the internal state
# that was derived during pre-processing (and that drives post-processing).
# Useful for debugging, but probably in need of improvement.
define gen_dump
dump:
	$$Qecho "Dumping for your debugging delight"
	$$Qecho
	$$(call dump_all)
$(eval TARGETS += dump)
$(eval dump_DESCRIPTION := "info to help debug this build system")
endef
define dump_all
	$(foreach i,$(IMAGES),$(call dump_image,$i))
	$(foreach i,$(VOLUMES),$(call dump_volume,$i))
	$Qecho "MDIRS: $(MDIRS)"
endef
define dump_image
	$(eval n := $(strip $1))
	$Qecho "IMAGE: $n"
	$Qecho "     path       : $($n_PATH)"
	$Qecho "     create_deps: $($n_create_deps)"
	$Qecho "     delete_deps: $($n_delete_deps)"
	$Qecho "     find_deps  : $($n_find_deps)"
	$Qecho "     from       : $($n_from)"
	$Qecho "     mountdeps  : $($n_mountdeps)"
	$Qecho "     mountargs  : $($n_mountargs)"
	$Qecho "     subcommands: $($n_subcommands)"
	$Qecho
endef
define dump_volume
	$(eval v := $(strip $1))
	$Qecho "VOLUME: $v  (vol_$v_create)"
	$Qecho "     create_deps: $(vol_$v_create_deps)"
	$Qecho "     image_deps : $(vol_$v_image_deps)"
	$Qecho "     wildcard   : $($v_WILDCARD)"
	$Qecho "     control    : $($v_CONTROL)"
	$Qecho "     command    : $($v_COMMAND)"
	$Qecho
endef

# Generate "all_<verb>" rules for the generic container image command in $1.
# This is just a dependency on the corresponding "<img>_<verb>" rules for each
# image.
define gen_all_img
$(eval c := $(strip $1))
all_$$c: $$(foreach i,$$(IMAGES),$$i_$$c)
endef

# Generate "vol_all_<verb>" rules for the generic volume command in $1. This is
# just a dependency on the corresponding "<vol>_<verb>" rules for each volume.
define gen_all_vol
$(eval c := $(strip $1))
vol_all_$$c: $$(foreach v,$$(VOLUMES),vol_$$v_$$c)
endef

# Generate rules for the container image in $1. This includes the _create,
# _delete, and _shell generics, as well as all the user-defined commands.
# Note, the dependency relationships between container images are reflected
# here in curious ways. For creation, the deps are between touchfiles. For
# deletion, the deps are between the _delete targets (rather than touchfiles)
# and they are in an inverted sense! (Makes sense if you think for a bit.)
# Also, the delete rules are generated differently depending on whether the
# container images already exist (so we don't create things in order to delete
# things).
define gen_image
$(eval n := $(strip $1))
$(eval $(call gen_image_create,$n))
$(if $(wildcard .touch_c_$n),$(eval $(call gen_image_delete,$n)),$(eval $(call gen_image_delete_null,$n)))
$n_shell: $n_create $($n_mountdeps)
	$Qecho "Launching a '$n' container with shell '$(DEFAULT_shell)'"
	$Qdocker run $(DEFAULT_docker_run_args) $($n_mountargs) $n $(DEFAULT_shell)
$(foreach i,$($n_subcommands),$(eval $(call gen_image_cmd,$n,$i)))
endef
define gen_image_create
$(eval n := $(strip $1))
.touch_c_$n: $($n_create_deps)
	$Qecho "(re-)Creating container image '$n'"
	$Q(( cd $($n_PATH) && \
		echo "FROM $($n_from)" > .Dockerfile.out && \
		cat Dockerfile >> .Dockerfile.out && \
		docker build -t $n -f ./.Dockerfile.out . ) && \
	touch .touch_c_$n)
$n_create: .touch_c_$n
endef
define gen_image_delete
$(eval n := $(strip $1))
$($n_delete_deps): $n_delete
$n_delete:
	$Qecho "Deleting container image '$n'"
	$Q((cd $($n_PATH) && docker image rm $n && rm .Dockerfile.out) && rm .touch_c_$n)
endef
define gen_image_delete_null
$(eval n := $(strip $1))
$n_delete:
endef
define gen_image_cmd
$(eval n := $(strip $1))
$(eval c := $(strip $2))
$n_$c: $($n_$c_deps)
	$Qecho "Launching a '$n' container running command '$c'"
	$Qdocker run $(DEFAULT_docker_run_args) $($n_mountargs) $n $($n_$c_COMMAND)
endef

# Generate _create and _delete rules for the volume in $1.
# _create is a rule for lazy-initialization. (We're talking bind-mounts, so by
# "initializing a volume" we simply mean "creating an empty directory". We
# explicitly mount these into containers when spinning them spun up. (I.e.
# these aren't "docker volumes" in the heavyweight sense.)
# _delete requires some messing around, depending on whether the volume exists
# (we need to treat dependencies differently), otherwise whether the user
# supplied a _WILDCARD attribute and, if they did, whether it indicates that
# the volume needs to be *emptied* before deletion and, if it does, creating a
# dependency on the corresponding hook.
define gen_volume
$(eval v := $(strip $1))
$(eval $(call gen_volume_create,$v))
$(if $(wildcard vol_$v),$(eval $(call gen_volume_delete,$v)),$(eval $(call gen_volume_delete_null,$v)))
endef
define gen_volume_create
$(eval v := $(strip $1))
vol_$v_create: | $(vol_$v_create_deps)
endef
define gen_volume_delete
$(eval v := $(strip $1))
$(if $(and $($v_WILDCARD), $(wildcard vol_$v/$($v_WILDCARD))),$(eval $(call gen_volume_delete_hook,$v)),$(eval $(call gen_volume_delete_nohook,$v)))
endef
define gen_volume_delete_hook
$(eval v := $(strip $1))
$(eval c := $(strip $($v_CONTROL)))
$(if $(wildcard .touch_c_$c),$(eval $(call gen_volume_delete_hook_go,$v)),$(eval $(call gen_volume_delete_hook_fail,$v)))
endef
define gen_volume_delete_hook_go
$(eval v := $(strip $1))
$(eval c := $(strip $($v_CONTROL)))
$(eval z := $(strip $($v_COMMAND)))
$(eval $(call gen_volume_delete_nohook,$v))
vol_$v_delete: $c_$z
endef
define gen_volume_delete_nohook
$(eval v := $(strip $1))
vol_$v_delete:
	$Qecho "Deleting volume '$v'"
	$Qrm -rf vol_$v
endef
define gen_volume_delete_hook_fail
$(eval v := $(strip $1))
$(eval c := $(strip $($v_CONTROL)))
vol_$v_delete:
	$Qecho "Deleting volume '$v' requires container '$c' for cleanup"
	$Qecho "(Consider 'make $c_create'? I didn't want to force this on you.)"
	$Qexit 1
endef
define gen_volume_delete_null
$(eval v := $(strip $1))
vol_$v_delete:
endef

# Put this rule at the end of the (ultimately assembled/generated) makefile,
# so that anything the user adds to MDIRS from their side of the makefile
# will get included in the rule
define gen_mdirs
$(MDIRS):
	$Qecho "Creating bind-mountable folder '$$@'"
	$Qmkdir -p $$@
endef

#############
# Rule-time functions
#
# The combination of pre-processing (parsing all inputs and building up all the
# internal data) and post-processing (generating rules and dependencies) has
# the appearance and effect of dynamically generating "a makefile". I.e. once
# that processing is done, we are in a situation that is equivalent to
# processing a static makefile, using whatever targets and parameters were
# passed to the "make" command (or the "default" target otherwise). The
# following functions don't participate in that pre- or post-processing, but
# are called by the resulting rules as various makefile targets get invoked.
#############

# Used by the "default:" rule to display a generic image command.
define list_gen_img
$(eval c := $(strip $1))
	$Qecho "  make <image>_$c  ($(gen_img_$c_DESCRIPTION))"
endef

# Used by the "default:" rule to display a container image and its commands.
define list_img
$(eval i := $(strip $1))
	$Qecho "IMAGE: $i  ($($i_DESCRIPTION))"
$(foreach c,$($i_COMMANDS),$(call list_img_cmd,$i,$c))
endef
define list_img_cmd
$(eval i := $(strip $1))
$(eval c := $(strip $2))
	$Qecho "  make $i_$c  ($($i_$c_DESCRIPTION))"
endef

# Used by the "default:" rule to display a generic volume command.
define list_gen_vol
$(eval c := $(strip $1))
	$Qecho "  make vol_<vol>_$c  ($(gen_vol_$c_DESCRIPTION))"
endef

# Used by the "default:" rule to display a volume.
define list_vol
$(eval v := $(strip $1))
	$Qecho "VOLUME: $v  ($($v_DESCRIPTION))"
endef

