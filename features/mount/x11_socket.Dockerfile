RUN apt-get install -y xterm
ARG DISPLAY
RUN echo "DISPLAY=$DISPLAY" >> /etc/environment
