ARG ASROOT
RUN $ASROOT sudo dpkg --add-architecture i386
RUN $ASROOT sudo apt update
RUN $ASROOT apt install -y wget libxml2:i386 libcanberra-gtk-module:i386 gtk2-engines-murrine:i386 libatk-adaptor:i386

COPY acroread.sh /
RUN $ASROOT chmod 775 /acroread.sh
#RUN $ASROOT /acroread.sh
#RUN $ASROOT rm /acroread.sh
