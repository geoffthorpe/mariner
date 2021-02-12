include mariner_v2.mk
DEFAULT_SHELL := /bin/bash
TRACEFILE := $(DEFAULT_CRUD)/TRACE.unique
$(eval $(call do_mariner_prep))

# Special, construct a "terminator" image around upstream "debian:latest", and
# layer everything else around that (using _EXTENDS). This allows for a bunch
# of special handling to support proxying, changes to roots-of-trust (CA
# certificates), bootstrapping from behind-the-firewall images (rather than
# external dockerhub), etc.
$(eval $(call make_mariner_terminator,mybase,debian:latest))


# Load the features we'll need
features_path := $(strip $(TOPDIR)/features)
features_list := $(strip \
	debian/apt_is_usable \
	debian/embed_me \
	mount/x11_socket \
	mount/docker_socket \
	app/acroread \
	app/gimp \
	app/make)

include $(foreach i,$(features_list),$(features_path)/$i.mk)


# Create some feature layers;
# - make 'apt' minimally usable, which isn't the case in some dockerhub images
$(eval $(call make_feature_layer,with_apt_is_usable,mybase,$(features_path),\
	debian/apt_is_usable))
# - set up so that the host-side username and uid and gid are present in the
#   container too.
$(eval $(call make_feature_layer,with_embed_me,with_apt_is_usable,$(features_path),\
	debian/embed_me))


# - mount the X11 socket into the container (and pass in $(DISPLAY))
$(eval $(call make_feature_layer,with_x11,with_embed_me,$(features_path),\
	mount/x11_socket))


# At this point, override the "shell" command so that it launches into a
# seperate xterm as the embedded user account (not root)
with_x11_shell_COMMAND := su --login $(shell id -un) -c xterm


# Also, put an "acroread" layer on top of with_x11.
$(eval $(call make_feature_layer,myacroread,with_x11,$(features_path),\
	app/acroread))
COMMANDS += acroread
acroread_COMMAND := su --login $(shell id -un) -c acroread
acroread_PROFILES := batch
myacroread_COMMANDS := shell acroread


# But each container restarts from virgin state, meaning the first-use dialog
# comes up every time. So ... create a "disposable_home" managed volume and
# mount it each time. This is a disposable volume, but not completely ephemeral
# and container-specific, so it persists from (and between) invocation to
# invocation.
VOLUMES += disposable_home
disposable_home_DEST=/home/$(shell whoami)
myacroread_VOLUMES += disposable_home


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
myacroread_VOLUMES += mydocs mydownloads


# Add a "gimp" layer, similar to "acroread". 
$(eval $(call make_feature_layer,mygimp,with_x11,$(features_path),\
	app/gimp))
COMMANDS += gimp
gimp_COMMAND := su --login $(shell id -un) -c gimp
gimp_PROFILES := batch
mygimp_COMMANDS := shell gimp
mygimp_VOLUMES := disposable_home mydocs mydownloads


# Test "async" behavior using the gimp command...
gimp_PROFILES += detach_join detach_nojoin
#gimp_detach_join_HIDE := 1


# Add a "docker" layer, that mounts the host docker socket into the container
# Build on top of the with_x11 layer
$(eval $(call make_feature_layer,with_docker,with_x11,$(features_path),\
	mount/docker_socket))


# As we did earlier for 'with_x11', make the 'with_docker' shell command launch
# in an xterm. But, there's a twist. You can't launch the xterm as root, which
# is why we do the "su --login" thing. But the 'with_docker' image is only
# useful for performing operations as root (the forwarded socket expects us to
# be the host user, which is root within the container). So ... switch to
# non-root to run the xterm, then inside the xterm shell, switch back to root!
with_docker_shell_COMMAND := su --login $(shell id -un) -c "xterm -e /bin/bash -c \"sudo su -\""


# Now do something incredibly stupid but interesting;
# Actually, let's not. My previous example here in fact has gone from stupid to
# illegal, because it was rebuilding and cross-clobbering state that belongs
# and is used on the host side. What really _is_ needed is an example of an
# inner use-case being driven by an outer use-case. (What we shouldn't have tried
# was having an inner use-case _be_ the outer use-case.)
# TBD; do something.


$(eval $(call do_mariner))
