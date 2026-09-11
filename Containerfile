FROM quay.io/fedora/fedora-bootc:44

# Copr Plugin
RUN dnf in -y 'dnf5-command(copr)'

# Kernel swap
RUN dnf copr enable -y bieszczaders/kernel-cachyos
#RUN dnf copr enable -y bieszczaders/kernel-cachyos-addons
RUN dnf in -y kernel-cachyos kernel-cachyos-devel-matched
RUN dnf rm -y kernel-core-7.2.4-200.fc44.x86_64

# System Packages
RUN dnf in -y micro htop fastfetch fish just

# Desktop Environment
RUN dnf in -y @kde-desktop-environment

# User Packages
RUN dnf in -y vlc

# Virtualization \ Containerization
RUN dnf in -y distrobox

# Flatpaks
RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
RUN flatpak install flathub it.mijorus.gearlever -y
RUN flatpak install flathub com.ranfdev.DistroShelf -y

# Clean Up
RUN dnf clean all

# OS Release
RUN echo -e 'NAME="KitsuneLiunx"\n\
PRETTY_NAME="KitsuneLinux (Fedora Based)"\n\
ID=fedora\n\
LOGO=kitsune-logo\n\
VERSION_ID=v0.1rc\n\
DEFAULT_HOSTNAME="kitsunelinux"' > /etc/os-release

# Run validation checks for bootc compatibility
RUN bootc container lint
