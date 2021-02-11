ARG MYTZ
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get install -y apt-utils
COPY timezone /etc
RUN cd /etc && rm -f localtime && ln -s /usr/share/zoneinfo/$MYTZ localtime
