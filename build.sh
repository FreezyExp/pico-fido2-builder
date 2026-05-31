#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Load environment variables from .env if it exists
if [ -f "$(dirname "$0")/.env" ]; then
    echo -e "${BLUE}Loading configuration from .env${NC}"
    export $(grep -v '^#' "$(dirname "$0")/.env" | xargs)
fi

# Set defaults if not in .env
BUILD_TYPE="${BUILD_TYPE:-ALL}"
PICO_BOARD="${PICO_BOARD:-pico}"
USB_VID="${USB_VID:-0x1D50}"
USB_PID="${USB_PID:-0x619B}"

echo -e "${BLUE}=== Pico-FIDO2 Build Environment ===${NC}\n"
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Build Type: $BUILD_TYPE"
echo -e "  Pico Board: $PICO_BOARD"
echo -e "  USB VID: $USB_VID"
echo -e "  USB PID: $USB_PID\n"

# Create directory structure
mkdir -p src sdks release home

# Setup pico-fido2 repository
if [ ! -d "src/pico-fido2" ]; then
    echo -e "${BLUE}Cloning pico-fido2 repository...${NC}"
    git clone https://github.com/librekeys/pico-fido2 src/pico-fido2
    cd src/pico-fido2
    git submodule update --init --recursive
    cd ../..
else
    echo -e "${BLUE}Updating pico-fido2 repository...${NC}"
    cd src/pico-fido2
    git pull
    git submodule update --init --recursive
    cd ../..
fi

# Setup Pico SDK (if building for PICO or ALL)
if [[ "$BUILD_TYPE" =~ ^(PICO|ALL)$ ]]; then
    if [ ! -d "sdks/pico-sdk" ]; then
        echo -e "${BLUE}Cloning Pico SDK...${NC}"
        git clone https://github.com/raspberrypi/pico-sdk.git sdks/pico-sdk
        cd sdks/pico-sdk
        git submodule update --init --recursive
        cd ../..
    else
        echo -e "${BLUE}Updating Pico SDK...${NC}"
        cd sdks/pico-sdk
        git fetch origin
        git submodule update --init --recursive
        cd ../..
    fi
fi

# Setup ESP-IDF (if building for ESP32 or ALL)
if [[ "$BUILD_TYPE" =~ ^(ESP32|ESP32-S3|ESP32-S2|ALL)$ ]]; then
    if [ ! -d "sdks/esp-idf" ]; then
        echo -e "${BLUE}Cloning ESP-IDF v5.5...${NC}"
        git clone --recursive https://github.com/espressif/esp-idf.git sdks/esp-idf
        cd sdks/esp-idf
        git checkout tags/v5.5
        cd ../..
    else
        echo -e "${BLUE}Updating ESP-IDF to v5.5...${NC}"
        cd sdks/esp-idf

        # Remove the problematic openthread submodule directory entirely
        rm -rf components/openthread/openthread

        # Clean everything recursively
        git submodule foreach --recursive git clean -fdx
        git submodule foreach --recursive git reset --hard HEAD
        git clean -fdx
        git reset --hard HEAD

        # Fetch latest refs
        git fetch origin

        # Checkout tag
        git checkout tags/v5.5

        # Reinitialize and update all submodules (including nested ones)
        git submodule update --init --recursive --force

        cd ../..
    fi
fi

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${BLUE}Starting Docker build...${NC}\n"

# Run podman-compose
export BUILD_TYPE
export PICO_BOARD
export USB_VID
export USB_PID

if ! command -v podman-compose &> /dev/null; then
    echo -e "${RED}Error: podman-compose not found${NC}"
    exit 1
fi

podman-compose up --build

echo -e "${GREEN}=== Build complete ===${NC}"
echo -e "${YELLOW}Release artifacts:${NC}"
ls -lh release/
