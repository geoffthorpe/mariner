############
# DEFAULTS #

# We will always have /bin/bash, which is nicer than /bin/sh
DEFAULT_SHELL := /bin/bash

include mariner_v2.mk

# Just one TRACE file, rewritten each time make is run.
TRACEFILE := $(DEFAULT_CRUD)/TRACE.unique

# Prep the environment (crud directory, tracing, etc) prior to defining the use-case.
$(eval $(call do_mariner_prep))

#################################################
# Some simple testing stuff to run in parallel. #

IMAGES := testing-base timage1
MYTESTS := tcmd1 tcmd2 tcmd3
COMMANDS := $(MYTESTS)
testing-base_TERMINATES := debian:latest
testing-base_PATH_MAP := testing_path_map
define testing_path_map
	$(eval $(strip $1)_PATH := $(TOPDIR)/$(strip $1))
endef
timage1_EXTENDS := testing-base
timage1_COMMANDS := tcmd1 tcmd2 tcmd3
tcmd1_PROFILES := batch
tcmd2_PROFILES := batch
tcmd3_PROFILES := batch
tcmd1_COMMAND := /bin/bash -c \
"echo OUT1 && sleep 1 && echo OUT1 && sleep 1 && echo OUT1 && sleep 1 && echo OUT1"
tcmd2_COMMAND := /bin/bash -c \
"echo OUT2 && sleep 1 && echo OUT2 && sleep 1 && echo OUT2 && sleep 1 && echo OUT2"
tcmd3_COMMAND := /bin/bash -c \
"echo OUT3 && sleep 1 && echo OUT3 && sleep 1 && echo OUT3 && sleep 1 && echo OUT3"

# This is where we can test parallel make. Everything has to be launched in
# batch mode, otherwise they compete for stdin.
all-tests: $(foreach i,$(MYTESTS),timage1_$i_batch)
	$(Q)echo "My tests went just fine, thanks"

#################
# Run "mariner" #

$(eval $(call do_mariner))
