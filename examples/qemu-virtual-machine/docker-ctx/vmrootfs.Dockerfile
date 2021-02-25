RUN apt-get install -y linux-image-amd64
RUN apt-get install -y systemd-sysv
RUN echo "RESUME=none" > /etc/initramfs-tools/conf.d/resume
RUN update-initramfs -u
