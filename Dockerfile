# Use a base image for Void Linux
FROM ghcr.io/void-linux/void-glibc:latest

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

# Create directories and set correct ownership and permissions for containeruser
RUN mkdir -p /home/containeruser/.ssh /home/containeruser/ssh_keys && \
    chown -R containeruser:containeruser /home/containeruser/.ssh /home/containeruser/ssh_keys && \
    chmod 700 /home/containeruser/.ssh /home/containeruser/ssh_keys

# Switch to non-root user
USER containeruser

# Generate SSH host keys in the writable directory as the containeruser
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

# Ensure the SSH config file has the correct ownership and permissions
RUN chown containeruser:containeruser /home/containeruser/.ssh/sshd_config && \
    chmod 600 /home/containeruser/.ssh/sshd_config

# Expose port 8080 for SSH
EXPOSE 8080

# Start SSH service using the custom configuration and key locations
CMD ["/usr/sbin/sshd", "-D", "-f", "/home/containeruser/.ssh/sshd_config"]
