ARG ASROOT
ARG FEATURE_HAS_MY_USER_NAME

ENV FEATURE_HAS_MY_USER_NAME=$FEATURE_HAS_MY_USER_NAME
ENV HOME /home/$FEATURE_HAS_MY_USER_NAME

COPY vde.sh /
RUN $ASROOT chmod 755 /vde.sh
