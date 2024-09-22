# Use a base image for Void Linux
FROM voidlinux/voidlinux-base:latest

# Set a non-root user
USER root

# Install necessary packages for SSH and Void Linux setup
RUN xbps-install -Syu && \
    xbps-install -y openssh void-repo-nonfree && \
    xbps-install -Syu && \
    rm -rf /var/cache/xbps/*

# Create a non-root user
RUN useradd -m -s /bin/bash voiduser && \
    echo 'voiduser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to non-root user
USER voiduser

# Set up SSH server to run on port 8080 (as OpenShift only allows certain ports)
RUN mkdir -p ~/.ssh && \
    ssh-keygen -A && \
    echo 'Port 8080' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config

# Script to update the user password at runtime using the environment variable
COPY update-password.sh /usr/local/bin/update-password.sh
RUN chmod +x /usr/local/bin/update-password.sh

# Expose port 8080 for SSH
EXPOSE 8080

# Start SSH service and update password using OpenShift secret
CMD ["/bin/bash", "-c", "/usr/local/bin/update-password.sh && /usr/sbin/sshd -D"]

