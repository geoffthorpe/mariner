include mariner_v2.mk
DEFAULT_SHELL := /bin/bash
TRACEFILE := $(DEFAULT_CRUD)/TRACE.unique
$(eval $(call do_mariner_prep))

IMAGES := mybase

mybase_TERMINATES := debian:latest
mybase_NOPATH := true
mybase_DOCKERFILE := $(TOPDIR)/Dockerfile-mybase


# Load the features we'll need
features_path := $(strip $(TOPDIR)/features)
features_list := $(strip \
	debian/apt_is_usable \
	debian/embed_me \
	user/as_me \
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


# - make containers automatically log in as the current host user, rather than
#   root. (This is why all our Dockerfiles have the ASROOT=sudo stuff, so that
#   image-building commands run as root, even if the container starts up our
#   command under a non-root user account by default.)
$(eval $(call make_feature_layer,with_as_me,with_embed_me,$(features_path),\
	user/as_me))


# - mount the X11 socket into the container (and pass in $(DISPLAY))
$(eval $(call make_feature_layer,with_x11,with_as_me,$(features_path),\
	mount/x11_socket))


# At this point, override the "shell" command so that it launches into a
# seperate xterm
with_x11_shell_COMMAND := xterm -e /bin/bash


# Also, put an "acroread" layer on top of with_x11.
$(eval $(call make_feature_layer,myacroread,with_x11,$(features_path),\
	app/acroread))
COMMANDS += acroread
acroread_COMMAND := acroread
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
gimp_COMMAND := gimp > /dev/null 2>&1
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


# As we did earlier for 'with_as_me', make the 'with_docker' shell command
# launch in an xterm
with_docker_shell_COMMAND := xterm -e /bin/bash


# Now do something incredibly stupid but interesting;
# - add a feature layer called "trouble", in which we install "make"
# - define an un-managed volume "thisdir" representing the current directory,
#   that mounts into containers at the same path.
# - add the "thisdir" volume to the "trouble" image.
# - make a new command "spiral".
# - add the "spiral" command to the "trouble" image.
# - define the "spiral" command to launch an xterm and in it, cd to the mount of
#   this directory, and (using sudo) run this spiral make target!
# - because we have forwarded the current directory, the docker socket, and the
#   X11 socket, we can recurse.
$(eval $(call make_feature_layer,trouble,with_docker,$(features_path),\
	app/make))
VOLUMES += thisdir
trouble_VOLUMES += thisdir
thisdir_MANAGED := false
thisdir_SOURCE := $(shell pwd)
thisdir_DEST := $(shell pwd)
COMMANDS += spiral
trouble_COMMANDS := shell spiral
spiral_COMMAND := xterm -e /bin/bash -c "cd $(shell pwd) && sudo make trouble_spiral"
# As a sequence of xterms pop up, they should typically get foregrounded, and a
# ctrl-c in the latest will cause the make->docker->make loop to stop, and the
# xterms will leave in the opposite order they arrived. Useful is to open a
# second console and have it run;
#    while /bin/true; do clear; docker ps -a; sleep 1; done


$(eval $(call do_mariner))
