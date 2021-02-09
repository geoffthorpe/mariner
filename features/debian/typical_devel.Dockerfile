ARG ASROOT

RUN $ASROOT apt-get install -y \
	gcc make git \
	autoconf automake libtool \
	python flex bison bc

