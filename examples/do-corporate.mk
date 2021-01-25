# This is a (working) example, but is intentionally simple and illustrative. If
# you're going to fork and modify Mariner for specific environment
# requirements, such as behind corporate proxies or inside some bizarre
# alternative docker (or non-docker) universe, overhauling this file might be a
# good place to start, in case that turns out to be the only thing you _have_
# to change...

$(info Tweaking the use-case for "corporate" requirements)

# In this example;
# A. our host is a managed box, we don't have any special privs
# B. we are using rootless docker, and the daemon is already running.
# C. we must pass through authenticating proxies for all access outside the
#    corporate network.
# D. there is a local web proxy service (listening on localhost, and specified
#    in "{all,http,https,ftp,no}_proxy" environment variables, see section 1.
# E. Because of D, problem C goes away (we don't have to teach containers to
#    authenticate all their outgoing requests).
# F. But because of D, we _do_ now have to teach all containers making outgoing
#    requests to trust the same CA certificate that's doing the TLS MITM that
#    your host system presumably already trusts. The path to this cert is
#    provided in the "ca_proxy" environment variable, see section 3.
# G. the docker daemon itself (that's already running) can't go out the web
#    proxies on your behalf because it doesn't know about your proxy or your
#    creds, and can't be taught about some alternative, in-house
#    registry/mirror (because, again, it's already running). So we explicitly
#    rewrite _TERMINATES attributes to point to an in-house docker registry for
#    initial bootstrapping. The environment variable for this is
#    "docker_proxy", see section 2.
# H. After that, all Dockerfile-driven interactions occur inside containers,
#    and we are able to inject environment and config to make that work.

############
# Section 1, treating "{all,http,https,ftp,no}_proxy" environment variables
#
# Create build-time and run-time configuratoin to use the given proxy.
#
# Note, when using rootless docker with vpnkit, a host-side proxy listening on
# "localhost" will be addressable at 192.168.65.2 from within spawned
# containers. If it is using slirp4netns instead of vpnkit, I believe the host
# shows up at 10.0.2.2 instead.  Don't ask me and don't shoot the messenger.
# Another thing you may run in to: if you have a --disable-host-loopback option
# from your "dockerd-rootless.sh" script, the container will never be able to
# reach the host at all, in which case you may need to think of other
# customizations.

CUSTOM_NAME := proxy-args.mk
CUSTOM := $(DEFAULT_CRUD)/corporate_$(CUSTOM_NAME)

# Rewrite all "localhost" to this address (vpnkit)
MUNGE_LOCALHOST := 192.168.65.2

define add_build_run_env_if_nonempty
	$(eval n := $(strip $1))
	$(if $($n),
		$(eval $n := $(subst localhost,$(strip $(MUNGE_LOCALHOST)),$(strip $($n))))
		$(info Adding BUILD option: --build-arg=$n="$($n)")
		$(info Adding RUN option  : --env=$n="$($n)")
		$(file >>$(CUSTOM),
$$(eval DEFAULT_ARGS_DOCKER_BUILD += --build-arg=$n="$($n)")
$$(eval DEFAULT_ARGS_DOCKER_RUN += --env=$n="$($n)"))
	,
		$(info Skipping empty $n)
	)
endef

