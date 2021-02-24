ARG FEATURE_HAS_MY_USER_NAME

ENV FEATURE_HAS_MY_USER_NAME=$FEATURE_HAS_MY_USER_NAME

RUN apt-get install -y kmod

COPY uml.sh /
RUN chmod 755 /uml.sh
COPY uml.myshutdown.c /
RUN chmod 644 /uml.myshutdown.c
