ARG FEATURE_HAS_MY_USER_UID
ARG FEATURE_HAS_MY_USER_GID
ARG FEATURE_HAS_MY_USER_NAME
ARG FEATURE_HAS_MY_USER_GNAME
ARG FEATURE_HAS_MY_USER_GROUPS
ARG FEATURE_HAS_MY_USER_GECOS
ARG RUNFLAG_AS_ME

ENV FEATURE_HAS_MY_USER_UID=$FEATURE_HAS_MY_USER_UID
ENV FEATURE_HAS_MY_USER_GID=$FEATURE_HAS_MY_USER_GID
ENV FEATURE_HAS_MY_USER_NAME=$FEATURE_HAS_MY_USER_NAME
ENV FEATURE_HAS_MY_USER_GNAME=$FEATURE_HAS_MY_USER_GNAME
ENV FEATURE_HAS_MY_USER_GROUPS=$FEATURE_HAS_MY_USER_GROUPS
ENV FEATURE_HAS_MY_USER_GECOS=$FEATURE_HAS_MY_USER_GECOS
ENV RUNFLAG_AS_ME=$RUNFLAG_AS_ME

RUN apt-get install -y sudo
COPY embed_me.sh /
RUN chmod 775 /embed_me.sh
RUN /embed_me.sh
RUN rm /embed_me.sh
