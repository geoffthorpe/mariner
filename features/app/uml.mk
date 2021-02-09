# Clones linux-stable if it hasn't been cloned, updates it, compiles it, and
# installs it.
#
# The git clone is made in $(HOME), so it shows up in $(HOME)/linux-stable. If
# persistence is desired, mount something at that path.
#
# As with all user-space-building recipes in Mariner, UML is configured with an
# install prefix of /install. Mounting something at that path would likely make
# sense.
#
# Note the ARGS_DOCKER_RUN attribute we set for the new image. This works
# around cases where the host mounts /dev/shm with "noexec", because UML
# requires the exec option.

# See the note in "debian/apt_is_usable.mk"

$(eval F := uml)
$(eval $F_PREFIX := app)
$(eval $F_FN := feature_$(subst /,__,$($F_PREFIX)/$F))

$(eval $($F_FN)_loaded := 1)
define $($F_FN)
	$(eval F := uml)
	$(eval $(call trace,start $($F_FN)($1,$2,$3)))
	$(eval FPARAM_NEW_IMAGE := $(strip $1))
	$(eval FPARAM_BASE_IMAGE := $(strip $2))
	$(eval FPARAM_FEATURE_PATH := $(strip $3))
	$(eval FPARAM_DEP := embed_me debian/typical_devel)

	$(foreach i,$(FPARAM_DEP),
		$(eval $(call trace,verify the base has $i))
		$(eval $(call verify_in_list,i,$(FPARAM_BASE_IMAGE)_FEATURES)))

	$(eval $(call trace,making resync dependency))
	$(eval mycp := cp --remove-destination)
	$(eval feature_cmd1 := $$Qecho "Resyncing '$(FPARAM_NEW_IMAGE)' files")
	$(eval feature_cmd2 := $$Q$(mycp) \
		$(FPARAM_FEATURE_PATH)/$($F_PREFIX)/$F.Dockerfile \
		$($(FPARAM_NEW_IMAGE)_DOCKERFILE))
	$(eval feature_cmd3 := $$Q$(mycp) \
		$(FPARAM_FEATURE_PATH)/$($F_PREFIX)/$F.sh \
		$($(FPARAM_NEW_IMAGE)_PATH))
	$(eval $(call mkout_rule,$($(FPARAM_NEW_IMAGE)_DOCKERFILE),\
		$(TOP_DEPS) \
		$(foreach i,\
			$(foreach j,sh Dockerfile mk,$F.$j),\
			$(FPARAM_FEATURE_PATH)/$($F_PREFIX)/$i),\
		feature_cmd1 feature_cmd2 feature_cmd3))

	$(eval $(call trace,checking for 'build' command))
	$(if $(filter build,$(COMMANDS)),,
		$(eval $(call trace,adding missing 'build' command))
		$(eval COMMANDS += build)
		$(eval build_COMMAND := /bin/false))
	$(eval $(FPARAM_NEW_IMAGE)_build_COMMAND := bash -c "/uml.sh")
	$(eval $(FPARAM_NEW_IMAGE)_COMMANDS := shell build)

	$(eval $(call trace,setting attributes for IMAGE $(FPARAM_NEW_IMAGE)))
	$(eval $(FPARAM_NEW_IMAGE)_DESCRIPTION := Mariner feature layer '$F')
	$(eval $(FPARAM_NEW_IMAGE)_ARGS_DOCKER_RUN := \
		-v /dev/shm --tmpfs /dev/shm:rw,nosuid,nodev,exec,size=4g)

	$(eval $(call trace,end $($F_FN)($1,$2,$3)))
endef
