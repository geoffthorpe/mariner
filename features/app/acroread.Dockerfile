RUN sudo dpkg --add-architecture i386
RUN sudo apt update
RUN apt install -y wget libxml2:i386 libcanberra-gtk-module:i386 gtk2-engines-murrine:i386 libatk-adaptor:i386

COPY acroread.sh /
RUN chmod 775 /acroread.sh
RUN /acroread.sh
RUN rm /acroread.sh
