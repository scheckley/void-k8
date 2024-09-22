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
RUN useradd -m -s /bin/bash containeruser && \
    echo 'containeruser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to non-root user
USER containeruser

# Create a writable directory for SSH keys and configuration
RUN mkdir -p /home/containeruser/.ssh && \
    mkdir -p /home/containeruser/ssh_keys && \
    chmod 700 /home/containeruser/.ssh

# Generate SSH host keys in the writable directory
RUN ssh-keygen -t rsa -f /home/containeruser/ssh_keys/ssh_host_rsa_key -N '' && \
    ssh-keygen -t ecdsa -f /home/containeruser/ssh_keys/ssh_host_ecdsa_key -N '' && \
    ssh-keygen -t ed25519 -f /home/containeruser/ssh_keys/ssh_host_ed25519_key -N ''

# Copy default SSH config to a writable location and modify it
RUN cp /etc/ssh/sshd_config /home/containeruser/.ssh/sshd_config && \
    echo 'Port 8080' >> /home/containeruser/.ssh/sshd_config && \
    echo 'PermitRootLogin no' >> /home/containeruser/.ssh/sshd_config && \
    echo 'HostKey /home/containeruser/ssh_keys/ssh_host_rsa_key' >> /home/containeruser/.ssh/sshd_config && \
    echo 'HostKey /home/containeruser/ssh_keys/ssh_host_ecdsa_key' >> /home/containeruser/.ssh/sshd_config && \
    echo 'HostKey /home/containeruser/ssh_keys/ssh_host_ed25519_key' >> /home/containeruser/.ssh/sshd_config

# Expose port 8080 for SSH
EXPOSE 8080

# Start SSH service using the custom configuration and key locations
CMD ["/usr/sbin/sshd", "-D", "-f", "/home/containeruser/.ssh/sshd_config"]

