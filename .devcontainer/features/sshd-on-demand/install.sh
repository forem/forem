#!/usr/bin/env bash
# Installs OpenSSH server so `gh codespace ssh`, `cp` and `logs` work, without an always-on daemon.
#
# Unlike ghcr.io/devcontainers/features/sshd, this feature has no entrypoint, so sshd does not
# start when the container starts.  In a Codespace, the CLI asks the Codespaces agent to start
# the server.  On a local devcontainer (host networking on Linux) nothing listens.  If sshd is
# started, it listens on loopback only, accepts keys only and refuses passwords.
set -euo pipefail

SSHD_PORT=2222

export DEBIAN_FRONTEND=noninteractive
if ! dpkg -s openssh-server >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y --no-install-recommends openssh-server
    rm -rf /var/lib/apt/lists/*
fi

mkdir -p /var/run/sshd /etc/ssh/sshd_config.d
# Containers have no login uid; without this, PAM rejects the session.
sed -i 's/session\s*required\s*pam_loginuid\.so/session optional pam_loginuid.so/g' /etc/pam.d/sshd
# Same port as the upstream feature, set in the main file.
sed -i -E "s/^#*\s*Port\s+.+/Port ${SSHD_PORT}/" /etc/ssh/sshd_config
if ! grep -qE '^Include /etc/ssh/sshd_config.d/\*\.conf' /etc/ssh/sshd_config; then
    sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config
fi

# sshd keeps the first value it reads for each keyword, and the Include line comes first,
# so these settings win over the defaults in the main file.
cat > /etc/ssh/sshd_config.d/00-forem-devcontainer.conf <<CONF
Port ${SSHD_PORT}
ListenAddress 127.0.0.1
ListenAddress ::1
PermitRootLogin prohibit-password
PasswordAuthentication no
PermitEmptyPasswords no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
GatewayPorts no
UsePAM yes
CONF

# Validate the generated configuration at build time without starting the daemon.
sshd -t

# Do not start sshd here.
