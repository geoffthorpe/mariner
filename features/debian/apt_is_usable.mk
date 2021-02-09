# This turns a minimal debian-flavored base image into an only slightly less
# minimal one in which apt is vaguely usable.

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
	$(eval $(call mkout_rule,$($(FPARAM_NEW_IMAGE)_DOCKERFILE),\
		$(TOP_DEPS) \
		$(foreach i,\
			$(foreach j,Dockerfile mk,$F.$j),\
			$(FPARAM_FEATURE_PATH)/$($F_PREFIX)/$i),\
		feature_cmd1 feature_cmd2))

	$(eval $(call trace,setting attributes for IMAGE $(FPARAM_NEW_IMAGE)))
	$(eval $(FPARAM_NEW_IMAGE)_DESCRIPTION := Mariner feature layer '$F')
	$(eval $(call trace,end $($F_FN)($1,$2,$3)))
endef
