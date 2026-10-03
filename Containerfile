FROM quay.io/fedora/fedora-bootc:45

# Copr Plugin
RUN dnf in -y 'dnf5-command(copr)'

# Kernel swap
RUN dnf copr enable -y bieszczaders/kernel-cachyos
#RUN dnf copr enable -y bieszczaders/kernel-cachyos-addons
RUN dnf in -y kernel-cachyos kernel-cachyos-devel-matched zram-generator-defaults
RUN dnf rm -y kernel-core-*

# Drivers and things
RUN dnf in -y ntfs-3g btrfs-progs langpacks-en glibc-all-langpacks

# System Packages
RUN dnf copr enable -y atim/starship
RUN dnf in -y micro btop fastfetch fish starship flatpak 

# Remove fedora repo before environment
#RUN flatpak remote-delete fedora

# Dev Tools
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
RUN echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
RUN dnf in -y just code

# Desktop Environment
#RUN dnf in -y plasma-desktop sddm dolphin konsole plasma-discover kinfocenter kwallet ark kate gwenview kcalc okular
RUN dnf in -y @kde-deskop NetworkManager pipewire

# User Packages
RUN dnf copr enable -y imput/helium
RUN dnf in -y helium-bin vlc 

# Virtualization \ Containerization
RUN dnf in -y @virtualization distrobox 

# Flatpaks
RUN flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
RUN flatpak install -y flathub it.mijorus.gearlever 
RUN flatpak install -y flathub com.ranfdev.DistroShelf

# Clean Up
RUN dnf upgrade -y --refresh && dnf autoremove -y && dnf clean all

# Configs
COPY ./configs/* /etc/
RUN command -v fish | tee -a /etc/shells
RUN useradd -D -s $(command -v fish)
RUN sed -i '/ \/ /d' /etc/fstab' 


# OS Release
RUN echo -e 'NAME="KitsuneLinux"\n\
PRETTY_NAME="KitsuneLinux (Fedora Based)"\n\
ID=fedora\n\
LOGO=kitsune-logo\n\
VERSION_ID=v0.1rc1\n\
DEFAULT_HOSTNAME="kitsunelinux"' > /etc/os-release

# Run validation checks for bootc compatibility
RUN bootc container lint
