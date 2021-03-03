# If this environment is behind an authenticating proxy, or needs to pre-trust
# corporate CA (and/or MITM) certs, or needs to source base container images
# (debian/ubuntu/etc) from some other registry than the system-wide default
# (which is usually dockerhub), the following fails-silently-if-absent include
# provides a place to hook in the required environment-variables. These are
# consumed by the "do_mariner_prep" function just below, generating the
# so-called "control-files" for this Mariner environment. (And also influence
# the "make_mariner_terminator" stuff right after that.)
-include enterprise-adaptations.mk

# Boilerplate loading and prep
include mariner_v2.mk
DEFAULT_SHELL := /bin/bash
TRACEFILE := $(DEFAULT_CRUD)/TRACE.unique
$(eval $(call do_mariner_prep))

# The one and only reference to externally-defined container images, we layer
# everything else on top of this (using _EXTENDS). We use
# make_mariner_terminator to produce this rather than explicitly declaring an
# image with _TERMINATES, because the wrapper also accommodates some dark
# corners of the "enterprise-adaptations.mk" stuff.
$(eval $(call make_mariner_terminator,mybase,debian:latest))

# Load the features we'll use
features_path := $(strip $(TOPDIR)/features)
features_list := $(strip \
	debian/apt_is_usable \
	debian/embed_me \
	mount/x11_socket \
	sys/nada)
include $(foreach i,$(features_list),$(features_path)/$i.mk)

$(eval $(call make_feature_layer,a1,mybase,$(features_path),debian/apt_is_usable))
$(eval $(call make_feature_layer,a2,a1,$(features_path),debian/embed_me))
$(eval $(call make_feature_layer,a3,a2,$(features_path),mount/x11_socket))
$(eval $(call make_feature_layer,alast,a3,$(features_path),sys/nada))

IMAGES += counter
counter_EXTENDS := alast
counter_PATH := $(TOPDIR)/ctx_counter
counter_ARGS_DOCKER_RUN := $(alast_ARGS_DOCKER_RUN) --env COUNTER_VAL="$(COUNTER_VAL)"

COMMANDS += countdown
counter_COMMANDS := countdown
countdown_PROFILES := batch detach_nojoin detach_join
countdown_COMMAND := su --login $(shell whoami) -w COUNTER_VAL -c "xterm -e /countdown.sh"


$(eval $(call do_mariner))
