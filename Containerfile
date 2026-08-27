#
#     Welcome to Kistune Linux
#     Based on Univesal Blue & bootc
#     Using Arch/CacheyOS as a base
#     Focused on Hyperland/DMS and podman containerization
#     uBlue/BuildBlue needs to get their tools in order because this was the better alternative.
#

# bases image on v4 cachyos
FROM docker.io/cachyos/cachyos-v3:latest AS base
ENV DRACUT_NO_XATTR=1

# Move everything from `/var` to `/usr/lib/sysimage` so behavior around pacman remains the same on `bootc usroverlay`'d systems, thanks bootcrew
RUN grep "= */var" /etc/pacman.conf | sed "/= *\/var/s/.*=// ; s/ //" | xargs -n1 sh -c 'mkdir -p "/usr/lib/sysimage/$(dirname $(echo $1 | sed "s@/var/@@"))" && mv -v "$1" "/usr/lib/sysimage/$(echo "$1" | sed "s@/var/@@")"' '' && \
    sed -i -e "/= *\/var/ s/^#//" -e "s@= */var@= /usr/lib/sysimage@g" -e "/DownloadUser/d" /etc/pacman.conf

# pacman cleaning after installs
RUN echo -e "[Trigger]\n\
Operation = Install\n\
Operation = Upgrade\n\
Type = Package\n\
Target = *\n\
\n\
[Action]\n\
Description = Cleaning up package cache...\n\
Depends = coreutils\n\
When = PostTransaction\n\
Exec = /usr/bin/rm -rf /var/cache/pacman/pkg" > /usr/share/libalpm/hooks/package-cleanup.hook

# prepares pacman
RUN pacman -Syu --noconfirm
RUN pacman -S --noconfirm reflector

# base linux packages
RUN pacman -S --noconfirm base linux-firmware dracut linux-cachyos ostree systemd 

# system tools
RUN pacman -S --noconfirm btrfs-progs e2fsprogs xfsprogs binutils shadow cpio dbus dbus-glib glib2 dosfstools skopeo

# media tools
RUN pacman -S --noconfirm librsvg libglvnd qt6-multimedia-ffmpeg plymouth acpid ddcutil dmidecode mesa-utils ntfs-3g \
      vulkan-tools wayland-utils playerctl rsync

# Fonts
RUN pacman -S --noconfirm noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji unicode-emoji

# CLI Utilities
RUN pacman -S --noconfirm sudo bash bash-completion fastfetch btop jq less lsof nano openssh micro man-db wget starship\
      tree usbutils cliphist unzip ptyxis glibc-locales tar udev tuned-ppd tuned curl patchelf 

# Virtualization \ Containerization
RUN pacman -S --noconfirm distrobox docker podman qemu-desktop libvirt virt-manager dnsmasq ebtables iptables

# drivers, yuck
RUN pacman -S --noconfirm amd-ucode intel-ucode efibootmgr shim mesa lib32-mesa libva-intel-driver libva-mesa-driver \
    vpl-gpu-rt vulkan-icd-loader vulkan-intel vulkan-radeon apparmor xf86-video-amdgpu lib32-vulkan-radeon zram-generator \
    lm_sensors intel-media-driver dotnet-runtime bluez bluez-utils

# Network 
RUN pacman -S --noconfirm libmtp nss-mdns samba smbclient networkmanager firewalld udiskie udisks2

# Pipewire
RUN pacman -S --noconfirm pipewire pipewire-pulse pipewire-zeroconf pipewire-ffado pipewire-libcamera sof-firmware wireplumber \
    alsa-firmware lib32-pipewire pipewire-audio linux-firmware-intel

# Desktop Environment 
RUN pacman -S --noconfirm xwayland-satellite xdg-desktop-portal-kde xdg-desktop-portal xdg-user-dirs xdg-desktop-portal-gnome \
      ffmpegthumbs kdegraphics-thumbnailers kdenetwork-filesharing kio-admin chezmoi matugen accountsservice dgop cava dolphin \ 
      breeze brightnessctl ddcutil xdg-utils kservice5 archlinux-xdg-menu shared-mime-info kio glycin gnome-themes-extra

