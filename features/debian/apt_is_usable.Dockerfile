ARG ASROOT
RUN $ASROOT echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN $ASROOT apt-get update && apt-get -y dist-upgrade && apt-get install -y apt-utils
