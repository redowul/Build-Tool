# Bash-Based C++ Build System (Linux + Windows)

This repository contains a flexible build system for C++ applications using **Bash** and **g++**. It supports both native Linux builds and cross-compilation for Windows using MinGW-w64.

The system automatically resolves source dependencies via `#include` directives, recompiles only changed files, and supports optional execution after build.

---

## Requirements

### General (Linux)
- `bash`
- `g++` (with C++17 support)
- `grep`, `sed`, `mkdir`, `find` (standard UNIX utilities)
- `libsdl2-dev`

Install SDL2 on Debian/Ubuntu:

```bash
sudo apt install libsdl2-dev
```

### Cross-Compilation (Windows)
- **MinGW-w64**: A toolchain for compiling Windows applications on Linux.
Install MinGW-w64:
```bash
# Fedora
sudo dnf install mingw64-gcc-c++

# Ubuntu/Debian
sudo apt install g++-mingw-w64-x86-64
```

### Usage
```bash
./build/build.sh [platform]
```

Where `[platform]` can be:
- `l` or `linux` for Linux builds
- `w` or `windows` for Windows builds