# yes i know chaotic aur blah blah blah
RUN pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
RUN pacman-key --init && pacman-key --lsign-key 3056513887B78AEB
RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
RUN echo -e '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' >> /etc/pacman.conf
RUN pacman -Syu --noconfirm

#RUN pacman-key --recv-key 5DE6BF3EBC86402E7A5C5D241FA48C960F9604CB --keyserver keyserver.ubuntu.com
#RUN pacman-key --lsign-key 5DE6BF3EBC86402E7A5C5D241FA48C960F9604CB
#RUN echo -e '[bootc]\nSigLevel = Required\nServer=https://github.com/hecknt/arch-bootc-pkgs/releases/download/$repo' >> /etc/pacman.conf
#RUN pacman -Syu --noconfirm

#dms/hyperland setup
RUN pacman -S --noconfirm \
    hyperland \
    chaotic-aur/bootc \
    chaotic-aur/dms-shell-git chaotic-aur/qt6ct-kde 

# bootc
#RUN pacman -S --noconfirm \
#  bootc/uupd && \
#  systemctl enable uupd.timer

# User tools
RUN pacman -S --noconfirm scx-scheds scx-manager gparted

# Set up zram, this will help users not run out of memory. Thanks xeniaOS for this one.
RUN echo -e '[zram0]\nzram-size = min(ram, 8192)' > /usr/lib/systemd/zram-generator.conf
RUN echo -e 'enable systemd-resolved.service' > /usr/lib/systemd/system-preset/91-resolved-default.preset
RUN echo -e 'L /etc/resolv.conf - - - - ../run/systemd/resolve/stub-resolv.conf' > /usr/lib/tmpfiles.d/resolved-default.conf
RUN systemctl preset systemd-resolved.service

# OS Release and Update uwu
RUN echo -e 'NAME="KistuneLiunx"\n\
PRETTY_NAME="KistuneLinux (Arch Based)"\n\
ID=arch\n\
BUILD_ID=rolling\n\
ANSI_COLOR="38;2;23;147;209"\n\
LOGO=archlinux-logo\n\
DEFAULT_HOSTNAME="devTest"' > /etc/os-release

# System services (Machine Boot level)
RUN systemctl enable polkit.service \
    NetworkManager.service \
    tuned.service \
    tuned-ppd.service \
    firewalld.service \
    greetd.service \
    flatpak-preinstall.service \
    xeniaos-group-fix.service \
    cups.socket \
    cups-browsed.service \
    bluetooth.service

# User services (Niri/user session level)
RUN systemctl --global enable \
    hyprland.service \
    dms.service \
    udiskie.service \
    chezmoi-init.service \
    chezmoi-update.service \
    chezmoi-update.timer 


RUN echo -e 'ntsync' > /etc/modules-load.d/ntsync.conf

#Starship setup
RUN echo -e 'eval "$(starship init bash)"' >> /etc/bash.bashrc

RUN rm -rf /home/build/.cache/* && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/* && \
    pacman -Rns --noconfirm git

# Necessary for general behavior expected by image-based systems
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd" && \
    rm -rf /boot /home /root /usr/local /srv /opt /mnt /var /usr/lib/sysimage/log /usr/lib/sysimage/cache/pacman/pkg && \
    mkdir -p /sysroot /boot /usr/lib/ostree /var && \
    ln -sT sysroot/ostree /ostree && ln -sT var/roothome /root && ln -sT var/srv /srv && ln -sT var/opt /opt && ln -sT var/mnt /mnt && ln -sT var/home /home && ln -sT ../var/usrlocal /usr/local && \
    echo "$(for dir in opt home srv mnt usrlocal ; do echo "d /var/$dir 0755 root root -" ; done)" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf "d /var/roothome 0700 root root -\nd /run/media 0755 root root -" | tee -a "/usr/lib/tmpfiles.d/bootc-base-dirs.conf" && \
    printf '[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n' | tee "/usr/lib/ostree/prepare-root.conf"

RUN bootc container lint