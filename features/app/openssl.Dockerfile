ARG FEATURE_HAS_MY_USER_NAME
ENV FEATURE_HAS_MY_USER_NAME=$FEATURE_HAS_MY_USER_NAME
COPY openssl.sh /
RUN chmod 755 /openssl.sh
