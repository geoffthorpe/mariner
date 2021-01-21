#############
# Global setup
#
# These settings can be overriden by the user's makefile, if required, at their
# risk and peril. :-)
#############

# If V is defined, don't supress the echoing of recipe code
ifndef V
	Q := @
endif

# If TRACE is defined, enable tracing
ifdef TRACE
	trace = $(info $(strip $1))
endif

$(eval TOPDIR := $(shell pwd))

$(eval MKOUT := $(TOPDIR)/.Makefile.out)

# The path of this include, version and all
$(eval MARINER_MK_PATH := $(TOPDIR)/mariner_v2.mk)

$(eval TOP_DEPS := mariner_v2.mk GNUmakefile)

$(eval DEFAULT_SHELL := /bin/sh)

$(eval DEFAULT_ARGS_FIND_DEPS := )

$(eval DEFAULT_RUNARGS_interactive := --rm -a stdin -a stdout -a stderr -i -t)
$(eval DEFAULT_RUNARGS_batch := --rm -i)
$(eval DEFAULT_COMMAND_PROFILES := interactive batch)

$(eval DEFAULT_VOLUME_OPTIONS := readwrite)

$(eval DEFAULT_VOLUME_MANAGED := true)

$(eval DEFAULT_VOLUME_SOURCE_MAP := mariner_default_volume_source_map)
define mariner_default_volume_source_map
	$(eval $(call trace,start mariner_default_source_map($1)))
	$(eval $(strip $1)_SOURCE := $(TOPDIR)/vol_$(strip $1))
	$(eval $(call trace,set $(strip $1)_SOURCE := $(TOPDIR)/vol_$(strip $1)))
	$(eval $(call trace,end mariner_default_source_map($1)))
endef

$(eval DEFAULT_VOLUME_DEST_MAP := mariner_default_volume_dest_map)
define mariner_default_volume_dest_map
	$(eval $(call trace,start mariner_default_dest_map($1)))
	$(eval $(strip $1)_DEST := /$(strip $1))
	$(eval $(call trace,set $(strip $1)_DEST := $(TOPDIR)/vol_$(strip $1)))
	$(eval $(call trace,end mariner_default_dest_map($1)))
endef

$(eval DEFAULT_IMAGE_PATH_MAP := mariner_default_image_path_map)
define mariner_default_image_path_map
	$(eval $(strip $1)_PATH := $(TOPDIR)/c_$(strip $1))
endef

$(eval DEFAULT_IMAGE_DNAME_MAP := mariner_default_image_dname_map)
define mariner_default_image_dname_map
	$(eval $(strip $1)_DNAME := $(strip $1))
endef

# At the end of rule-generation, we produce a single, lazy-initialization rule
# for all the directories that need it. This list builds up in MDIRS, and the
# user can add their own.
$(eval MDIRS :=)

####################
# Output functions #
####################

