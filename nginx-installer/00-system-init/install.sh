#!/bin/bash

# Exit on any error
set -e
# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during package installation
export DEBIAN_FRONTEND=noninteractive

echo "--- Ensuring dpkg is not locked and configured ---"
dpkg --configure -a

echo "--- Updating package lists ---"
apt-get update -y

echo "--- Upgrading packages ---"
apt-get upgrade -y

echo "--- Installing system dependencies ---"
apt-get install -y --no-install-recommends \
    tzdata \
    software-properties-common \
    wget \
    zip \
    net-tools \
    iputils-ping \
    apt-transport-https \
    dirmngr \
    ca-certificates \
    lsb-release \
    gpg-agent \
    gpg \
    gnupg2 \
    gnupg \
    certbot \
    python3-certbot-nginx \
    curl \
    unzip \
    git \
    ssh

# --- Configure Timezone to UTC ---
# This must be done *after* tzdata is installed to avoid errors.
echo "--- Configuring timezone to UTC ---"
ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

echo "--- Autoremoving unnecessary packages ---"
apt-get autoremove -y

## Setup system
echo "--- Copying system configurations ---"
cp -r src/sysctl.conf /etc/sysctl.conf
sysctl -p --ignore

## Time history
echo "--- Setting up time history ---"
echo 'export HISTTIMEFORMAT="%F %T "' >> /etc/profile
source /etc/profile
echo ". /etc/profile" >> ~/.bashrc
echo "--- Copying limits configuration ---"
cp -r src/limits.conf /etc/security/limits.conf
echo "--- Copying SSH configuration ---"
cp -r src/sshd_config /etc/ssh/sshd_config
echo "--- Copying PAM session configuration ---"
cp -r src/common-session /etc/pam.d/common-session

## Create User
echo "--- Creating user app ---"
readonly username="app"
if ! id -u "${username}" >/dev/null 2>&1; then
    echo "--- Adding user ${username} ---"
    useradd --create-home --shell /bin/bash "${username}"
    PASSWORD=$(openssl rand -base64 12)
    echo "--- Setting password for ${username} ---"
    echo "${username}:${PASSWORD}" | chpasswd
    passwd -e "${username}"
    echo "User ${username} created."
fi

usermod -aG sudo "${username}"
chsh -s /bin/bash "${username}"
echo "--- Creating site directory for ${username} ---"
mkdir -p /home/"${username}"/site
chown -R "${username}":"${username}" /home/"${username}"/site
echo "--- Finished system initialization ---"
