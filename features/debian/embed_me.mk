# This adds a user-account in the container image that has the same;
# - effective user ID (from `id -u`),
# - effective group ID (from `id -g`), and
# - user name (from `whoami`)
# as the host user.
# Note, the framework will add our "name" to the derived image's _FEATURES
# attributes. However, that is "debian/embed_me", and we may later have
# "redhat/embed_me" and other variants. Code that depends on this feature
# doesn't (necessarily) want to depend on the distro-specifics of it, so we
# explicitly add "embed_me" (without prefix) to _FEATURES as well, to support
# this.

# See the note in "debian/apt_is_usable.mk"

$(eval F := embed_me)
$(eval $F_PREFIX := debian)
$(eval $F_FN := feature_$(subst /,__,$($F_PREFIX)/$F))

$(eval $($F_FN)_loaded := 1)
define $($F_FN)
	$(eval F := embed_me)
	$(eval $(call trace,start $($F_FN)($1,$2,$3)))
	$(eval FPARAM_NEW_IMAGE := $(strip $1))
	$(eval FPARAM_BASE_IMAGE := $(strip $2))
	$(eval FPARAM_FEATURE_PATH := $(strip $3))
	$(eval FPARAM_DEP := debian/apt_is_usable)

	$(eval $(call trace,verify the base has $(FPARAM_DEP)))
	$(eval $(call verify_in_list,FPARAM_DEP,$(FPARAM_BASE_IMAGE)_FEATURES))

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

	$(eval $(call trace,setting attributes for IMAGE $(FPARAM_NEW_IMAGE)))
	$(eval $(FPARAM_NEW_IMAGE)_DESCRIPTION := Mariner feature layer '$F')
	$(eval $(FPARAM_NEW_IMAGE)_ARGS_DOCKER_BUILD += \
		--build-arg FEATURE_HAS_MY_USER_UID=$(shell id -u) \
		--build-arg FEATURE_HAS_MY_USER_GID=$(shell id -g) \
		--build-arg FEATURE_HAS_MY_USER_NAME=$(shell whoami) \
		--build-arg FEATURE_HAS_MY_USER_GECOS="$(shell getent passwd `whoami` | cut -d ':' -f 5)")

	$(eval $(FPARAM_NEW_IMAGE)_FEATURES += $F)
	$(eval $(call trace,end $($F_FN)($1,$2,$3)))
endef
