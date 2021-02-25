RUN apt install -y qemu-system-x86-64
RUN apt install -y extlinux
COPY mkdiskimage.sh /
COPY launch.sh /
