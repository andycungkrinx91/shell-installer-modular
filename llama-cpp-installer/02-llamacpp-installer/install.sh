#!/bin/bash

# Exit on any error
set -e

# --- Configuration ---
# The APP_USER is inherited from the main installer.sh script for consistency.
: "${APP_USER:?ERROR: APP_USER environment variable is not set. Please define it in the main installer.}"
readonly LLAMACPP_USER="${APP_USER}"
readonly LLAMACPP_HOME="/home/${APP_USER}/site/llamacpp"
readonly MODELS_PATH="${LLAMACPP_HOME}/models"
# Use a specific, stable tag of llama.cpp for reproducibility.
readonly LLAMACPP_VERSION="b6002"

# Save the module's root directory to ensure relative paths are handled correctly.
readonly MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# --- Helper Functions ---
log() {
    echo "--- $1 ---"
}

# --- Main Installation ---
log "Starting Llama.cpp installation..."
log "Installing build dependencies..."
# libopenblas-dev is required for compiling with BLAS support for better performance.
# bc is needed for floating-point math to calculate thread count.
apt-get update -y
apt-get install -y --no-install-recommends build-essential cmake git libopenblas-dev bc libcurl4-openssl-dev

log "Creating directories for Llama.cpp under ${LLAMACPP_HOME}"
mkdir -p "$LLAMACPP_HOME"
mkdir -p "$MODELS_PATH"
chown -R "${LLAMACPP_USER}":"${LLAMACPP_USER}" "${LLAMACPP_HOME}"

log "Cloning Llama.cpp repository (version ${LLAMACPP_VERSION})..."
# Clone the repository as the application user to ensure correct file ownership.
# The repository has been moved to the ggml-org organization.
sudo -u "${LLAMACPP_USER}" git clone --branch ${LLAMACPP_VERSION} https://github.com/ggml-org/llama.cpp.git "${LLAMACPP_HOME}/repo"

log "Compiling Llama.cpp server with OpenBLAS support..."
# Run the build process as the application user in a subshell.
# By running the entire build process within a 'sudo -u ... bash -c' block,
# we ensure that all commands (cd, mkdir, cmake) are executed by the correct user
# in a consistent environment, preventing permission and path issues.
readonly STAGING_DIR="/tmp/llamacpp-staging"
mkdir -p "$STAGING_DIR"
chown "${LLAMACPP_USER}":"${LLAMACPP_USER}" "$STAGING_DIR"

sudo -u "${LLAMACPP_USER}" bash -c '
    set -e
    cd "'"${LLAMACPP_HOME}"'/repo"
    mkdir -p build
    cd build
    cmake .. -DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS
    # Build all targets to ensure dependencies are met.
    cmake --build . --config Release -- -j"$(nproc)"
    # Use `cmake --install` to place the compiled binaries into a predictable
    # staging directory. This is more reliable than copying from the build tree.
    cmake --install . --prefix "'"$STAGING_DIR"'"
'

log "Installing the server binary and shared libraries..."
# Copy the server binary to a system path.
cp "${STAGING_DIR}/bin/llama-server" /usr/local/bin/llamacpp-server
# Copy the compiled shared libraries (like libmtmd.so) to the system's library path.
cp -r "${STAGING_DIR}/lib/"* /usr/local/lib/
# Update the dynamic linker's cache to recognize the new libraries.
ldconfig

rm -rf "$STAGING_DIR"

log "Downloading and configuring LLM models..."

# The MODELS_CONFIG is inherited from the main installer.sh script.
: "${MODELS_CONFIG:?ERROR: MODELS_CONFIG environment variable is not set. Please define it in the main installer.}"
# Recreate the associative array from the exported configuration.
eval "$MODELS_CONFIG"

# This will build the arguments for the server command, e.g., --model-alias qwen=... --model-alias gemma=...
server_model_args=""

# Check if the models array is empty after evaluation.
if [ ${#models[@]} -eq 0 ]; then
    log "No models defined in the main installer. Skipping model download."
else
    for model_name in "${!models[@]}"; do
        url="${models[$model_name]}"
        filename=$(basename "$url")
        filepath="${MODELS_PATH}/${filename}"

        log "Downloading ${model_name}..."
        # Download as the app user to ensure correct permissions from the start.
        sudo -u "${LLAMACPP_USER}" wget -q --show-progress --tries=5 --connect-timeout=600 -O "${filepath}" "$url"

        # Add the model to the server arguments using an alias.
        # Note the space at the end of the string.
        server_model_args+="--model-alias ${model_name}=${filepath} "
    done
fi

log "Generating a secure API key for the server..."
readonly API_KEY_PATH="${LLAMACPP_HOME}/api_key.txt"
# Use hex encoding instead of base64 to avoid special characters like '/' and '+'
# which can cause issues when passed as unquoted command-line arguments.
API_KEY=$(openssl rand -hex 32)
echo "${API_KEY}" | sudo -u "${LLAMACPP_USER}" tee "${API_KEY_PATH}" > /dev/null
# Ensure only the user can read the key.
sudo -u "${LLAMACPP_USER}" chmod 600 "${API_KEY_PATH}"

log "Setting up systemd service for Llama.cpp server..."
# Calculate the number of threads to use based on the user's request.
# The formula is (Total Cores - 1) * 1.5, rounded to the nearest integer.
TOTAL_CORES=$(nproc)
if [ "$TOTAL_CORES" -eq 1 ]; then
    CPU_THREADS=1
else
    # Use bc for floating point arithmetic.
    CPU_THREADS_FLOAT=$(echo "(${TOTAL_CORES} - 1) * 1.5" | bc)
    # Use printf to round the result to the nearest whole number.
    CPU_THREADS=$(printf "%.0f\n" "$CPU_THREADS_FLOAT")
fi

log "Configuring Llama.cpp server to use ${CPU_THREADS} threads on a ${TOTAL_CORES}-core system."

# Construct the full argument list for the server.
EXEC_ARGS="--host 127.0.0.1 --port 8081 --threads ${CPU_THREADS} ${server_model_args}--ctx-size 4096 --api-key ${API_KEY}"

# Create the final service file by replacing placeholders.
sed -e "s|__LLAMACPP_USER__|${LLAMACPP_USER}|g" \
    -e "s|__EXEC_ARGS__|${EXEC_ARGS}|g" \
    "${MODULE_DIR}/src/llamacpp.service" > /etc/systemd/system/llamacpp.service

log "Reloading systemd and starting Llama.cpp service"
systemctl daemon-reload
systemctl enable --now llamacpp.service

log "Llama.cpp installation complete."
echo "The Llama.cpp server should be running and accessible via the Nginx proxy."
echo "An API key has been generated for security."
echo "You can find the key at: ${API_KEY_PATH} (inside the container)"
echo "You can check its status with: systemctl status llamacpp.service"