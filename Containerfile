FROM quay.io/fedora/fedora-bootc:44

# Install system packages
RUN dnf install -y htop 



# Finally clean
RUN dnf clean all

# Run validation checks for bootc compatibility
RUN bootc container lint