#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

BUILD_TYPE="${BUILD_TYPE:-ALL}"
PICO_BOARD="${PICO_BOARD:-pico}"
USB_VID="${USB_VID:-0x1D50}"
USB_PID="${USB_PID:-0x619B}"

echo -e "${BLUE}=== Pico-FIDO2 Build Pipeline ===${NC}"
echo -e "${YELLOW}Build Type: $BUILD_TYPE${NC}"
echo -e "${YELLOW}Pico Board: $PICO_BOARD${NC}"
echo -e "${YELLOW}USB VID: $USB_VID, USB PID: $USB_PID${NC}\n"

cd /app/src/pico-fido2

mkdir -p /app/release

echo -e "${YELLOW}=== NEW ===${NC}\n"

# Build for PICO
if [[ "$BUILD_TYPE" =~ ^(PICO|ALL)$ ]]; then
    echo -e "${BLUE}=== Building for Raspberry Pi Pico ===${NC}\n"

    if [ ! -d "/app/build/pico" ]; then
        mkdir -p /app/build/pico
    fi

    cd /app/build/pico

    export PICO_SDK_PATH=/app/sdks/pico-sdk
    cmake /app/src/pico-fido2 \
        -DPICO_BOARD=$PICO_BOARD \
        -DUSB_VID=$USB_VID \
        -DUSB_PID=$USB_PID \
        -G Ninja

    ninja

    # Copy PICO build artifacts
    if [ -f "*.uf2" ]; then
        cp *.uf2 /app/release/ || true
    fi
    if [ -f "*.elf" ]; then
        cp *.elf /app/release/ || true
    fi

    echo -e "${GREEN}Pico build complete${NC}\n"
fi

# Build for ESP32-S3
if [[ "$BUILD_TYPE" =~ ^(ESP32-S3|ESP32|ALL)$ ]]; then
    echo -e "${BLUE}=== Building for ESP32-S3 ===${NC}\n"

    if [ ! -d "/app/build/esp32-s3" ]; then
        mkdir -p /app/build/esp32-s3
        mkdir -p /app/build/esp32-s3/build
    fi

    cd $ESP_IDF_PATH

    # Install ESP-IDF tools
    ./install.sh esp32s3
    source ./export.sh

    cd /app/src/pico-fido2/pico-fido/

    idf.py set-target esp32s3
    idf.py all
    mkdir -p build
    cd build

    esptool.py --chip ESP32-S3 merge_bin \
        -o /app/release/pico_fido_esp32-s3.bin \
        @flash_args

    echo -e "${GREEN}ESP32-S3 build complete${NC}\n"
fi

# Build for ESP32-S2
if [[ "$BUILD_TYPE" =~ ^(ESP32-S2|ESP32|ALL)$ ]]; then
    echo -e "${BLUE}=== Building for ESP32-S2 ===${NC}\n"

    cd $ESP_IDF_PATH
    ./install.sh esp32s2
    source ./export.sh

    cd /app/src/pico-fido2

    idf.py set-target esp32s2
    idf.py all

    mkdir -p build
    cd build

    esptool.py --chip ESP32-S2 merge_bin \
        -o /app/release/pico_fido_esp32-s2.bin \
        @flash_args

    echo -e "${GREEN}ESP32-S2 build complete${NC}\n"
fi

echo -e "${GREEN}=== All builds complete ===${NC}"
echo -e "${YELLOW}Release artifacts:${NC}"
ls -lh /app/release/
