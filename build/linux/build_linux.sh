#!/bin/bash
set -e

# Resolve script and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load configuration from project root
source "$PROJECT_ROOT/build/config.env"

# Validate required config variables
: "${SRC_DIRECTORY:?Missing SRC_DIRECTORY in config.env}"
: "${OUTPUT_FILENAME_LINUX:?Missing OUTPUT_FILENAME_LINUX in config.env}"
: "${ARTIFACTS_DIRECTORY_LINUX:?Missing ARTIFACTS_DIRECTORY_LINUX in config.env}"
: "${TARGET_DIRECTORY_LINUX:?Missing TARGET_DIRECTORY_LINUX in config.env}"
: "${ENTRYPOINT:?Missing ENTRYPOINT in config.env}"

# Resolve all config paths to absolute paths
SRC_DIRECTORY="$PROJECT_ROOT/$SRC_DIRECTORY"
ENTRYPOINT="$PROJECT_ROOT/$ENTRYPOINT"
ARTIFACTS_DIRECTORY_LINUX="$PROJECT_ROOT/$ARTIFACTS_DIRECTORY_LINUX"
TARGET_DIRECTORY_LINUX="$PROJECT_ROOT/$TARGET_DIRECTORY_LINUX"

# Create build output directories
mkdir -p "$ARTIFACTS_DIRECTORY_LINUX" "$TARGET_DIRECTORY_LINUX"

# Track all source files
declare -a all_sources=("$ENTRYPOINT")
declare -a processed_files=()

find_sources() {
    local file=$1

    # Look for local includes (e.g., #include "foo/bar.hpp")
    local includes
    includes=$(grep -E '^#include\s*".*"' "$file" | sed -E 's/#include\s+"([^"]+)".*/\1/')

    for header in $includes; do
        # Convert include path to .cpp source path
        local src_path="${header/include/src}"
        src_path="${src_path%.h}.cpp"
        local full_cpp="$SRC_DIRECTORY/$src_path"

        # Avoid duplicates
        if [[ -f "$full_cpp" && ! " ${all_sources[*]} " =~ " $full_cpp " ]]; then
            all_sources+=("$full_cpp")
        fi
    done
}

# Recursively find all dependent source files
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

# Compiler flags
CXXFLAGS="-std=c++17 -I$SRC_DIRECTORY/include"
LDFLAGS="-lSDL2 -lSDL2main"
BUILD_MODE="${1:-release}"

if [[ "$BUILD_MODE" == "debug" ]]; then
    CXXFLAGS="$CXXFLAGS -g -O0 -DDEBUG"
else
    CXXFLAGS="$CXXFLAGS -O2 -DNDEBUG"
fi

# Compile all sources
object_files=()
for src in "${all_sources[@]}"; do
    obj="$ARTIFACTS_DIRECTORY_LINUX/$(basename "${src%.cpp}.o")"

    if [[ ! -f "$obj" || "$src" -nt "$obj" ]]; then
        echo "Compiling $src → $obj"
        g++ $CXXFLAGS -c "$src" -o "$obj"
    fi

    object_files+=("$obj")
done

# Link final binary
output_path="$TARGET_DIRECTORY_LINUX/$OUTPUT_FILENAME_LINUX"
echo "Linking → $output_path"
g++ "${object_files[@]}" -o "$output_path" $LDFLAGS

# Confirm output exists
if [[ ! -s "$output_path" ]]; then
    echo "Error: Output file missing or empty."
    exit 1
fi

# Optional execution
for arg in "$@"; do
    if [[ "$arg" =~ ^(-e|--execute|e|execute)$ ]]; then
        echo "Running $output_path..."
        "$output_path"
        break
    fi
done
