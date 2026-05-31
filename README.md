# Building pico-fido2 with Docker/Podman

> [!WARNING]
> Only ESP-S3 was built and tested so far, in theory S2 should build with little issues. Pico might require some additional setup.

> [!NOTE]
> AI was used to generate a large portion of the files, some human corrections were made. Expect some jankyness as I did not keep best practises in mind for Docker / Podman / git usage.
> My main goal was to get my s3 in a working state, sharing these files now in there current state for the community to experiment with.

This guide explains how to build pico-fido2 firmware for Raspberry Pi Pico and ESP32 variants using Docker or Podman, keeping your host system clean.

## Prerequisites

- **Podman** and **podman-compose** installed
- or for **Docker** and *docker compose*: change the build.sh ```podman-compose``` command to ```docker compose```
- **Git** installed on the host

### Installation

**Podman + podman-compose (recommended for Linux):**
```bash
# Fedora/RHEL
sudo dnf install podman podman-compose

# Debian/Ubuntu
sudo apt install podman podman-compose

# Arch
sudo pacman -Syu podman podman-compose

# macOS
brew install podman podman-compose

### Initial Setup
```bash
# Make setup script executable
chmod +x build.sh

./build.sh
```

### Build Specific Target
```bash
# Build only PICO
BUILD_TYPE=PICO ./build.sh

# Build only ESP32 (S2 and S3)
BUILD_TYPE=ESP32 ./build.sh

# supported values: PICO, ESP32, ESP32-S3, ESP32-S2, ALL defaults to ALL
```

### Use .env
build.sh will load the .env next to it, if available. ./build.sh then uses these always.
```bash
BUILD_TYPE=ESP32
USB_VID=0x1D50
USB_PID=0x619B
```
or more specifically, only S3
```bash
BUILD_TYPE=ESP32-S3
USB_VID=0x1D50
USB_PID=0x619B
```

### Update Everything and Rebuild
```bash
./build.sh
```
---

## Key Features

- **Modular Build Types**: Control which firmware to build (PICO, ESP32, ESP32-S3, ESP32-S2 or ALL)
- **External SDK Management**: SDKs in `./sdks/` folder are persistent and reusable
- **Persistent Build Cache**: Build directory binds to host for incremental rebuilds
- **Setup Script**: Handles initial clone, submodule initialization, and updates
- **Flexible Configuration**: Environment variables control board type, USB IDs, build targets
- **Clean Separation**: Source code, SDKs, builds, and releases all in separate folders
- **Fast Rebuilds**: Subsequent runs skip cloning and reuse existing SDKs and build artifacts