define mkout_comment
	$(file >>$(MKOUT),)
	$(file >>$(MKOUT),# $1)
endef

define mkout_header
	$(file >>$(MKOUT),)
	$(file >>$(MKOUT),########)
	$(file >>$(MKOUT),# $1)
	$(file >>$(MKOUT),########)
endef

define mkout_init
	$(eval $(call trace,start mkout_init))
	$(file >$(MKOUT),# Auto-generated makefile rules)
	$(file >>$(MKOUT),)
	$(eval $(call trace,end mkout_init))
endef

define mkout_load
	$(eval $(call trace,start mkout_load))
	include $(MKOUT)
	$(eval $(call trace,end mkout_load))
endef

# $1 is the target, $2 is the dependency, $3 is a list of variables, each of which
# represents a distinct line of the recipe (mkout_rule will indent these)
define mkout_rule
	$(eval $(call trace,start mkout_rule($1,$2,$3)))
	$(file >>$(MKOUT),)
	$(file >>$(MKOUT),$(strip $1): $(strip $2))
	$(foreach i,$(strip $3),
		$(eval $(call trace,-> $i=$($i)))
		$(file >>$(MKOUT),	$($i)))
	$(eval $(call trace,end mkout_rule($1,$2,$3)))
endef

# uniquePrefix: mlv
define mkout_long_var
	$(eval $(call trace,start mkout_long_var($1)))
	$(eval mlv := $(strip $1))
	$(file >>$(MKOUT),)
	$(file >>$(MKOUT),$(mlv) :=)
	$(foreach i,$($(mlv)),
		$(eval $(call trace,-> $i))
		$(file >>$(MKOUT),$(mlv) += $i))
	$(eval $(call trace,end mkout_long_var($1)))
endef

# The point of this routine (and the subsequent _else and _endif routines) are
# to put conditionals in the generated makefile, i.e. to avoid the condition
# being evaluated pre-expansion. (The conditional isn't there to decide on the
# makefile content that we're generating, it is supposed to be in the generated
# makefile content with the two possible outcomes, and be evaluate _there_,
# later on.) Be wary of escaping the relevant characters ("$", "#", etc) so
# they end up in the generated makefile content as intended.
# $1 is the shell command. Its stdout and stderr are redirected to /dev/null. The
#    conditional is considered TRUE if the command succeeded (zero exit code),
#    or FALSE if the command failed (non-zero exit code).
# uniquePrefix: mis
define mkout_if_shell
	$(eval $(call trace,start mkout_if_shell($1)))
	$(eval mis := $(strip $1))
	$(file >>$(MKOUT),)
	$(file >>$(MKOUT),isYES:=$$(shell $(mis) > /dev/null 2>&1 && echo YES))
	$(file >>$(MKOUT),ifeq (YES,$$(isYES)))
	$(eval $(call trace,end mkout_if_shell($1,$2,$3)))
endef
define mkout_else
	$(file >>$(MKOUT),)
	$(file >>$(MKOUT),else)
endef
define mkout_endif
	$(file >>$(MKOUT),)
	$(file >>$(MKOUT),endif)
endef

define mkout_mdirs
	$(eval $(call trace,start mkout_mdirs))
	$(eval $(call mkout_long_var,MDIRS))
	$(file >>$(MKOUT),)
	$(file >>$(MKOUT),$$(MDIRS):)
	$(file >>$(MKOUT),	$$Qecho "Creating empty directory '$$@'")
	$(file >>$(MKOUT),	$$Qmkdir -p $$@)
	$(eval $(call trace,end mkout_mdirs))
endef

#####################
# Utility functions #
#####################

# For the various verify_***() functions, $1 isn't the value to be checked, but
# the _name_ of the property that holds the value to be checked. This is
# "by-reference" to allow meaningful error messages.

# uniquePrefix: vnd
define verify_no_duplicates
	$(eval $(call trace,start verify_no_duplicates($1)))
	$(eval vndn := $(strip $1))
	$(eval vndi := $(strip $($(vndn))))
	$(eval vndo := )
	$(eval $(call trace,examining list; $(vndi)))
	$(foreach i,$(vndi),\
		$(if $(filter $i,$(vndo)),\
			$(error "Bad: duplicates in $(vndn)"),\
			$(eval vndo += $i)))
	$(eval $(call trace,end verify_no_duplicates($1)))
endef

# uniquePrefix: vloo
define verify_list_of_one
	$(eval $(call trace,start verify_list_of_one($1)))
	$(eval vloon := $(strip $1))
	$(eval vlooi := $(strip $($(vloon))))
	$(eval $(call trace,examining list; $(vlooi)))
	$(if $(filter 1,$(words $(vlooi))),,\
		$(error "Bad: $(vloon) list size != 1"))
	$(eval $(call trace,end verify_list_of_one($1)))
endef

# uniquePrefix: vil
define verify_in_list
	$(eval $(call trace,start verify_in_list($1,$2)))
	$(eval viln := $(strip $1))
	$(eval vili := $(strip $($(viln))))
	$(eval vilp := $(strip $2))
	$(eval vill := $(strip $($(vilp))))
	$(eval $(call trace,examining item; $(vili)))
	$(eval $(call trace,examining list; $(vill)))
	$(eval vilx := $(filter $(vill),$(vili)))
	$(eval vily := $(filter $(vili),$(vilx)))
	$(if $(vily),,$(error "Bad: $(viln) is not in $(vilp)"))
	$(eval $(call trace,end verify_in_list($1,$2)))
endef

# uniquePrefix: vnil
define verify_not_in_list
	$(eval $(call trace,start verify_not_in_list($1,$2)))
	$(eval vniln := $(strip $1))
	$(eval vnili := $(strip $($(vniln))))
	$(eval vnilp := $(strip $2))
	$(eval vnill := $(strip $($(vnilp))))
	$(eval $(call trace,examining item; $(vnili)))
	$(eval $(call trace,examining list; $(vnill)))
	$(eval vnilx := $(filter $(vnill),$(vnili)))
	$(eval vnily := $(filter $(vnili),$(vnilx)))
	$(if $(vnily),$(error "Bad: $(vniln) is in $(vnilp)"))
	$(eval $(call trace,end verify_not_in_list($1,$2)))
endef

# uniquePrefix: vail
define verify_all_in_list
	$(eval $(call trace,start verify_all_in_list($1,$2)))
	$(eval vailn := $(strip $1))
	$(eval vaili := $(strip $($(vailn))))
	$(eval vailp := $(strip $2))
	$(eval vaill := $(strip $($(vailp))))
	$(foreach i,$(vaili),
		$(eval $(call trace,examining item; $(i)))
		$(eval $(call verify_in_list,i,$(vailp))))
	$(eval $(call trace,end verify_all_in_list($1,$2)))
endef

# uniquePrefix: vne
define verify_not_empty
	$(eval $(call trace,start verify_not_empty($1)))
	$(eval vnen := $(strip $1))
	$(eval vnei := $(strip $($(vnen))))
	$(eval $(call trace,examining value; $(vnei)))
	$(if $(vnei),,$(error "Bad: $(vnen) should be non-empty"))
	$(eval $(call trace,end verify_not_empty($1)))
endef

# uniquePrefix: vooo
define verify_one_or_other
	$(eval $(call trace,start verify_one_or_other($1,$2,$3)))
	$(eval vooon := $(strip $1))
	$(eval voooi := $(strip $($(vooon))))
	$(eval vooo1 := $(strip $2))
	$(eval vooo2 := $(strip $3))
	$(eval voooA := $(filter $(vooo1),$(voooi))) # Is it A?
	$(eval voooB := $(filter $(vooo2),$(voooi))) # Is it B?
	$(eval $(call trace,examining value; $(voooi)))
	$(if $(and $(voooA),$(voooB)),$(error "WTF? Bug?")) # Impossible
	$(if $(or $(voooA),$(voooB)),,\
		$(error "Bad: $(vooon) should be $(vooo1) or $(vooo2)"))
	$(eval $(call trace,end verify_one_or_other($1)))
endef

define verify_valid_BOOL
	$(eval $(call trace,start verify_valid_BOOL($1)))
	$(eval $(call verify_one_or_other,$1,true,false))
	$(eval $(call trace,end verify_valid_BOOL($1)))
endef
BOOL_is_true = $(filter true,$(strip $1))
BOOL_is_false = $(filter false,$(strip $1))

define verify_valid_OPTIONS
	$(eval $(call trace,start verify_valid_OPTIONS($1)))
	$(eval $(call verify_one_or_other,$1,readonly,readwrite))
	$(eval $(call trace,end verify_valid_OPTIONS($1)))
endef
OPTIONS_is_readonly = $(filter readonly,$(strip $1))
OPTIONS_is_readwrite = $(filter readwrite,$(strip $1))

# uniquePrefix: vvP
define verify_valid_PROFILE
	$(eval $(call trace,start verify_valid_PROFILE($1)))
	$(eval vvP := $(strip $1))
	$(if $(DEFAULT_RUNARGS_$(vvP)),,
		$(error "Bad: $(vvP) is not a valid command profile"))
	$(eval $(call trace,end verify_valid_PROFILE($1)))
endef

# uniquePrefix: vvPs
define verify_valid_PROFILES
	$(eval $(call trace,start verify_valid_PROFILES($1)))
	$(eval vvPs := $(strip $1))
	$(eval vvPsl := $($(vvPs)))
	$(eval $(call trace,examining list $(vvPsl)))
	$(foreach i,$(vvPsl),
		$(eval $(call verify_valid_PROFILE,$i)))
	$(eval $(call trace,end verify_valid_PROFILES($1)))
endef

# uniquePrefix: sie
define set_if_empty
	$(eval $(call trace,start set_if_empty($1,$2)))
	$(eval sien := $(strip $1))
	$(eval siei := $(strip $($(sien))))
	$(eval siea := $(strip $2))
	$(eval $(call trace,previous value of $(sien)=$(siei)))
	$(if $(siei),,$(eval $(sien) := $(siea)))
	$(eval siei := $(strip $($(sien))))
	$(eval $(call trace,new value of $(sien)=$(siei)))
	$(eval $(call trace,end set_if_empty($1,$2)))
endef

# uniquePrefix: mie
define map_if_empty
	$(eval $(call trace,start map_if_empty($1,$2,$3)))
	$(eval mien := $(strip $1))
	$(eval miei := $(strip $($(mien))))
	$(eval miea := $(strip $2))
	$(eval mieb := $(strip $3))
	$(eval $(call trace,previous value of $(mien)=$(miei)))
	$(if $(miei),,
		$(eval $(call trace,mapping $(mieb) -> $(miea)))
		$(eval $(call $(miea),$(mieb))))
	$(eval miei := $(strip $($(mien))))
	$(eval $(call trace,new value of $(mien)=$(miei)))
	$(eval $(call trace,end map_if_empty($1,$2,$3)))
endef

# uniquePrefix: ls
define list_subtract
	$(eval $(call trace,start list_subtract($1,$2)))
	$(eval lsX := $(strip $1))
	$(eval lsA := $(strip $($(lsX))))
	$(eval lsY := $(strip $2))
	$(eval lsB := $(strip $($(lsY))))
	$(eval $(call trace,current value of $(lsX)=$(lsA)))
	$(eval $(call trace,current value of $(lsY)=$(lsB)))
	$(eval $(lsX) := $(filter-out $(lsB),$(lsA)))
	$(eval $(call trace,new value of $(lsX)=$($(lsX))))
	$(eval $(call trace,end list_subtract($1,$2)))
endef

# This one is curious. $1 is the name of an IMAGE that _EXTENDS another. We
# grow the parent's _EXTENDED_BY property (which tracks "ancestors") with the
# name of the child and everything in the child's _EXTENDED_BY property,
# eliminating duplicates as we go (must be idempotent). In doing so, we always
# check that the parent doesn't find itself being one of its own ancestors -
# this is what detects circular deps.
#uniquePrefix: meb
define mark_extended_by
	$(eval $(call trace,start mark_extended_by($1)))
	$(eval mebX := $(strip $1))
	$(eval mebA := $(strip $($(mebX)_EXTENDED_BY)))
	$(eval mebY := $(strip $($(mebX)_EXTENDS)))
	$(eval mebB := $(strip $($(mebY)_EXTENDED_BY)))
	$(eval $(call trace,current value of $(mebX)_EXTENDED_BY=$(mebA)))
	$(eval $(call trace,current value of $(mebX)_EXTENDS=$(mebY)))
	$(eval $(call trace,current value of $(mebY)_EXTENDED_BY=$(mebB)))
	$(eval $(mebY)_EXTENDED_BY += $(mebX) $(mebA))
	$(eval $(call list_deduplicate,$(mebY)_EXTENDED_BY))
	$(eval $(call trace,new value of $(mebY)_EXTENDED_BY=$($(mebY)_EXTENDED_BY)))
	$(eval $(call trace,check for circular deps))
	$(eval $(call verify_not_in_list,$(mebX)_EXTENDS,$(mebY)_EXTENDED_BY))
	$(eval $(call trace,end mark_extended_by($1,$2)))
endef

# Given a volume source ($2), destination ($3), and options ($4), produce the
# required argument to "docker run" and append it to the given variable ($1).
# Note, we only support one OPTIONS, which is synthetically "readonly" or
# "readwrite". This needs to be converted to "readonly" or <empty>,
# respectively.
# uniquePrefix: mma
define make_mount_args
	$(eval $(call trace,start make_mount_args($1,$2,$3,$4)))
	$(eval mmav := $(strip $1))
	$(eval mmas := $(strip $2))
	$(eval mmad := $(strip $3))
	$(eval mmao := $(strip $4))
	$(eval mmar := --mount type=bind,source=$(mmas),destination=$(mmad))
	$(if $(call OPTIONS_is_readonly,$(mmao)),
		$(eval mmar := $(mmar),readonly))
	$(eval $(call trace,-> $(mmav) += $(mmar)))
	$(eval $(mmav) += $(mmar))
	$(eval $(call trace,end make_mount_args($1,$2,$3,$4)))
endef

##################################################
# The singular API function that does everything #
##################################################

define do_mariner
	$(eval $(call mkout_init))
	$(eval $(call trace,start do_mariner()))
	$(eval $(call do_sanity_checks))
	$(eval $(call process_volumes))
	$(eval $(call process_commands))
	$(eval $(call process_images))
	$(eval $(call process_2_image_command))
	$(eval $(call process_2_image_volume))
	$(eval $(call process_3_image_volume_command))
	$(eval $(call gen_rules_volumes))
	$(eval $(call gen_rules_images))
	$(eval $(call gen_rules_image_commands))
	$(eval $(call mkout_mdirs))
	$(eval $(call trace,end do_mariner()))
	$(eval $(call mkout_load))
endef

########################################
# Process VOLUMES and parse attributes #
########################################

define process_volumes
	$(eval $(call trace,start process_volumes()))
	$(eval $(call verify_no_duplicates,VOLUMES))
	$(eval $(call trace,about to loop over VOLUMES=$(VOLUMES)))
	$(foreach i,$(VOLUMES),$(eval $(call process_volume,$i)))
	$(eval $(call trace,end process_volumes()))
endef

# uniquePrefix: tv
define trace_volume
	$(eval $(call trace,start trace_volume($1)))
	$(eval tvv := $(strip $1))
	$(eval $(call trace,_DESCRIPTION=$($(tvv)_DESCRIPTION)))
	$(eval $(call trace,_SOURCE=$($(tvv)_SOURCE)))
	$(eval $(call trace,_DEST=$($(tvv)_DEST)))
	$(eval $(call trace,_OPTIONS=$($(tvv)_OPTIONS)))
	$(eval $(call trace,_MANAGED=$($(tvv)_MANAGED)))
	$(eval $(call trace,end trace_volume()))
endef

# uniquePrefix: pv
define process_volume
	$(eval $(call trace,start process_volume($1)))
	$(eval pvv := $(strip $1))
	$(eval $(call trace_volume, $(pvv)))
	# If <vol>_SOURCE is empty, inherit from the default map
	$(eval $(call trace,examine _SOURCE))
	$(eval $(call map_if_empty, \
		$(pvv)_SOURCE, \
		$(DEFAULT_VOLUME_SOURCE_MAP), \
		$(pvv)))
	# If <vol>_DEST is empty, inherit from the default map
	$(eval $(call trace,examine _DEST))
	$(eval $(call map_if_empty, \
		$(pvv)_DEST, \
		$(DEFAULT_VOLUME_DEST_MAP), \
		$(pvv)))
	# If <vol>_OPTIONS is empty, inherit from the default
	$(eval $(call trace,examine _OPTIONS))
	$(eval $(call set_if_empty, \
		$(pvv)_OPTIONS, \
		$(DEFAULT_VOLUME_OPTIONS)))
	# If <vol>_MANAGED is empty, inherit from the default
	$(eval $(call trace,examine _MANAGED))
	$(eval $(call set_if_empty, \
		$(pvv)_MANAGED, \
		$(DEFAULT_VOLUME_MANAGED)))
	# Check the values are legit
	$(eval $(call trace,check attribs have legit values))
	$(eval $(call verify_valid_OPTIONS,$(pvv)_OPTIONS))
	$(eval $(call verify_valid_BOOL,$(pvv)_MANAGED))
	$(eval $(call verify_not_empty,$(pvv)_SOURCE))
	$(eval $(call verify_not_empty,$(pvv)_DEST))
	$(eval $(call trace_volume, $(pvv)))
	$(eval $(call trace,end process_volume()))
endef

#########################################
# Process COMMANDS and parse attributes #
#########################################

define process_commands
	$(eval $(call trace,start process_commands()))
	$(eval $(call verify_no_duplicates,COMMANDS))
	$(if $(filter $(COMMANDS),create),
		$(error "Bad: attempt to user-define 'create' COMMAND"))
	$(if $(filter $(COMMANDS),delete),
		$(error "Bad: attempt to user-define 'delete' COMMAND"))
	$(if $(filter-out $(COMMANDS),shell),
		$(eval $(call trace,adding _shell generic))
		$(eval COMMANDS += shell)
		$(eval $(call trace,-> COMMANDS=$(COMMANDS)))
		$(eval shell_COMMAND ?= $(DEFAULT_SHELL))
		$(eval shell_DESCRIPTION ?= start $(shell_COMMAND) in a container)
		$(eval shell_PROFILES ?= interactive))
	$(eval $(call trace,about to loop over COMMANDS=$(COMMANDS)))
	$(foreach i,$(strip $(COMMANDS)),
		$(eval $(call process_command,$i)))
	$(eval $(call trace,end process_commands()))
endef

# uniquePrefix: tc
define trace_command
	$(eval $(call trace,start trace_command($1)))
	$(eval tcv := $(strip $1))
	$(eval $(call trace,_DESCRIPTION=$($(tcv)_DESCRIPTION)))
	$(eval $(call trace,_COMMAND=$($(tcv)_COMMAND)))
	$(eval $(call trace,_DNAME=$($(tcv)_DNAME)))
	$(eval $(call trace,_PROFILES=$($(tcv)_PROFILES)))
	$(eval $(call trace,end trace_command()))
endef

# uniquePrefix: pc
define process_command
	$(eval $(call trace,start process_command($1)))
	$(eval pcv := $(strip $1))
	$(eval $(call trace_command, $(pcv)))
	# If _COMMAND is empty, explode
	$(eval $(call verify_not_empty, $(pcv)_COMMAND))
	# _PROFILES has a default, and needs validation
	$(eval $(call set_if_empty,$(pcv)_PROFILES,$(DEFAULT_COMMAND_PROFILES)))
	$(eval $(call verify_valid_PROFILES,$(pcv)_PROFILES))
	$(eval $(call trace_command,$(pcv)))
	$(eval $(call trace,end process_command()))
endef

#######################################
# Process IMAGES and parse attributes #
#######################################

define process_images
	$(eval $(call trace,start process_images()))
	$(eval $(call verify_no_duplicates,IMAGES))
	$(eval $(call trace,about to loop over IMAGES=$(IMAGES)))
	$(foreach i,$(IMAGES),$(eval $(call process_image,$i,)))
	$(eval $(call trace,end process_images()))
endef

# uniquePrefix: ti
define trace_image
	$(eval $(call trace,start trace_image($1)))
	$(eval tiv := $(strip $1))
	$(eval $(call trace,_DESCRIPTION=$($(tiv)_DESCRIPTION)))
	$(eval $(call trace,_TERMINATES=$($(tiv)_TERMINATES)))
	$(eval $(call trace,_EXTENDS=$($(tiv)_EXTENDS)))
	$(eval $(call trace,_PATH=$($(tiv)_PATH)))
	$(eval $(call trace,_DNAME=$($(tiv)_DNAME)))
	$(eval $(call trace,_PATH_MAP=$($(tiv)_PATH_MAP)))
	$(eval $(call trace,_DNAME_MAP=$($(tiv)_DNAME_MAP)))
	$(eval $(call trace,_VOLUMES=$($(tiv)_VOLUMES)))
	$(eval $(call trace,_UNVOLUMES=$($(tiv)_UNVOLUMES)))
	$(eval $(call trace,_COMMANDS=$($(tiv)_COMMANDS)))
	$(eval $(call trace,_UNCOMMANDS=$($(tiv)_UNCOMMANDS)))
	$(eval $(call trace,end trace_image($1)))
endef

# Note, this is an exception because it has to be reentrant. I.e. it calls
# itself, yet local variables are global, so how do we avoid self-clobber? The
# uniquePrefix stuff only makes local variables function-specific, but if the
# same function is present more than once in the same call-stack, we're toast.
# So the trick to deal with this is;
# - we use an initially-empty call parameter that gets appended to the
#   "uniquePrefix".
# - when calling ourselves, we append a character to that call parameter.
# - upon return from recursion, re-init the local uniquePrefix (to un-clobber
#   it).
# Also, just to be sexy, mark all images with a list of images that depend on
# it, call it _EXTENDED_BY. If an image is extended by itself, that indicates a
# circular dependency, so we can tell the user what the problem is rather than
# looping until we hit a process limit, an OOM-killer, or the heat-death of the
# universe.
# uniquePrefix: pi
define process_image
	$(eval $(call trace,start process_image($1,$2)))
	$(eval pip := pi$(strip $2))
	$(eval $(call trace,using uniqueness prefix $(pip)))
	$(eval $(pip)v := $(strip $1))
	$(eval $(call trace_image, $($(pip)v)))
	# Exactly one of <vol>_TERMINATES or <vol>_EXTENDS should be non-empty
	$(eval $(call trace,examine _TERMINATES and _EXTENDS))
	$(eval $($(pip)v)_tmp := $($($(pip)v)_TERMINATES) $($($(pip)v)_EXTENDS))
	$(eval $(call trace,set $($(pip)v)_tmp to _TERMINATES + _EXTENDS))
	$(eval $(call verify_list_of_one,$($(pip)v)_tmp))
	# Now, if _EXTENDS, we want to recurse into the image we depend on, so
	# it can sort out its attributes, rinse and repeat.
	$(if $($($(pip)v)_EXTENDS),
		$(eval $(call trace,verify $($(pip)v)_EXTENDS is known))
		$(eval $(call verify_in_list,$($(pip)v)_EXTENDS,IMAGES))
		$(eval $(call trace,grow _EXTENDED_BY, detect circular deps))
		$(eval $(call mark_extended_by,$($(pip)v)))
		$(eval $(call trace,recurse into $($(pip)v)_EXTENDS))
		$(eval $(call trace,pre-recurse; pip=$(pip)))
		$(eval $(call process_image,
			$($($(pip)v)_EXTENDS),
			$(strip $2)x))
		$(eval pip := pi$(strip $2))
		$(eval $(call trace,post-recurse; pip=$(pip)))
		$(eval $(call trace,examine _PATH_MAP (in _EXTENDS case)))
		$(eval $(call set_if_empty,
			$($(pip)v)_PATH_MAP,
			$($($($(pip)v)_EXTENDS)_PATH_MAP)))
		$(eval $(call trace,examine _DNAME_MAP (in _EXTENDS case)))
		$(eval $(call set_if_empty,
			$($(pip)v)_DNAME_MAP,
			$($($($(pip)v)_EXTENDS)_DNAME_MAP)))
		$(eval $(call trace,examine _VOLUMES (in _EXTENDS case)))
		$(eval $(call set_if_empty,
			$($(pip)v)_VOLUMES,
			$($($($(pip)v)_EXTENDS)_VOLUMES)))
		$(eval $(call trace,examine _COMMANDS (in _EXTENDS case)))
		$(eval $(call set_if_empty,
			$($(pip)v)_COMMANDS,
			$($($($(pip)v)_EXTENDS)_COMMANDS)))
	,
		$(eval $(call trace,examine _PATH_MAP (in _TERMINATES case)))
		$(eval $(call set_if_empty,
			$($(pip)v)_PATH_MAP,
			$(DEFAULT_IMAGE_PATH_MAP)))
		$(eval $(call trace,examine _DNAME_MAP (in _TERMINATES case)))
		$(eval $(call set_if_empty,
			$($(pip)v)_DNAME_MAP,
			$(DEFAULT_IMAGE_DNAME_MAP)))
		$(eval $(call trace,examine _VOLUMES (in _TERMINATES case)))
		$(eval $(call set_if_empty,
			$($(pip)v)_VOLUMES,))
		$(eval $(call trace,examine _COMMANDS (in _TERMINATES case)))
		$(eval $(call set_if_empty,
			$($(pip)v)_COMMANDS,))
		$(if $(filter-out $($($(pip)v)_COMMANDS),shell),
			$(eval $(call trace,adding _shell generic (in _TERMINATES case)))
			$(eval $(call trace,before:$($(pip)v)_COMMANDS=$($($(pip)v)_COMMANDS)))
			$(eval $($(pip)v)_COMMANDS += shell)
			$(eval $(call trace, after:$($(pip)v)_COMMANDS=$($($(pip)v)_COMMANDS)))
			)
	)
	$(eval $(call trace,examine _PATH))
	$(eval $(call map_if_empty,
		$($(pip)v)_PATH,
		$($($(pip)v)_PATH_MAP),
		$($(pip)v)))
	$(eval $(call trace,examine _DNAME))
	$(eval $(call map_if_empty,
		$($(pip)v)_DNAME,
		$($($(pip)v)_DNAME_MAP),
		$($(pip)v)))
	$(eval $(call trace,examine _UNVOLUMES))
	$(eval $(call list_subtract,
		$($(pip)v)_VOLUMES,
		$($(pip)v)_UNVOLUMES))
	$(eval $(call trace,examine _UNCOMMANDS))
	$(eval $(call list_subtract,
		$($(pip)v)_COMMANDS,
		$($(pip)v)_UNCOMMANDS))
	$(eval $(call trace,check _VOLUMES for legit values))
	$(eval $(call verify_all_in_list,$($(pip)v)_VOLUMES,VOLUMES))
	$(eval $(call trace,check _COMMANDS for legit values))
	$(eval $(call verify_all_in_list,$($(pip)v)_COMMANDS,COMMANDS))
	$(eval $(call trace_image, $($(pip)v)))
	$(eval $(call trace,end process_image($1,$2)))
endef

##########################################
# Parse IMAGE_COMMAND 2-tuple attributes #
##########################################

define process_2_image_command
	$(eval $(call trace,start process_2_image_command()))
	$(foreach i,$(IMAGES),$(foreach j,$($i_COMMANDS),
		$(eval $(call process_2ic,$i,$j))))
	$(eval $(call trace,end process_2_image_command()))
endef

# uniquePrefix: t2ic
define trace_2ic
	$(eval $(call trace,start trace_2ic($1)))
	$(eval t2ic := $(strip $1))
	$(eval $(call trace,_COMMAND=$($(t2ic)_COMMAND)))
	$(eval $(call trace,_DNAME=$($(t2ic)_DNAME)))
	$(eval $(call trace,_VOLUMES=$($(t2ic)_VOLUMES)))
	$(eval $(call trace,_UNVOLUMES=$($(t2ic)_UNVOLUMES)))
	$(eval $(call trace,_PROFILES=$($(t2ic)_PROFILES)))
	$(eval $(call trace,end trace_2ic($1)))
endef

# uniquePrefix: p2ic
define process_2ic
	$(eval $(call trace,start process_2ic($1,$2)))
	$(eval p2icI := $(strip $1))
	$(eval p2icC := $(strip $2))
	$(eval p2ic2 := $(p2icI)_$(p2icC))
	$(eval $(call trace_2ic, $(p2ic2)))
	$(eval $(call trace,examine _COMMAND))
	$(eval $(call set_if_empty,$(p2ic2)_COMMAND,$($(p2icC)_COMMAND)))
	$(eval $(call trace,examine _DNAME))
	$(eval $(call set_if_empty,$(p2ic2)_DNAME,$($(p2icC)_DNAME)))
	$(eval $(call trace,examine _VOLUMES))
	$(eval $(call set_if_empty,$(p2ic2)_VOLUMES,$($(p2icI)_VOLUMES)))
	$(eval $(call trace,examine _UNVOLUMES))
	$(eval $(call list_subtract,$(p2ic2)_VOLUMES,$(p2ic2)_UNVOLUMES))
	$(eval $(call trace,examine _PROFILES))
	$(eval $(call set_if_empty,$(p2ic2)_PROFILES,$($(p2icC)_PROFILES)))
	$(eval $(call verify_valid_PROFILES,$(p2ic2)_PROFILES))
	$(eval $(call trace,set backrefs _IMAGE and _COMMAND))
	$(eval $(p2ic2)_B_IMAGE := $(p2icI))
	$(eval $(p2ic2)_B_COMMAND := $(p2icC))
	$(eval $(call trace_2ic, $(p2ic2)))
	$(eval $(call trace,end process_2ic($1,$2)))
endef

#########################################
# Parse IMAGE_VOLUME 2-tuple attributes #
#########################################

define process_2_image_volume
	$(eval $(call trace,start process_2_image_volume()))
	$(foreach i,$(IMAGES),$(foreach j,$($i_VOLUMES),
		$(eval $(call process_2iv,$i,$j))))
	$(eval $(call trace,end process_2_image_volume()))
endef

# uniquePrefix: t2iv
define trace_2iv
	$(eval $(call trace,start trace_2iv($1)))
	$(eval t2iv := $(strip $1))
	$(eval $(call trace,_DEST=$($(t2iv)_DEST)))
	$(eval $(call trace,_OPTIONS=$($(t2iv)_OPTIONS)))
	$(eval $(call trace,end trace_2iv($1)))
endef

# Note, the default handling (of the _DEST attribute) is dependent on whether
# the underlying image _EXTENDS another image. If it does, we have to recurse
# all the way in, in order for default-inheritence to always work backwards
# from the _TERMINATES layer back up the _EXTENDS chain. This means we need to
# play the same reentrancy trick we played in process_image.
# Fortunately we do not have to reproduce the buildup of _EXTENDED_BY
# attributes to handle loop detection, as those have already been
# detected/caught. Likewise, we don't need to do error detection (e.g. that
# $i_EXTENDS points to something legit in IMAGES) because that too has already
# happened.
# uniquePrefix: p2iv
define process_2iv
	$(eval $(call trace,start process_2iv($1,$2,$3)))
	$(eval p2iv := p2iv$(strip $3))
	$(eval $(call trace,using uniquess prefix $(p2iv)))
	$(eval $(p2iv)I := $(strip $1))
	$(eval $(p2iv)V := $(strip $2))
	$(eval $(p2iv)2 := $($(p2iv)I)_$($(p2iv)V))
	$(eval $(call trace_2iv, $($(p2iv)2)))
	# If _EXTENDS, recurse to the image-volume 2-tuple for the image that
	# is the immediate ancestor of this one. We go all the way to the
	# _TERMINATES case, and then do default-handling "on the way back" up
	# that dependency chain.
	$(if $($($(p2iv)I)_EXTENDS),
		$(eval $(call trace,recurse into $($($(p2iv)I)_EXTENDS)))
		$(eval $(call trace,pre-recurse; p2iv=$(p2iv)))
		$(eval $(call process_2iv,
			$($($(p2iv)I)_EXTENDS),
			$($(p2iv)V),
			$(strip $3)x))
		$(eval p2iv := p2iv$(strip $3))
		$(eval $(call trace,post-recurse; p2iv=$(p2iv)))
		$(eval $(call trace,examine _DEST))
		$(eval $(call set_if_empty,
			$($(p2iv)2)_DEST,
			$($($($(p2iv)I)_EXTENDS)_$($(p2iv)V)_DEST)))
		$(eval $(call trace,examine _OPTIONS))
		$(eval $(call set_if_empty,
			$($(p2iv)2)_OPTIONS,
			$($($($(p2iv)I)_EXTENDS)_$($(p2iv)V)_OPTIONS)))
	,
		$(eval $(call trace,examine _DEST))
		$(eval $(call set_if_empty,
			$($(p2iv)2)_DEST,
			$($($(p2iv)V)_DEST)))
		$(eval $(call trace,examine _OPTIONS))
		$(eval $(call set_if_empty,
			$($(p2iv)2)_OPTIONS,
			$($($(p2iv)V)_OPTIONS)))
		$(eval $(call verify_valid_OPTIONS,$($(p2iv)2)_OPTIONS))
	)
	$(eval $(call trace,set backrefs _IMAGE and _VOLUME))
	$(eval $($(p2iv)2)_B_IMAGE := $($(p2iv)I))
	$(eval $($(p2iv)2)_B_VOLUME := $($(p2iv)V))
	$(eval $(call trace_2iv, $($(p2iv)2)))
	$(eval $(call trace,end process_2iv($1,$2,$3)))
endef

###########################################
# IMAGE_VOLUME_COMMAND 3-tuple attributes #
###########################################

define process_3_image_volume_command
	$(eval $(call trace,start process_3_image_volume_command()))
	$(foreach i,$(IMAGES),
		$(foreach j,$($i_VOLUMES),
			$(foreach k,$($i_COMMANDS),
				$(eval $(call process_3ivc,$i,$j,$k)))))
	$(eval $(call trace,end process_3_image_volume_command()))
endef

# uniquePrefix: t3ivc
define trace_3ivc
	$(eval $(call trace,start trace_3ivc($1)))
	$(eval t3ivc := $(strip $1))
	$(eval $(call trace,_DEST=$($(t3ivc)_DEST)))
	$(eval $(call trace,_OPTIONS=$($(t3ivc)_OPTIONS)))
	$(eval $(call trace,end trace_3ivc($1)))
endef

# The processing here is quite analogous to the 2iv equivalent.
# uniquePrefix: p3ivc
define process_3ivc
	$(eval $(call trace,start process_3ivc($1,$2,$3,$4)))
	$(eval p3ivc := p3ivc$(strip $4))
	$(eval $(call trace,using uniquess prefix $(p3ivc)))
	$(eval $(p3ivc)I := $(strip $1))
	$(eval $(p3ivc)V := $(strip $2))
	$(eval $(p3ivc)C := $(strip $3))
	$(eval $(p3ivc)2 := $($(p3ivc)I)_$($(p3ivc)V))
	$(eval $(p3ivc)3 := $($(p3ivc)I)_$($(p3ivc)V)_$($(p3ivc)C))
	$(eval $(call trace_3ivc, $($(p3ivc)3)))
	# If _EXTENDS, recurse to the image-volume-command 3-tuple for the
	# image that is the immediate ancestor of this one. We go all the way
	# to the _TERMINATES case, and then do default-handling "on the way
	# back" up that dependency chain.
	$(if $($($(p3ivc)I)_EXTENDS),
		$(eval $(call trace,recurse into $($($(p3ivc)I)_EXTENDS)))
		$(eval $(call trace,pre-recurse; p3ivc=$(p3ivc)))
		$(eval $(call process_3ivc,
			$($($(p3ivc)I)_EXTENDS),
			$($(p3ivc)V),
			$($(p3ivc)C),
			$(strip $4)x))
		$(eval p3ivc := p3ivc$(strip $4))
		$(eval $(call trace,post-recurse; p3ivc=$(p3ivc)))
		$(eval $(call trace,examine _DEST))
		$(eval $(call set_if_empty,
			$($(p3ivc)3)_DEST,
			$($($($(p3ivc)I)_EXTENDS)_$($(p3ivc)V)_DEST)))
		$(eval $(call set_if_empty,
			$($(p3ivc)3)_DEST,
			$($($(p3ivc)2)_DEST)))
		$(eval $(call trace,examine _OPTIONS))
		$(eval $(call set_if_empty,
			$($(p3ivc)3)_OPTIONS,
			$($($($(p3ivc)I)_EXTENDS)_$($(p3ivc)V)_OPTIONS)))
	,
		$(eval $(call trace,examine _DEST))
		$(eval $(call set_if_empty,
			$($(p3ivc)3)_DEST,
			$($($(p3ivc)2)_DEST)))
		$(eval $(call trace,examine _OPTIONS))
		$(eval $(call set_if_empty,
			$($(p3ivc)3)_OPTIONS,
			$($($(p3ivc)2)_OPTIONS)))
		$(eval $(call verify_valid_OPTIONS,$($(p3ivc)3)_OPTIONS))
	)
	$(eval $(call trace,set backrefs _IMAGE, _VOLUME, and _COMMAND))
	$(eval $($(p3ivc)3)_B_IMAGE := $($(p3ivc)I))
	$(eval $($(p3ivc)3)_B_VOLUME := $($(p3ivc)V))
	$(eval $($(p3ivc)3)_B_COMMAND := $($(p3ivc)C))
	$(eval $(call trace_3ivc, $($(p3ivc)3)))
	$(eval $(call trace,end process_3ivc($1,$2,$3,$4)))
endef

#################################
# Generate 1-tuple VOLUME rules #
#################################

define gen_rules_volumes
	$(eval $(call trace,start gen_rules_volumes()))
	$(eval $(call verify_no_duplicates,VOLUMES))
	$(eval $(call mkout_header,VOLUMES))
	$(eval $(call trace,about to loop over VOLUMES=$(VOLUMES)))
	$(foreach i,$(VOLUMES),$(eval $(call gen_rules_volume,$i)))
	$(eval $(call trace,end gen_rules_volumes()))
endef

# Rules; _create, _delete
# uniquePrefix: grv
define gen_rules_volume
	$(eval $(call trace,start gen_rules_volume($1)))
	$(eval grv := $(strip $1))
	$(if $(call BOOL_is_true,$($(grv)_MANAGED)),
		$(eval $(call trace,$(grv) is MANAGED))
		$(eval $(call mkout_comment,Rules for MANAGED volume $(grv)))
		$(eval grvx := $$Qrmdir $($(grv)_SOURCE))
		$(eval MDIRS += $($(grv)_SOURCE))
		$(eval $(call mkout_rule,$(grv)_create,| $($(grv)_SOURCE),))
		$(eval $(call mkout_rule,$(grv)_delete,,grvx))
	,
		$(eval $(call trace,$(grv) is UNMANAGED))
		$(eval $(call mkout,comment,No rules for UNMANAGED volume $(grv))))
	$(eval $(call trace,end gen_rules_volume($1)))
endef

################################
# Generate 1-tuple IMAGE rules #
################################

define gen_rules_images
	$(eval $(call trace,start gen_rules_images()))
	$(eval $(call verify_no_duplicates,IMAGES))
	$(eval $(call mkout_header,IMAGES))
	$(eval $(call trace,about to loop over IMAGES=$(IMAGES)))
	$(foreach i,$(IMAGES),$(eval $(call gen_rules_image,$i)))
	$(eval $(call trace,end gen_rules_images()))
endef

# Rules; _create, _delete
#
# .Dockerfile_$i :depends: on $(_PATH)/Dockerfile
#   -> :recipe: recreate .Dockerfile_$i
#
# if _EXTENDS
#   .touch_$i :depends: on .touch_$($i_EXTENDS)
#
# if _TERMINATES
#   .touch_$i :depends: on $(TOP_DEPS)
#
# .touch_$i :depends: on .Dockerfile_$i
# .touch_$i :depends: on "find _PATH"
#   -> :recipe: "docker build" && touch .touch_$i
#
# $i_create :depends: on .touch_$i
#
# if :exists: .touch_$i
#   if $i_EXTENDS
#       $($i_EXTENDS)_delete :depends: on $i_delete
#
#   $i_delete:
#     -> :recipe: "docker image rm && rm .Dockerfile_$i && rm .touch_$i
# else
#   $i_delete:
#
# uniquePrefix: gri
define gen_rules_image
	$(eval $(call trace,start gen_rules_image($1)))
	$(eval gri := $(strip $1))
	$(eval $(call mkout_comment,Rules for IMAGE $(gri)))
	$(eval $(gri)_DOUT := $(TOPDIR)/.Dockerfile_$(gri))
	$(eval $(gri)_DIN := $($(gri)_PATH)/Dockerfile)
	$(eval $(gri)1 := \
$$Qecho "Updating .Dockerfile_$(gri)")
	$(eval $(gri)2 := \
$$Qecho "FROM $(strip $($(gri)_EXTENDS) $($(gri)_TERMINATES))" > $($(gri)_DOUT))
	$(eval $(gri)3 := \
$$Qcat $($(gri)_PATH)/Dockerfile >> $($(gri)_DOUT))
	$(eval $(call mkout_rule,$($(gri)_DOUT),$($(gri)_DIN),$(gri)1 $(gri)2 $(gri)3))
	$(if $($(gri)_EXTENDS),
		$(eval $(call mkout_rule,.touch_$(gri),.touch_$($(gri)_EXTENDS),))
	,
		$(eval $(call mkout_rule,.touch_$(gri),$(TOP_DEPS),))
	)
	$(eval $(call mkout_rule,.touch_$(gri),$($(gri)_DOUT),))
	$(eval $(call trace,set $(gri)_PATH_DEPS from $($(gri)_PATH)))
	$(eval $(gri)_PATH_DEPS := $(shell find $($(gri)_PATH)))
	$(eval $(call mkout_long_var,$(gri)_PATH_DEPS))
	$(eval $(call mkout_rule,.touch_$(gri),$$($(gri)_PATH_DEPS),))
	$(eval $(gri)1 := \
$$Qecho "(re-)Creating container image $(gri)")
	$(eval $(gri)2 := \
$$Q(cd $($(gri)_PATH) && docker build -t $(gri) -f $($(gri)_DOUT) . ))
	$(eval $(gri)3 := \
$$Qtouch .touch_$(gri))
	$(eval $(call mkout_rule,.touch_$(gri),,$(gri)1 $(gri)2 $(gri)3))
	$(eval $(call mkout_rule,$(gri)_create,.touch_$(gri),))
	$(eval $(call mkout_if_shell,stat .touch_$(gri)))
	$(if $($(gri)_EXTENDS),
		$(call mkout_rule,$($(gri)_EXTENDS)_delete,$(gri)_delete,,))
	$(eval $(gri)1 := \
$$Qecho "Deleting container image $(gri)")
	$(eval $(gri)2 := \
$$Qdocker image rm $(gri))
	$(eval $(gri)3 := \
$$Qrm $($(gri)_DOUT))
	$(eval $(gri)4 := \
$$Qrm .touch_$(gri))
	$(eval $(call mkout_rule,$(gri)_delete,,$(gri)1 $(gri)2 $(gri)3 $(gri)4))
	$(eval $(call mkout_else))
	$(eval $(call mkout_rule,$(gri)_delete,,))
	$(eval $(call mkout_endif))
	$(eval $(call trace,end gen_rules_image($1)))
endef

########################################
# Generate 2-tuple IMAGE_COMMAND rules #
########################################

define gen_rules_image_commands
	$(eval $(call trace,start gen_rules_image_commands()))
	$(eval $(call mkout_header,IMAGE_COMMAND 2-tuples))
	$(foreach i,$(IMAGES),
		$(eval $(call trace,i=$i))
		$(eval $(call trace,i_COMMANDS=$($i_COMMANDS)))
		$(foreach j,$($i_COMMANDS),
			$(eval $(call gen_rules_image_command,$i,$j))))
	$(eval $(call trace,end gen_rules_image_commands()))
endef


# Rules; $1_$2 (<image>_<command>), $1_$2_$(foreach $($1_$2_PROFILES))
# Note, the 1-tuple rule-generation for images and volumes was only dependent
# on the corresponding 1-tuple processing. Things are different here. One
# 2-tuple (image/command) processing has occurred, 3-tuple image/command/volume
# processing occurs which pulls in and consolidates
# defaults/inheritence/overrides info from the 1-tuple and 2-tuple processing.
# So many of the inputs to these rules come from 3-tuple processing that
# potentially overrides the 2-tuple processing results. These are the inputs
# and which tuples they come from;
#  3ivc: DEST, OPTIONS
#   2ic: COMMAND, DNAME, VOLUMES
#    1i: PATH
#    1v: SOURCE
# Once all that is considered, we actually have to generate a rule for each
# PROFILE that's supported, and then define the generic (PROFILE-agnostic) rule
# to be an alias for the first listed PROFILE.
# uniquePrefix: gric
define gen_rules_image_command
	$(eval $(call trace,start gen_rules_image_command($1,$2)))
	$(eval grici := $(strip $1))
	$(eval gricc := $(strip $2))
	$(eval gricic := $(grici)_$(gricc))
	$(eval $(call mkout_comment,Rules for IMAGE/COMMAND $(gricic)))
	$(eval $(call trace,generating $(gricic) deps))
	$(eval $(gricic)_DEPS := $(grici)_create)
	$(eval $(gricic)_DEPS += $(foreach i,$($(gricic)_VOLUMES),$i_create))
	$(eval $(call mkout_long_var,$(gricic)_DEPS))
	$(eval $(gricic)_MOUNT_ARGS := )
	$(foreach i,$($(gricic)_VOLUMES),
		$(eval $(gricic)_MOUNT_ARGS +=
			$(eval $(call make_mount_args,
				$(gricic)_MOUNT_ARGS,
				$($i_SOURCE),
				$($(grici)_$i_$(gricc)_DEST),
				$($(grici)_$i_$(gricc)_OPTIONS)))))
	$(eval $(call mkout_long_var,$(gricic)_MOUNT_ARGS))
	$(foreach i,$($(gricic)_PROFILES),
		$(eval $(call gen_rule_image_command_profile,$(gricic),$i)))
	$(eval $(call mkout_rule,$(gricic),
		$(gricic)_$(firstword $($(gricic)_PROFILES))))
	$(eval $(call trace,end gen_rules_image_command($1,$2)))
endef

# uniquePrefix: gricp
define gen_rule_image_command_profile
	$(eval $(call trace,end gen_rule_image_command_profile($1,$2)))
	$(eval gricp2 := $(strip $1))
	$(eval gricpP := $(strip $2))
	$(eval gricpC := $(strip $($(gricp2)_COMMAND)))
	$(eval gricpBI := $(strip $($(gricp2)_B_IMAGE)))
	$(eval gricpBC := $(strip $($(gricp2)_B_COMMAND)))
	$(if $($(gricic)_DNAME),
		$(eval TMP1 := \
$$Qecho "Launching $(gricpP) container '$($(gricp2)_DNAME)'"),
		$(eval TMP1 := \
$$Qecho "Launching a '$(gricpBI)' $(gricpP) container running command ('$(gricpBC)')"))
	$(eval TMP2 := $$Qdocker run $(DEFAULT_RUNARGS_$(gricpP)) \)
	$(eval TMP3 := $$$$($(gricp2)_MOUNT_ARGS) \)
	$(eval TMP4 := $(gricpBI) \)
	$(eval TMP5 := $(gricpC))
	$(eval $(call mkout_rule,$(gricp2)_$(gricpP),$$($(gricp2)_DEPS),
		TMP1 TMP2 TMP3 TMP4 TMP5))
	$(eval $(call trace,end gen_rule_image_command_profile($1,$2)))
endef

#################
# SANITY CHECKS #
#################

# I learned a lot about weird GNU make behavior in constructing this function.
# Long story short, the final sed is necessary to avoid having the output
# (duplicate "uniquePrefix" lines from this file) getting re-expanded. In
# particular, the lines that match begin with a "#", and without the sed
# component, they "disappear".
define do_sanity_checks
	$(eval $(call trace,start do_sanity_checks))
	$(eval UID_CONFLICTS := \
		$(shell egrep "^# uniquePrefix:" $(MARINER_MK_PATH) | sort |
			uniq -d | sed 's/[\\\#]/\\&/g'))
	$(if $(strip $(UID_CONFLICTS)),
		$(info $(UID_CONFLICTS)) $(error Conflicting uniquePrefix))
	$(eval $(call trace,end do_sanity_checks))
endef