RUN apt install -y libjson-perl libncurses-dev texinfo

ARG FEATURE_HAS_MY_USER_NAME
ENV FEATURE_HAS_MY_USER_NAME=$FEATURE_HAS_MY_USER_NAME

COPY heimdal.sh /
RUN chmod 755 /heimdal.sh
