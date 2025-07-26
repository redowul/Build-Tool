#!/bin/bash
set -euo pipefail

# Absolute path to this script's directory (build/)
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$BUILD_DIR/.." && pwd)"

# Load build configuration
source "$BUILD_DIR/config.env"

# Usage info
show_usage() {
    echo "Usage: $0 [linux|windows|l|w] [-e|--execute]"
    echo "  l | linux     Build for Linux"
    echo "  w | windows   Build for Windows"
    echo "  -e | --execute  Run the result after building"
    exit 1
}

# Require at least one argument
[[ $# -lt 1 ]] && show_usage

# Resolve build script path
case "$1" in
    l | linux)
        build_script="$PROJECT_ROOT/$BUILD_SCRIPT_LINUX"
        ;;
    w | windows)
        build_script="$PROJECT_ROOT/$BUILD_SCRIPT_WINDOWS"
        ;;
    *)
        show_usage
        ;;
esac

# Confirm script exists
if [[ ! -f "$build_script" ]]; then
    echo "Build script not found: $build_script"
    exit 1
fi

# Shift the first arg ("l" or "w") and forward the rest
shift
exec bash "$build_script" "$@"
