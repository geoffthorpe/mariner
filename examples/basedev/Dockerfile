# Avoid some annoying debconf warnings
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Probably not required unless using a "slim" debian baseline, but harmless in any case.
RUN apt-get update

# "apt-get install"s will issue warnings if apt-utils isn't installed, so install it first.
RUN apt-get install -y apt-utils

# The rest of this goes faster if there's one instance of apt-get, on the other
# hand if we start creating variants, docker can only be "clever" about saving
# storage/time when there are common sequences of Dockerfile commands, which
# won't happen if each container recipe coalesces its package installations
# into a single, long, unique RUN command.
# So ... one RUN for now, with line-breaks to emphasize category, and break
# this apart if variants become "a thing".
RUN apt-get install -y \
	gcc make git \
	autoconf automake libtool \
	python

# Adding things that came up along the way, keeping it seperate from previous stuff.
RUN apt-get install -y flex bison bc
