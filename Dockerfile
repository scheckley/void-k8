# Use a base image for Void Linux
FROM ghcr.io/void-linux/void-glibc:latest

# Use a base image for Void Linux
FROM voidlinux/voidlinux-base:latest

# Set root user to install packages
USER root

# Install necessary packages for SSH, user management, and Void Linux setup
RUN xbps-install -Syu && \
    xbps-install -y openssh shadow void-repo-nonfree && \
    xbps-install -Syu && \
    rm -rf /var/cache/xbps/*

# Create a non-root user with sudo privileges
RUN useradd -m -s /bin/bash containeruser && \
    echo 'containeruser ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Create necessary directories in /tmp and set permissions
RUN mkdir -p /tmp/ssh_config /tmp/ssh_keys && \
    chmod 700 /tmp/ssh_config /tmp/ssh_keys && \
    chown -R containeruser:containeruser /tmp/ssh_config /tmp/ssh_keys

# Switch to non-root user
USER containeruser

# Generate SSH host keys in the /tmp directory
RUN ssh-keygen -t rsa -f /tmp/ssh_keys/ssh_host_rsa_key -N '' && \
    ssh-keygen -t ecdsa -f /tmp/ssh_keys/ssh_host_ecdsa_key -N '' && \
    ssh-keygen -t ed25519 -f /tmp/ssh_keys/ssh_host_ed25519_key -N ''

# Copy default SSH config to /tmp and modify it
RUN cp /etc/ssh/sshd_config /tmp/ssh_config/sshd_config && \
    echo 'Port 8080' >> /tmp/ssh_config/sshd_config && \
    echo 'PermitRootLogin no' >> /tmp/ssh_config/sshd_config && \
    echo 'HostKey /tmp/ssh_keys/ssh_host_rsa_key' >> /tmp/ssh_config/sshd_config && \
    echo 'HostKey /tmp/ssh_keys/ssh_host_ecdsa_key' >> /tmp/ssh_config/sshd_config && \
    echo 'HostKey /tmp/ssh_keys/ssh_host_ed25519_key' >> /tmp/ssh_config/sshd_config

# Ensure the SSH config file in /tmp has the correct permissions
RUN chmod 600 /tmp/ssh_config/sshd_config

# Expose port 8080 for SSH
EXPOSE 8080

# Start SSH service using the custom configuration and key locations in /tmp
CMD ["/usr/sbin/sshd", "-D", "-f", "/tmp/ssh_config/sshd_config"]