$(if $(shell stat $(CUSTOM) > /dev/null 2>&1 && echo YES),,\
	$(if $(strip $(all_proxy) $(http_proxy) $(https_proxy) $(ftp_proxy) $(no_proxy)),,\
		$(error There are no '{all,http,https,ftp,no}_proxy' settings to apply??))\
	$(info Building $(CUSTOM_NAME) for the first time. Remove it to trigger re-generation.)\
	$(info (Path: $(CUSTOM)))\
	$(file >$(CUSTOM),# Auto-generated file. Move or delete to trigger re-generation)\
	$(eval $(call add_build_run_env_if_nonempty,all_proxy))\
	$(eval $(call add_build_run_env_if_nonempty,http_proxy))\
	$(eval $(call add_build_run_env_if_nonempty,https_proxy))\
	$(eval $(call add_build_run_env_if_nonempty,ftp_proxy))\
	$(eval $(call add_build_run_env_if_nonempty,no_proxy))\
	$(info Finished building $(CUSTOM_NAME)))

# Now source the fruits of our labor
include $(CUSTOM)

############
# Section 2, treating the "ca_proxy" environment variable, and making a
#            derivative Docker context, Dockerfile, etc.
#
# This is more than just writing environment settings to file then loading the
# file. We actually produce a new context area, duplicate the host trust roots
# (path given by "ca_proxy") to it, and set up a dependency to copy the
# Dockerfile to it and append it with instructions to inject those trust root
# certs into the container image.
#
# NB: this assumes that the original, pre-corporate "basedev" definition had a
# context (it doesn't set _NOPATH) but that the only file in it is its
# Dockerfile (so _DOCKERFILE can't point anywhere else). If either of those
# assumptions is false, you'll want to change something here. E.g. adding
# dependencies to copy any other context that should replicate to the
# replacement context area, treating the Dockerfile separately iff it's not
# part of the context, handling the case where there's no context at all, etc.

CUSTOM_NAME := TLS-interception-MITM.mk
CUSTOM := $(DEFAULT_CRUD)/corporate_$(CUSTOM_NAME)

# "tmp_" so that our basedev_* environment comes _only_ from sourcing the
# generated file.
tmp_basedev_PATH := $(DEFAULT_CRUD)/basedev-corporate
tmp_basedev_OLDDOCKERFILE := $(TOPDIR)/basedev/Dockerfile
tmp_basedev_DOCKERFILE := $(tmp_basedev_PATH)/Dockerfile
tmp_basedev_CA_SOURCE := $(ca_proxy)
tmp_basedev_CA_NAMES := $(shell cd $(tmp_basedev_CA_SOURCE) && ls *.crt 2> /dev/null)
tmp_basedev_CA_DEST := /usr/share/ca-certificates
tmp_basedev_CA_CONF := /etc/ca-certificates.conf
tmp_basedev_CA_CMD := update-ca-certificates

$(if $(shell mkdir -p $(tmp_basedev_PATH) > /dev/null 2>&1 && echo YES),,\
	$(error Failed to create $(tmp_basedev_PATH)))

$(if $(shell stat $(CUSTOM) > /dev/null 2>&1 && echo YES),,\
	$(if $(strip $(ca_proxy)),,\
		$(error Must set 'ca_proxy' for this to work))\
	$(if $(strip $(tmp_basedev_CA_NAMES)),,\
		$(error Must put *.crt CA certs in the 'ca_proxy' directory for this to work))\
	$(info Building $(CUSTOM_NAME) for the first time. Remove it to trigger re-generation.)\
	$(info (Path: $(CUSTOM)))\
	$(file >$(CUSTOM),# Auto-generated file. Move or delete to trigger re-generation)\
	$(file >>$(CUSTOM),)\
	$(file >>$(CUSTOM),$$(eval ca_proxy := $(ca_proxy)))\
	$(file >>$(CUSTOM),$$(eval basedev_PATH := $(tmp_basedev_PATH)))\
	$(file >>$(CUSTOM),$$(eval basedev_OLDDOCKERFILE := $(tmp_basedev_OLDDOCKERFILE)))\
	$(file >>$(CUSTOM),$$(eval basedev_DOCKERFILE := $(tmp_basedev_DOCKERFILE)))\
	$(file >>$(CUSTOM),$$(eval basedev_CA_SOURCE := $(tmp_basedev_CA_SOURCE)))\
	$(file >>$(CUSTOM),$$(eval basedev_CA_NAMES := $(tmp_basedev_CA_NAMES)))\
	$(file >>$(CUSTOM),$$(eval basedev_CA_DEST := $(tmp_basedev_CA_DEST)))\
	$(file >>$(CUSTOM),$$(eval basedev_CA_CONF := $(tmp_basedev_CA_CONF)))\
	$(file >>$(CUSTOM),$$(eval basedev_CA_CMD := $(tmp_basedev_CA_CMD)))\
	$(file >>$(CUSTOM),)\
	$(file >>$(CUSTOM),$$(basedev_DOCKERFILE): $$(basedev_OLDDOCKERFILE))\
	$(file >>$(CUSTOM),	$$Qecho "Resyncing corporatized 'basedev' CA certificates")\
	$(file >>$(CUSTOM),	$$Qmkdir -p $$(basedev_PATH)/corporate-CA)\
	$(file >>$(CUSTOM),	$$Q(cd $$(basedev_CA_SOURCE) && cp -L $$(basedev_CA_NAMES) $$(basedev_PATH)/corporate-CA))\
	$(file >>$(CUSTOM),	$$Qecho "Building corporatized 'basedev' Dockerfile")\
	$(file >>$(CUSTOM),	$$Qcp $$(basedev_OLDDOCKERFILE) $$(basedev_DOCKERFILE))\
	$(file >>$(CUSTOM),	$$Qecho "" >> $$(basedev_DOCKERFILE))\
	$(file >>$(CUSTOM),	$$Qecho "# The following is appended by do-corporate.mk" >> $$(basedev_DOCKERFILE))\
	$(file >>$(CUSTOM),	$$Qecho "RUN mkdir -p $$(basedev_CA_DEST)/corporate-CA" >> $$(basedev_DOCKERFILE))\
	$(file >>$(CUSTOM),	$$Qecho "WORKDIR $$(basedev_CA_DEST)/corporate-CA" >> $$(basedev_DOCKERFILE))\
	$(file >>$(CUSTOM),	$$Qfor i in $$(basedev_CA_NAMES); do \)\
	$(file >>$(CUSTOM),		echo "COPY corporate-CA/$$$$i ./" >> $$(basedev_DOCKERFILE); \)\
	$(file >>$(CUSTOM),		echo "RUN echo corporate-CA/$$$$i >> $$(basedev_CA_CONF)" >> $$(basedev_DOCKERFILE); \)\
	$(file >>$(CUSTOM),	done)\
	$(file >>$(CUSTOM),	$$Qecho "RUN $$(basedev_CA_CMD)" >> $$(basedev_DOCKERFILE))\
	$(file >>$(CUSTOM),	$$Qecho "WORKDIR /" >> $$(basedev_DOCKERFILE))\
	$(file >>$(CUSTOM),))

include $(CUSTOM)

############
# Section 3, treating the "docker_proxy" environment variable.
#
# We assume that basedev_TERMINATES is the "standard" name[:tag] of an upstream
# container image to be loaded from dockerhub or wherever else things come from
# normally. The following code rewrites that to an alternative, in-house,
# this-side-of-the-proxy, mirror locatoin to pull from. We use the "ca_proxy"
# env-var as a URL prefix for whatever the _TERMINATES attribute was
# previously. I.e. that prefix converts a "standard" dockerhub lookup into
# whatever its "corporate" equivalent should be.
#
# So yes, this _will_ go horribly wrong if the original _TERMINATES setting is
# a full URI/URL rather than just a name (relative path), or if the
# naming/paths aren't the same between the local registry and the upstream one.

CUSTOM_NAME := docker-registry.mk
CUSTOM := $(DEFAULT_CRUD)/corporate_$(CUSTOM_NAME)

$(if $(shell stat $(CUSTOM) > /dev/null 2>&1 && echo YES),,\
	$(if $(strip $(docker_proxy)),,\
		$(error Must set 'docker_proxy' for this to work))\
	$(info Building $(CUSTOM_NAME) for the first time. Remove it to trigger re-generation.)\
	$(info (Path: $(CUSTOM)))\
	$(file >$(CUSTOM),# Auto-generated file. Move or delete to trigger re-generation)\
	$(file >>$(CUSTOM),$$(eval docker_proxy := $(docker_proxy)))\
	$(file >>$(CUSTOM),$$(eval basedev_TERMINATES := $$(docker_proxy)/$(basedev_TERMINATES))))

include $(CUSTOM)

############
# Section 4, hook in permanently, so DO_CORPORATE doesn't need to be defined
#            any more.

$(shell touch $(DEFAULT_CRUD)/ztouch.do-corporate)
