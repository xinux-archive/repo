FROM archlinux:latest

# Setuo mirror
RUN echo 'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
RUN pacman -Sy --noconfirm reflector
RUN reflector --protocol https -c Uzbekistan --sort rate --save /etc/pacman.d/mirrorlist
RUN pacman -Sy --noconfirm devtools base-devel
RUN systemd-machine-id-setup

# Setup environment
ENV XINUX_MAIN_DIR="/home/user/main" XINUX_OUT_DIR="/home/user/repo" XINUX_WORK_DIR="/home/user/work"
RUN useradd -m -s /bin/bash -d "/home/user/" user
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/xinux-repo"
WORKDIR /home/user/main/
COPY . /home/user/main/

# Run
ENTRYPOINT []
CMD ["sudo", "-E" ,"-u", "user" , "/home/user/main/scripts/docker.sh","user" , "--" , "/home/user/main/scripts/main.sh", "--user", "user"]
