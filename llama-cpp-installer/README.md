# Modular Llama.cpp Server Installer

This project provides a set of modular, automated shell scripts to deploy a high-performance `llama.cpp` inference server on a fresh Ubuntu system. It includes Nginx as a reverse proxy, a systemd service for robust process management, and a powerful local testing environment using LXC/LXD.

## Features

- **Automated Deployment**: Go from a clean Ubuntu server to a running AI inference API in one command.
- **Modular Architecture**: Scripts are organized by function (system init, Nginx, Llama.cpp), making them easy to understand, modify, or extend.
- **Configurable Models**: Easily select which GGUF models to download and serve by editing a central configuration file.
- **Nginx Reverse Proxy**: Sets up Nginx to proxy requests to the `llama.cpp` server, enabling easy SSL termination and routing.
- **Secure by Default**: Automatically generates a secure API key for the `llama.cpp` server.
- **Robust Process Management**: Creates and enables a `systemd` service to ensure the `llama.cpp` server runs reliably and restarts on failure.
- **Integrated LXC/LXD Testing**: Includes a `local-test.sh` script to build and test the entire installation in a clean, isolated container, ensuring predictable and repeatable deployments.

---

## Prerequisites

### For Production Deployment
- A server running 24.04.
- Root or `sudo` access.

### For Local Testing
- A local machine with **LXD** installed. If you don't have it, you can install it easily:
  ```bash
  sudo snap install lxd
  sudo lxd init --auto
  ```

---

## How to Use

### 1. Production Deployment

Follow these steps to deploy the server on a live production machine.

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url>
    cd llama-cpp-installer
    ```

2.  **Configure the Installer:**
    Open `installer.sh` and edit the configuration variables:
    - Set `SERVER_NAME` to your server's public domain name (e.g., `api.mydomain.com`).
    - In the `models` array, uncomment or add the models you wish to download and serve.

    ```shellscript
    # installer.sh

    # ...
    export SERVER_NAME="your.domain.com"

    declare -A models=(
        # Uncomment the models you want to use
        ["qwen3-0.6b"]="https://huggingface.co/unsloth/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-BF16.gguf"
        # ["phi4-mini"]="https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-Q6_K.gguf"
    )
    # ...
    ```

3.  **Run the Installer:**
    Execute the script with `sudo`. It will run all the modules in order.
    ```bash
    sudo ./installer.sh
    ```

4.  **Get Your API Key:**
    Once the installation is complete, the API key will be stored on the server. Retrieve it with:
    ```bash
    sudo cat /home/app/site/llamacpp/api_key.txt
    ```

5.  **Test the API:**
    You can now make requests to your server. Replace `YOUR_DOMAIN` and `YOUR_API_KEY`.
    ```bash
    curl http://YOUR_DOMAIN/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer YOUR_API_KEY" \
      -d '{
        "model": "qwen3-0.6b",
        "messages": [{"role": "user", "content": "Explain the importance of modular software design."}]
      }'
    ```

### 2. Local Testing with LXC/LXD

The `local-test.sh` script is the recommended way to test changes or run a local instance of the server without affecting your host system.

> ### A Cheer for the Infra Team!
> A huge shout-out to our infrastructure colleagues and the developers behind **LXC/LXD**. This local testing workflow is made possible by the power and simplicity of system containers, allowing us to spin up clean, isolated, and fully-featured Ubuntu environments in seconds. It's a fantastic tool for ensuring our deployments are robust, repeatable, and bug-free before they ever touch production. **Cheers!**

1.  **Run the Test Script:**
    From the project root, simply execute the script. It requires no arguments.
    ```bash
    bash ./local-test.sh
    ```
    The script will:
    - Create a minimal Ubuntu image to speed up future runs.
    - Launch a new container named `llama-cpp-test`.
    - Mount the project directory into the container at `/app`.
    - Forward ports from your host to the container (`8080` -> `80`, `8081` -> `8081`).
    - Execute the `installer.sh` script inside the container.

2.  **Interact with the Test Container:**
    The script will output helpful commands when it finishes.
    - **Test the Web Server**: Open `http://localhost:8080` in your browser.
    - **Get the API Key**: `lxc exec llama-cpp-test -- cat /home/app/site/llamacpp/api_key.txt`
    - **Test the API**: Use `http://localhost:8081` as the endpoint for your `curl` command.
    - **Get a Shell**: `lxc exec llama-cpp-test -- bash`
    - **Stop the Container**: `lxc stop llama-cpp-test`
    - **Delete the Container**: `lxc delete --force llama-cpp-test`

---

## Project Structure

```
├── 00-system-init/       # System setup, user creation, dependencies
├── 01-nginx-installer/   # Nginx installation and reverse proxy configuration
├── 02-llamacpp-installer/  # Clones, compiles, and sets up llama.cpp as a service
├── installer.sh          # Main entry point, runs all modules
├── local-test.sh         # LXC/LXD script for isolated local testing
└── README.md             # This file
```

## Extending the Installer

To add a new installation step (e.g., installing a database), simply create a new numbered directory and add an `install.sh` script inside it. The main `installer.sh` will automatically pick it up and execute it in order.

**Example: `03-redis-installer/install.sh`**
```bash
#!/bin/bash
set -e
echo "--- Installing Redis ---"
apt-get update
apt-get install -y redis-server
systemctl enable --now redis-server
echo "--- Finished Redis installation ---"
```

## Authored

Copyright (c) 2025 Andy Setiyawan