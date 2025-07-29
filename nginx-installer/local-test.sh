#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Use the 'ubuntu:' remote, which is specifically for official Ubuntu images
# and can be more reliable. The alias for 24.04 on this remote is just '24.04'.
readonly BASE_IMAGE="ubuntu:24.04"
readonly TEMP_CONTAINER_NAME="min-ubuntu-builder"
# Use a hyphen in the alias, as a colon makes LXC interpret it as 'remote:image'.
readonly NEW_IMAGE_ALIAS="minimal-ubuntu-24.04"
readonly CONTAINER_NAME="nginx-test"

# --- Helper Functions ---
log() {
    echo "--- $1 ---"
}

# --- Main Logic ---

# Part 1: Ensure the minimal image exists, creating it if necessary.
if ! lxc image info "$NEW_IMAGE_ALIAS" &>/dev/null; then
    log "Minimal image '$NEW_IMAGE_ALIAS' not found. Creating it now..."

    # Clean up temp builder container if it exists from a failed previous run
    if lxc info "$TEMP_CONTAINER_NAME" &>/dev/null; then
        lxc delete --force "$TEMP_CONTAINER_NAME"
    fi

    log "Creating a temporary container from '$BASE_IMAGE' to build the minimal image..."
    lxc launch "$BASE_IMAGE" "$TEMP_CONTAINER_NAME"

    log "Waiting for the temporary container to boot..."
    lxc exec "$TEMP_CONTAINER_NAME" -- cloud-init status --wait

    log "Shrinking the container by removing non-essential files..."
    lxc exec "$TEMP_CONTAINER_NAME" -- bash -c '
        set -ex
        apt-get -y autoremove --purge
        apt-get clean
        rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* /usr/share/locale/*
        rm -rf /var/lib/apt/lists/* /var/cache/apt/*
        find /var/log -type f -exec truncate -s 0 {} \;
    '

    log "Stopping the temporary container..."
    lxc stop "$TEMP_CONTAINER_NAME"

    log "Publishing the container as a new image: '$NEW_IMAGE_ALIAS'..."
    # The --public flag is not needed for a local image.
    lxc publish "$TEMP_CONTAINER_NAME" --alias "$NEW_IMAGE_ALIAS"

    log "Cleaning up the temporary container..."
    lxc delete "$TEMP_CONTAINER_NAME"

    echo
    log "Success! Minimal image '$NEW_IMAGE_ALIAS' has been created."
else
    log "Minimal image '$NEW_IMAGE_ALIAS' already exists. Skipping creation."
fi

# Part 2: Run the test environment using the minimal image.
readonly PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

log "Starting LXC test environment for project in: $PROJECT_DIR"

# Clean up any previous container with the same name for a fresh start.
if lxc info "$CONTAINER_NAME" &>/dev/null; then
    log "Found existing '$CONTAINER_NAME' container. Deleting it for a clean run."
    lxc delete --force "$CONTAINER_NAME"
fi

log "Launching new container '$CONTAINER_NAME' from image '$NEW_IMAGE_ALIAS'..."
lxc launch "$NEW_IMAGE_ALIAS" "$CONTAINER_NAME"

log "Configuring container..."
lxc config device add "$CONTAINER_NAME" app-scripts disk source="$PROJECT_DIR" path=/app
lxc config device add "$CONTAINER_NAME" http-proxy proxy listen=tcp:0.0.0.0:8080 connect=tcp:127.0.0.1:80
lxc config device add "$CONTAINER_NAME" https-proxy proxy listen=tcp:0.0.0.0:8443 connect=tcp:127.0.0.1:443

log "Waiting for container to boot and initialize..."
lxc exec "$CONTAINER_NAME" -- cloud-init status --wait

log "Ensuring installer script is executable..."
# Make the main installer executable.
chmod +x "$PROJECT_DIR/installer.sh"
# Also make all the modular install scripts executable.
chmod +x "$PROJECT_DIR"/??-*/install.sh

log "Executing installer script inside the container..."
# The installer will run and print its own logs, including the location of the API key.
lxc exec "$CONTAINER_NAME" -- /app/installer.sh

echo
echo "The installer has finished. The summary above provides instructions for a production server."
echo "For this test environment, access the web server at: http://localhost:8080"
echo "To get a shell inside the container, run: lxc exec $CONTAINER_NAME -- bash"
echo "To stop the container, run: lxc stop $CONTAINER_NAME"
echo "To delete the container, run: lxc delete --force $CONTAINER_NAME"
