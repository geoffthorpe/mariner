
# The following piece of hacking is to demonstrate the dual-touchfile technique
# for implementing "detach_join" semantics, which is how we get asychronous
# commands and their completions to work as distinct Makefile dependency
# targets.
#
# A couple of things worth noting from the outset;
#   - Mariner container usage has thus far always been "fire-and-forget". We
#     don't capture the CID of containers we spin up, and we use the "--rm"
#     flag to ensure docker removes the container post-exit.
#   - The detach-join case is different in both respects. We must capture the
#     CID in order to be able to wait for its conclusion ("join"), and as it
#     may conclude before we try to "join", we can't use "--rm".
#   - We already need to touch a "joinfile", as both the dependency target and
#     outcome of a requirement to have the container launched. As we need to
#     capture the CID of that launch, we can serve both needs at once by having
#     "docker-run" create that joinfile by writing the CID to it!
#    

IMG := detacher_counter
CMD := su --login $(shell whoami) -w COUNTER_VAL -c "xterm -e /countdown.sh"
IMG_CREATE := (cd .. && make counter_create)
DRUN := docker run -it -v /tmp/.X11-unix:/tmp/.X11-unix --env COUNTER_VAL="$(COUNTER_VAL)"

# ONCE_ONLY := 1

# The "detach_join" semantics use these two touchfile paths as dependencies and
# dependency targets in the following way.
TOPDIR := $(shell pwd)
joinfile := $(TOPDIR)/touch-join
donefile := $(TOPDIR)/touch-done
TOCLEAN += $(joinfile) $(donefile)

dump:
	@echo "make $(joinfile)       # to ensure the command is launched"
	@echo "make $(donefile)       # to ensure the command has completed"

# And this is a dummy touchfile used to encapsulate the idea of "upstream"
# dependencies. I.e. if this was in the Mariner/workflow makefile, this would
# be (or be dependent on) the _TOUCHFILE attribute of the container image,
# which triggers rebuilding if the image is out of date for any reason. As
# we're outside the Mariner scope, replace it with a first-use call to the
# Mariner workflow to build the container we use. (And if it had already been
# built, fine, this will be quick.)
builtfile := $(TOPDIR)/touch-built
TOCLEAN += $(builtfile)
$(builtfile):
	$(IMG_CREATE)
	touch $(builtfile)
	@echo ; echo ; echo

# The joinfile is declared as dependent only on "upstream" requirements. A
# dependency on this joinfile amounts to a need for the command to be launched,
# which creates the joinfile.
$(joinfile): $(builtfile)
	$(DRUN) -d --cidfile=$(joinfile) $(IMG) $(CMD)
	@echo
	@echo "Command launched, CID=`cat $(joinfile)`"

# We make the donefile dependent on the joinfile, and if triggered, its recipe
# will ensure the container has exited before creating the donefile. At this
# point the launch (join) and wait (done) dependency targets are met, and as
# the donefile is newer than the joinfile, there is nothing more to do.
# Subsequent dependencies on either of these cause "nothing to do, already
# up-to-date". Interestingly, we can remove the joinfile when creating the
# donefile, in which case a subsequent dependency on the joinfile will trigger
# a new command to be launched, and creates a joinfile that is now newer than
# the donefile! Rinse and repeat. The ONCE_ONLY variable illustrates this here.
#
# Also worth noting, a dependency on the donefile (without prior dependency on
# the joinfile) produces a blocking operation! I.e. it implicitly depends on
# the joinfile, so it triggers launching of the command before running the
# donefile recipe, which waits for the command to complete.
$(donefile): $(joinfile)
	@cid=`cat $(joinfile)` && \
		echo "Waiting, CID=$$cid" && \
		exitcode=`docker container wait $$cid` && \
		docker container rm $$cid && \
		(echo "I got exit code $$exitcode, so I'll exit with that too" && exit $$exitcode)
	@touch $(donefile)
	@$(if $(ONCE_ONLY),/bin/true,rm $(joinfile))

# Provide symbolic targets that appear in make's tab-completion
do_launch: $(joinfile)
do_wait: $(donefile)

# OK, what if we're building huge things and won't handcraft targets for each and every
# command? Well, it's called programming...
LOTS := foo bar jack jill
LOTS += $(foreach i,$(shell seq 1 1 20),minion$i)
showlots:
	@echo LOTS=$(LOTS)

# To make it interesting, the countdown counter for each command can be scrambled. I'll use a 5-bit
# LFSR for this (giving values from 1 to 31).
# 5-bit LFSR polynomial: x5+x3+1
$(file >lfsr.sh,#!/bin/bash)
$(file >>lfsr.sh,cur=$$1)
$(file >>lfsr.sh,mask=0x14)
$(file >>lfsr.sh,lsb=$$((cur%2)))
$(file >>lfsr.sh,cur=$$((cur/2)))
$(file >>lfsr.sh,if [[ "x$$lsb" == "x1" ]]; then)
$(file >>lfsr.sh,	cur=$$((cur^mask)))
$(file >>lfsr.sh,fi)
$(file >>lfsr.sh,echo $$cur)
$(shell chmod 755 lfsr.sh)
TOCLEAN += lfsr.sh

# So loop over LOTS and generate joinfile/donefile rules for each of them. (The
# existing builtfile thing is fine for everyone.)
$(eval lfsr_val := 1)
define foo
	$(eval i := $(strip $1))
	$(eval j := $(TOPDIR)/join_$i)
	$(eval d := $(TOPDIR)/done_$i)
	$(eval TOCLEAN += $j $d)
	$(eval lfsr_val := $(shell ./lfsr.sh $(lfsr_val)))
	$(info "Creating rules for task $i (countdown=$(lfsr_val))")
$j: $(builtfile)
	@$(DRUN) -d --cidfile=$j --env COUNTER_VAL=$(lfsr_val) $(IMG) $(CMD)
	@echo "Command launched, CID=`cat $j`"
$d: $j
	@cid=`cat $j` && echo "waiting for CID=$$$$cid" && \
		code=`docker container wait $$$$cid` && \
		docker container rm $$$$cid && \
		(echo "exit code was $$$$code" && exit $$$$code)
	@touch $(TOPDIR)/done_$i
	@$(if $(ONCE_ONLY),/bin/true,rm $(TOPDIR)/join_$i)
endef
$(foreach i,$(LOTS),$(eval $(call foo,$i)))
# That gives join/done pairs of dependency targets for each item, and as they
# use absolute paths, they don't show up in tab-completion for "make". (Good.)
# Make symbolic dependency targets that combine them all.
all_launch: $(foreach i,$(LOTS),$(TOPDIR)/join_$i)
all_wait: $(foreach i,$(LOTS),$(TOPDIR)/done_$i)

clean:
	rm -f $(TOCLEAN)
