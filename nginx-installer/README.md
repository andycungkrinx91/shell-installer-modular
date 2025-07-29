# Modular Nginx Installer

![Language](https://img.shields.io/badge/language-Shell-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

This project provides a robust and modular framework for automatically setting up a production-ready Nginx web server on a fresh Ubuntu 24.04 system. Its design emphasizes simplicity, reusability, and painless local testing.

## Key Features

*   **Fully Automated**: From initial system updates and security hardening to a complete Nginx configuration.
*   **Modular Architecture**: Easily add or remove functionality by creating or deleting numbered directories (e.g., `02-database-installer`). The installer executes them in order.
*   **Centralized Configuration**: Key variables like domain names and user accounts are defined in one place (`installer.sh`).
*   **Production-Ready Defaults**: Includes beautiful custom error pages, security hardening (`sysctl`, `limits.conf`), and log rotation.
*   **Painless Local Testing**: A powerful `local-test.sh` script leverages LXC/LXD to spin up a clean, isolated Ubuntu container and run the entire installation process in seconds.

## A Nod to Local-First Infrastructure

A massive shout-out to our beloved infrastructure tool incredible **LXC/LXD** technology! 🚀

The `local-test.sh` script is a testament to the power of having production-like environments on your local machine. By creating lightweight, OS-level containers, LXD allows us to test our deployment scripts with confidence, speed, and isolation. This bridges the gap between development and production, squashes "it works on my machine" bugs, and empowers developers to own their deployment pipeline.

So, here's to the infra guys who champion these tools. **Cheers for making our lives easier and our deployments more reliable!**

## Project Structure

```
.
├── 00-system-init/
│   ├── install.sh      # System updates, package installation, user creation, security hardening.
│   └── src/            # Config files (sysctl.conf, limits.conf, etc.).
├── 01-nginx-installer/
│   ├── install.sh      # Installs and configures Nginx.
│   └── src/            # Nginx config files and HTML templates.
├── installer.sh        # The main entry point. Orchestrates the module execution.
├── local-test.sh       # Script to create and run the installer in a local LXC container.
└── README.md           # You are here!
```

## Usage Guide

### 1. Local Testing (Highly Recommended)

This is the safest and fastest way to see the installer in action.

**Prerequisites**: You need `git` and a working `lxc`/`lxd` installation.

```bash
# 1. Make the test script executable
chmod +x local-test.sh

# 2. Run the script!
./local-test.sh
```

The script will:
1.  Create a minimal Ubuntu 24.04 LXC image if it doesn't exist.
2.  Launch a new container named `nginx-test`.
3.  Mount the project directory into the container.
4.  Execute the `installer.sh` script inside the container.

Once finished, you can access the Nginx welcome page at **`http://localhost:8080`**.

To interact with the container:
```bash
# Get a shell inside the container
lxc exec nginx-test -- bash

# Stop the container
lxc stop nginx-test

# Delete the container
lxc delete --force nginx-test
```

### 2. Production Deployment

When you're ready to deploy to a live server:

**Prerequisites**: A fresh Ubuntu 24.04 server and `git`.

```bash
# 1. IMPORTANT: Configure your domain
#    Edit installer.sh and change the SERVER_NAME variable.
nano installer.sh
# Find and replace 'your.domain.com' with your actual domain.

# 2. Make the installer and modules executable
chmod +x installer.sh
chmod +x */install.sh

# 3. Run the installer with root privileges
sudo ./installer.sh
```

The script will configure your server. Once done, you can access your site at `http://your.domain.com`.

## Customization

The power of this project is its modularity.

*   **Adding a New Module**:
    1.  Create a new directory, e.g., `02-ufw-firewall/`. The number prefix determines the execution order.
    2.  Inside, create an `install.sh` script with your setup logic.
    3.  Make it executable: `chmod +x 02-ufw-firewall/install.sh`.
    The main `installer.sh` will automatically pick it up and run it.

*   **Modifying Configuration**:
    *   Global settings (like `APP_USER`) are in `installer.sh`.
    *   Module-specific files (like Nginx configs) are in the `src` directory of each module.

## Authored

Copyright (c) 2025 Andy Setiyawan
