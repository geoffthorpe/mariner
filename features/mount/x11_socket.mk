# This passes the host-side's DISPLAY environment variable to containers and
# mounts the host's /tmp/.X11-unix directory into the containers' same path.
# This requires the "embed_me" feature, to have the same username+uid+gid in
# the container for launching X apps.

# See the note in "debian/apt_is_usable.mk"

$(eval F := x11_socket)
$(eval $F_PREFIX := mount)
$(eval $F_FN := feature_$(subst /,__,$($F_PREFIX)/$F))

$(eval $($F_FN)_loaded := 1)
define $($F_FN)
	$(eval F := x11_socket)
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
	$(eval $(FPARAM_NEW_IMAGE)_ARGS_DOCKER_BUILD += --build-arg DISPLAY=$(DISPLAY))
	$(eval $(FPARAM_NEW_IMAGE)_ARGS_DOCKER_RUN += -v /tmp/.X11-unix:/tmp/.X11-unix)

	$(eval $(call trace,end $($F_FN)($1,$2,$3)))
endef
