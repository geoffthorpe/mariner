# This turns a minimal debian-flavored base image into an only slightly less
# minimal one in which apt is vaguely usable.
#
# Given that this is a common first-step, I'm layering in another workaround
# for something _nasty_, timezones! The default timezone of a container image
# ends up being something like "Etc/UTC", which can give sick results if you
# end up sharing host files and timestamps with containers. (I found out the
# hard way, by running "make" in a container on a built source tree that was
# mounted from the host. Erk.) We make the feature layer dependent on the host
# /etc/timezone, copy it into the feature layer directory whenever updating,
# and the Dockerfile plonks that into the container image's /etc directory. We
# also fix up the /etc/localtime symlink to point to the corresponding
# zoneinfo.

# Warning, globals are global. Let's say;
# - I define a "FEATURE_NAME" and "FEATURE_FN" here as globals,
# - I define a function called "$(FEATURE_FN)",
# - in that function I use "$(FEATURE_NAME)",
# - I do the same things in another feature file (i.e. same variable names, but
#   assigned different values),
# Then, I will end up with two different functions that will both, _at
# run_time_, use whatever $(FEATURE_NAME) was last set to!
#
# This is a naughty, naughty language.
#
# So ... anything that needs to be available for evaluation at run/call-time
# but isn't passed to the function as a parameter should be given a variable
# name that is genuinely unique. The easiest way to do that is have them all
# prefixed by the feature name. I can set $(FEATURE_NAME) to do that, so long
# as the function implementatoin _refreshes_ that variable to our intended
# value before it is used by any other code in the function.

$(eval F := apt_is_usable)
$(eval $F_PREFIX := debian)
$(eval $F_FN := feature_$(subst /,__,$($F_PREFIX)/$F))

$(eval $($F_FN)_loaded := 1)
define $($F_FN)
	$(eval F := apt_is_usable)
	$(eval $(call trace,start $($F_FN)($1,$2,$3)))
	$(eval FPARAM_NEW_IMAGE := $(strip $1))
	$(eval FPARAM_BASE_IMAGE := $(strip $2))
	$(eval FPARAM_FEATURE_PATH := $(strip $3))

	$(eval $(call trace,making resync dependency))
	$(eval mycp := cp --remove-destination)
	$(eval feature_cmd1 := $$Qecho "Resyncing '$(FPARAM_NEW_IMAGE)' files")
	$(eval feature_cmd2 := $$Q$(mycp) \
		$(FPARAM_FEATURE_PATH)/$($F_PREFIX)/$F.Dockerfile \
		$($(FPARAM_NEW_IMAGE)_DOCKERFILE))
	$(eval feature_cmd3 := $$Q$(mycp) /etc/timezone \
		$($(FPARAM_NEW_IMAGE)_PATH))
	$(eval $(call mkout_rule,$($(FPARAM_NEW_IMAGE)_DOCKERFILE),\
		$(TOP_DEPS) \
		/etc/timezone \
		$(foreach i,\
			$(foreach j,Dockerfile mk,$F.$j),\
			$(FPARAM_FEATURE_PATH)/$($F_PREFIX)/$i),\
		feature_cmd1 feature_cmd2 feature_cmd3))

	$(eval $(call trace,setting attributes for IMAGE $(FPARAM_NEW_IMAGE)))
	$(eval $(FPARAM_NEW_IMAGE)_DESCRIPTION := Mariner feature layer '$F')
	$(eval $(FPARAM_NEW_IMAGE)_ARGS_DOCKER_BUILD += \
		--build-arg MYTZ=$(shell cat /etc/timezone))
	$(eval $(call trace,end $($F_FN)($1,$2,$3)))
endef
