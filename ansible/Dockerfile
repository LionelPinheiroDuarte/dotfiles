# Test environment for the Ansible bootstrap playbook.
# Mimics a fresh Debian-based WSL install.
#
# Usage:
#   docker build -t dotfiles-test -f ansible/Dockerfile .
#   docker run --rm dotfiles-test

ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ansible \
    git \
    sudo \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user with passwordless sudo (mimics a real user on a fresh install)
RUN useradd -m -s /bin/bash testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
WORKDIR /home/testuser

# Copy dotfiles repo into the expected location
COPY --chown=testuser:testuser . /home/testuser/repos/github/dotfiles

CMD ["ansible-playbook", \
     "/home/testuser/repos/github/dotfiles/ansible/playbook.yml", \
     "-i", "/home/testuser/repos/github/dotfiles/ansible/inventory.ini"]
