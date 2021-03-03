# Use "alcatraz" as the docker namespace. All generated images and networks
# will be prefixed by "alcatraz_" within Docker, and so hopefully not mess with
# (nor be messed with by) other activities.
DSPACE := alcatraz

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
$(eval $(call make_mariner_terminator,mybase,ubuntu:rolling))

# Load the features we'll use
features_path := $(strip $(TOPDIR)/features)
features_list := $(strip \
	debian/apt_is_usable \
	debian/embed_me \
	mount/x11_socket \
	mount/audio_socket \
	mount/docker_socket \
	app/acroread \
	app/gimp)
include $(foreach i,$(features_list),$(features_path)/$i.mk)

$(eval $(call make_feature_layer,a1,mybase,$(features_path),debian/apt_is_usable))
$(eval $(call make_feature_layer,a2,a1,$(features_path),debian/embed_me))
$(eval $(call make_feature_layer,a3,a2,$(features_path),mount/x11_socket))
$(eval $(call make_feature_layer,a4,a3,$(features_path),mount/audio_socket))
$(eval $(call make_feature_layer,a5,a4,$(features_path),app/acroread))
$(eval $(call make_feature_layer,alast,a5,$(features_path),app/gimp))

# The 'alcatraz' image becomes a template for app-specific container images.
#
# With the feature layers added just above, a user account (matching the
# current host user account w.r.t. name/groups/uids/etc) has been created
# within the container image, and it has access to the current host account's
# X11, sound, and docker servers/daemons/devices.
#
# Here, we will further embellish it with stuff that isn't factored out into
# "feature layers" yet. Right now, this includes PulseAudio handling. (Passing
# /dev/snd isn't enough in some host environments, in which case apps within
# the container should be started via the "apulse" wrapper.)
#
# See ./ctx_alcatraz/{Dockerfile,run-arbitrary.sh} for the detail.
IMAGES += alcatraz
alcatraz_EXTENDS := alast
alcatraz_PATH := $(TOPDIR)/ctx_alcatraz

COMMANDS += run-arbitrary
alcatraz_COMMANDS := shell run-arbitrary
run-arbitrary_COMMAND := /run-arbitrary.sh
alcatraz_ARGS_DOCKER_RUN := $(alast_ARGS_DOCKER_RUN) --env ARG_RUN_ARBITRARY

# But each container restarts from virgin state, meaning the first-use dialog
# comes up every time. So ... create a "disposable_home" managed volume and
# mount it each time. This is a disposable volume, but not completely ephemeral
# and container-specific, so it persists between invocations.
VOLUMES += disposable_home
disposable_home_DEST=/home/$(shell whoami)
alcatraz_VOLUMES += disposable_home

# But if we're opening acroread this way, it's to open a PDF that has been
# dropped into our Documents or Downloads directories. Define unmanaged
# (non-disposable) volumes for them and mount them _readonly_(!) inside our
# otherwise managed (disposable) home directory.
VOLUMES += mydocs mydownloads
mydocs_MANAGED := false
mydownloads_MANAGED := false
mydocs_SOURCE := $(HOME)/Documents
mydocs_DEST := /home/$(shell whoami)/Documents
mydownloads_SOURCE := $(HOME)/Downloads
mydownloads_DEST := /home/$(shell whoami)/Downloads
mydocs_OPTIONS := readonly
mydownloads_OPTIONS := readonly
alcatraz_VOLUMES += mydocs mydownloads

$(eval $(call do_mariner))
