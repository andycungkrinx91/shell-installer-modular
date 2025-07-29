#!/bin/bash

# installer.sh - Main installer script to run modular installation scripts.

log() {
    echo "--- $1 ---"
}

main() {
    # Exit immediately if a command exits with a non-zero status.
    set -e

    # --- Centralized Configuration ---
    # Define global settings here to be used by the installation modules.
    # These variables will be exported to the sub-scripts.
    export APP_USER="app"
    export SERVER_NAME="your.domain.com"
    log "Using SERVER_NAME=${SERVER_NAME}"
    # Add other global configurations for your modules here.
    # Example: export SOME_API_KEY="your-key"

    # --- Pre-flight Checks ---
    # Ensure the script is run with root privileges, as modules will perform installations.
    if [[ "${EUID}" -ne 0 ]]; then
        echo "ERROR: This script must be run with root privileges. Please use 'sudo ./installer.sh'." >&2
        exit 1
    fi

    # Get the absolute path of the directory where the script is located.
    # This ensures that the script can be run from anywhere.
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

    echo "Starting modular installation..."
    echo

    # Loop through all directories matching the pattern '??-*' in the script's directory.
    # The pattern ensures they are processed in lexicographical order (00, 01, 02, ...).
    for module_dir in "$SCRIPT_DIR"/??-*; do
        # Check if the path is a directory before proceeding
        [ ! -d "$module_dir" ] && continue

        local module_name
        module_name=$(basename "$module_dir")
        local install_script_path="$module_dir/install.sh"

        if [ -f "$install_script_path" ] && [ -x "$install_script_path" ]; then
            log "Executing module: ${module_name}"
            # Execute in a subshell, changing to the module directory first.
            # This allows scripts to use relative paths to their own files.
            if (cd "$module_dir" && ./install.sh); then
                log "Finished module: ${module_name}"
            else
                echo "ERROR: Module ${module_name} failed to execute."
                exit 1
            fi
            echo
        else

            echo "--- Skipping module ${module_name}: 'install.sh' not found or not executable. ---"
            echo
        fi
    done

    log "Installation complete."
    echo
    echo "The server has been successfully configured."
    echo "  - Nginx is serving your site at: http://${SERVER_NAME}"

}

# Run the main function, passing all script arguments to it.
main "$@"