#!/bin/bash
set -e

# Resolve script and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load config from project root
source "$PROJECT_ROOT/build/config.env"

# Validate required config
: "${SRC_DIRECTORY:?Missing SRC_DIRECTORY in config.env}"
: "${OUTPUT_FILENAME_WINDOWS:?Missing OUTPUT_FILENAME_WINDOWS in config.env}"
: "${ARTIFACTS_DIRECTORY_WINDOWS:?Missing ARTIFACTS_DIRECTORY_WINDOWS in config.env}"
: "${TARGET_DIRECTORY_WINDOWS:?Missing TARGET_DIRECTORY_WINDOWS in config.env}"
: "${ENTRYPOINT:?Missing ENTRYPOINT in config.env}"
: "${SDL_WINDOWS_PATH:?Missing SDL_WINDOWS_PATH in config.env}"

# Resolve to absolute paths
SRC_DIRECTORY="$PROJECT_ROOT/$SRC_DIRECTORY"
ENTRYPOINT="$PROJECT_ROOT/$ENTRYPOINT"
ARTIFACTS_DIRECTORY_WINDOWS="$PROJECT_ROOT/$ARTIFACTS_DIRECTORY_WINDOWS"
TARGET_DIRECTORY_WINDOWS="$PROJECT_ROOT/$TARGET_DIRECTORY_WINDOWS"
SDL_PATH="$PROJECT_ROOT/$SDL_WINDOWS_PATH"

# Create output directories
mkdir -p "$ARTIFACTS_DIRECTORY_WINDOWS" "$TARGET_DIRECTORY_WINDOWS"

# Track sources
declare -a all_sources=("$ENTRYPOINT")
declare -a processed_files=()

find_sources() {
    local file=$1
    local includes
    includes=$(grep -E '^#include\s*".*"' "$file" | sed -E 's/#include\s+"([^"]+)".*/\1/')

    for header in $includes; do
        local src_path="${header/include/src}"
        src_path="${src_path%.h}.cpp"
        local full_cpp="$SRC_DIRECTORY/$src_path"

        if [[ -f "$full_cpp" && ! " ${all_sources[*]} " =~ " $full_cpp " ]]; then
            all_sources+=("$full_cpp")
        fi
    done
}

# Recursively find dependencies
while :; do
    new_files=()
    for file in "${all_sources[@]}"; do
        if [[ ! " ${processed_files[*]} " =~ " $file " ]]; then
            find_sources "$file"
            processed_files+=("$file")
            new_files+=("$file")
        fi
    done
    [[ ${#new_files[@]} -eq 0 ]] && break
done

# Compiler settings
CXX=x86_64-w64-mingw32-g++
CXXFLAGS="-std=c++17 -I$SDL_PATH/include -I$SRC_DIRECTORY/include"
LDFLAGS="-L$SDL_PATH/lib -lmingw32 -lSDL2main -lSDL2 -mwindows"
BUILD_MODE="${1:-release}"

if [[ "$BUILD_MODE" == "debug" ]]; then
    CXXFLAGS="$CXXFLAGS -g -O0 -DDEBUG"
else
    CXXFLAGS="$CXXFLAGS -O2 -DNDEBUG"
fi

# Compile sources
object_files=()
for src in "${all_sources[@]}"; do
    obj="$ARTIFACTS_DIRECTORY_WINDOWS/$(basename "${src%.cpp}.o")"

    if [[ ! -f "$obj" || "$src" -nt "$obj" ]]; then
        echo "Compiling $src → $obj"
        $CXX $CXXFLAGS -c "$src" -o "$obj"
    fi

    object_files+=("$obj")
done

# Link to final Windows binary
output_path="$TARGET_DIRECTORY_WINDOWS/$OUTPUT_FILENAME_WINDOWS"
echo "Linking → $output_path"
$CXX "${object_files[@]}" -o "$output_path" $LDFLAGS

if [[ ! -s "$output_path" ]]; then
    echo "Error: Output file missing or empty."
    exit 1
fi

# Optional execution via PowerShell
for arg in "$@"; do
    if [[ "$arg" =~ ^(-e|--execute|e|execute)$ ]]; then
        echo "Launching $output_path in PowerShell..."
        win_path=$(wslpath -w "$output_path")
        powershell.exe -NoProfile -NonInteractive -Command "Start-Process '$win_path'" || {
            echo "Failed to launch."
            exit 1
        }
        break
    fi
done

