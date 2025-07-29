# Automated Server Deployment Scripts

![Language](https://img.shields.io/badge/language-Shell-blue.svg)

This repository is a collection of robust and modular shell script frameworks designed to automate the setup of production-ready server environments on fresh Ubuntu systems. Each project emphasizes simplicity, reusability, and painless local testing, allowing you to go from a clean OS to a fully configured service with a single command.

## Core Philosophy

All projects in this collection are built upon a few key principles:

*   **Fully Automated**: From initial system updates and security hardening to complete application configuration.
*   **Modular Architecture**: Functionality is broken down into numbered directories (e.g., `00-system-init`, `01-nginx-installer`). This makes the process transparent and easy to extend—simply add a new numbered directory with an `install.sh` script.
*   **Centralized Configuration**: Key variables like domain names and user accounts are defined in a single `installer.sh` file for easy customization.
*   **Painless Local Testing**: Every project includes a powerful `local-test.sh` script that leverages LXC/LXD to run the entire installation in a clean, isolated container.

---

## A Massive Cheer for Local-First Infrastructure! 🚀

A huge shout-out to our beloved infrastructure colleagues and the incredible developers behind **LXC/LXD** technology!

The `local-test.sh` script included in each project is a testament to the power of having production-like environments on your local machine. By creating lightweight, OS-level containers, LXD allows us to test our deployment scripts with confidence, speed, and isolation. This philosophy bridges the gap between development and production, squashes "it works on my machine" bugs, and empowers developers to own their deployment pipeline from start to finish.

So, here's to the infra guys who champion these tools. **Cheers for making our lives easier and our deployments more reliable!**

---

## Projects

Here are the available installer projects:

### 1. Modular Nginx Installer

A framework for automatically setting up a production-ready Nginx web server on a fresh Ubuntu 24.04 system.

*   **Features**: System hardening, custom error pages, log rotation, and a secure default configuration.
*   **Details**: View Nginx Installer README

### 2. Modular Llama.cpp Server Installer

Automated scripts to deploy a high-performance `llama.cpp` inference server, complete with Nginx as a reverse proxy and a robust systemd service.

*   **Features**: GGUF model selection via config, automatic API key generation, process management with systemd, and Nginx reverse proxy setup.
*   **Details**: View Llama.cpp Installer README

## How to Use

Please refer to the `README.md` file within each project directory for specific setup and usage instructions.

## Authored

Copyright (c) 2025 Andy Setiyawan