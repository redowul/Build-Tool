#!/bin/bash
set -euo pipefail

# Get the absolute path to the build/ directory
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration values
source "$BUILD_DIR/config.env"

# Show usage info
show_usage() {
    echo "Usage: $0 [linux|windows|l|w] [-e|--execute]"
    echo "  l | linux     Build for Linux"
    echo "  w | windows   Build for Windows"
    echo "  -e | --execute  Run the result after building"
    exit 1
}

# Require at least one argument (the platform)
[[ $# -lt 1 ]] && show_usage

# Choose the appropriate build script based on the platform
case "$1" in
    l | linux)
        build_script="$BUILD_SCRIPT_LINUX"
        ;;
    w | windows)
        build_script="$BUILD_SCRIPT_WINDOWS"
        ;;
    *)
        show_usage
        ;;
esac

# Check for optional --execute flag
execute_flag=""
if [[ "${2:-}" =~ ^(-e|--execute|e|execute)$ ]]; then
    execute_flag="execute"
fi

# Run the build
exec bash "$build_script" $execute_flag