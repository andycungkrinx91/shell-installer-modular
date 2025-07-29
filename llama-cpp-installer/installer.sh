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

    # Define the models to be installed by the llamacpp module.
    declare -A models=(
        ## Local/devsite test ##
        ["qwen3-0.6b"]="https://huggingface.co/unsloth/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-BF16.gguf"
        # ["qwen2.5-coder-0.5b"]="https://huggingface.co/unsloth/Qwen2.5-Coder-0.5B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-0.5B-Instruct-F16.gguf"
        # ["gemma-3-1b"]="https://huggingface.co/unsloth/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q5_K_M.gguf"
        # ["llama3.2-1b"]="https://huggingface.co/unsloth/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q5_K_S.gguf"
        ### Production ###
        # ["gemma-3-12b"]="https://huggingface.co/unsloth/gemma-3-12b-it-GGUF/resolve/main/gemma-3-12b-it-Q4_0.gguf"
        # ["qwen3-8b"]="https://huggingface.co/unsloth/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-UD-Q4_K_XL.gguf"
        # ["qwen3-14b"]="https://huggingface.co/unsloth/Qwen3-14B-GGUF/resolve/main/Qwen3-14B-UD-Q4_K_XL.gguf"
        # ["deepseek-r1-qwen3-8b"]="https://huggingface.co/unsloth/DeepSeek-R1-0528-Qwen3-8B-GGUF/resolve/main/DeepSeek-R1-0528-Qwen3-8B-Q5_K_S.gguf"
        # ["deepseek-r1-llama-8b"]="https://huggingface.co/unsloth/DeepSeek-R1-Distill-Llama-8B-GGUF/resolve/main/DeepSeek-R1-Distill-Llama-8B-UD-Q4_K_XL.gguf"
        # ["phi4-mini"]="https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-Q6_K.gguf"
        # ["phi4-mini-reasoning"]="https://huggingface.co/unsloth/Phi-4-mini-reasoning-GGUF/resolve/main/Phi-4-mini-reasoning-UD-Q5_K_XL.gguf"
        # ["llama3.2-3b"]="https://huggingface.co/unsloth/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-UD-Q8_K_XL.gguf"
        # ["llama3.1-8b"]="https://huggingface.co/unsloth/Llama-3.1-8B-Instruct-GGUF/resolve/main/Llama-3.1-8B-Instruct-UD-Q4_K_XL.gguf"
        # ["openchat3.5"]="https://huggingface.co/TheBloke/openchat_3.5-GGUF/resolve/main/openchat_3.5.Q5_K_S.gguf"
        # ["mistral-7b"]="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.1-GGUF/resolve/main/mistral-7b-instruct-v0.1.Q4_K_M.gguf"
        # ["mistral-7b-claude"]="https://huggingface.co/TheBloke/Mistral-7B-Claude-Chat-GGUF/resolve/main/mistral-7b-claude-chat.Q5_K_S.gguf"
        # ["gpt4all-falcon"]="https://huggingface.co/tensorblock/gpt4all-falcon-GGUF/resolve/main/gpt4all-falcon-Q5_K_S.gguf"
        # ["airoboros-llama2-gpt4.1-7b"]="https://huggingface.co/TheBloke/airoboros-l2-7b-gpt4-1.4.1-GGUF/resolve/main/airoboros-l2-7b-gpt4-1.4.1.Q5_K_S.gguf"
        # ["airoboros-llama2-gpt4.2-7b"]="https://huggingface.co/TheBloke/airoboros-l2-7B-gpt4-2.0-GGUF/resolve/main/airoboros-l2-7B-gpt4-2.0.Q5_K_S.gguf"
        # ["kimi-k2"]="https://huggingface.co/ubergarm/Kimi-K2-Instruct-GGUF/resolve/main/mainline/imatrix-mainline-pr9400-plus-kimi-k2-942c55cd5-Kimi-K2-Instruct-Q8_0.gguf"
        # ["kimiko-claude"]="https://huggingface.co/mradermacher/Kimiko-Claude-FP16-GGUF/resolve/main/Kimiko-Claude-FP16.Q5_K_S.gguf"
    )
    # Export the array definition so it can be used by sub-scripts.
    export MODELS_CONFIG=$(declare -p models)

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
    echo "  - The Llama.cpp API is proxied through Nginx at the /v1/ path."
    echo
    echo "An API key was generated for the Llama.cpp server."
    echo "To retrieve it, log into the server and run:"
    echo "  sudo cat /home/${APP_USER}/site/llamacpp/api_key.txt"
    echo
    echo "Example curl command (replace YOUR_API_KEY and use your server's domain/IP):"
    echo "  curl http://${SERVER_NAME}/v1/chat/completions -H \"Content-Type: application/json\" -H \"Authorization: Bearer YOUR_API_KEY\" -d '{\"model\": \"qwen3-0.6b\", \"messages\": [{\"role\": \"user\", \"content\": \"How are you?\"}]}'"

}

# Run the main function, passing all script arguments to it.
main "$@"