# This adds a "USER" dockerfile directive, and propagates the host user-name
# (the result of `whoami`), so that adding this feature produces images that,
# by default, run commands as that user in the container (rather than root).
# Necessarily, this requires that the "embed_me" feature already be present.

# See the note in "debian/apt_is_usable.mk"

# NOTE: because this layer (and any layered on top of it) will cause launched
# containers to start with user (not root) privileges, the "embed_me" layer (that
# this layer depends on) has provided two additional adaptations;
# - the user is given password-less sudo privs
# - the ASROOT build-arg is present and expands to "sudo".
# As such, Dockerfiles that operate above this layer can use constructs of the
# form; "RUN $ASROOT <...>"

$(eval F := as_me)
$(eval $F_PREFIX := user)
$(eval $F_FN := feature_$(subst /,__,$($F_PREFIX)/$F))

$(eval $($F_FN)_loaded := 1)
define $($F_FN)
	$(eval F := as_me)
	$(eval $(call trace,start $($F_FN)($1,$2,$3)))
	$(eval FPARAM_NEW_IMAGE := $(strip $1))
	$(eval FPARAM_BASE_IMAGE := $(strip $2))
	$(eval FPARAM_FEATURE_PATH := $(strip $3))
	$(eval FPARAM_DEP := embed_me)

	$(eval $(call trace,verify the base has $(FPARAM_DEP)))
	$(eval $(call verify_in_list,FPARAM_DEP,$(FPARAM_BASE_IMAGE)_FEATURES))

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
	$(eval $(FPARAM_NEW_IMAGE)_ARGS_DOCKER_BUILD += --build-arg ASROOT="sudo -E")

	$(eval $(call trace,end $($F_FN)($1,$2,$3)))
endef
