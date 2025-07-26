#!/bin/bash
set -euo pipefail

# Absolute path to this script's directory (chisel/build)
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$BUILD_DIR/.." && pwd)"

source "$BUILD_DIR/config.env"
# Show usage
show_usage() {
    echo "Usage: $0 [linux|windows|l|w] [-e|--execute]"
    echo "  l | linux     Build for Linux"
    echo "  w | windows   Build for Windows"
    echo "  -e | --execute  Run the result after building"
    exit 1
}

# Require at least one argument
[[ $# -lt 1 ]] && show_usage

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

# Optional execute flag
execute_flag=""
if [[ "${2:-}" =~ ^(-e|--execute|e|execute)$ ]]; then
    execute_flag="execute"
fi

# Confirm script exists
if [[ ! -f "$build_script" ]]; then
    echo "Build script not found: $build_script"
    exit 1
fi

# Execute it
exec bash "$build_script" $execute_flag
