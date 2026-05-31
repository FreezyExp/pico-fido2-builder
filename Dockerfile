FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# Build arguments for selective SDK installation
ARG INSTALL_PICO=true \
    INSTALL_ESP32=true \
    PICO_SDK_VERSION=2.1.1 \
    ESP_IDF_VERSION=v5.5

# Set SDK paths as environment variables
ENV PICO_SDK_PATH=/app/sdks/pico-sdk \
    ESP_IDF_PATH=/app/sdks/esp-idf \
    PATH="/app/sdks/esp-idf/tools/esp32s3:/app/sdks/esp-idf/tools/esp32s2:/app/sdks/esp-idf/tools:${PATH}"

# Install all system dependencies in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Common build tools
    git \
    wget \
    curl \
    cmake \
    ninja-build \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    ccache \
    pkg-config \
    make \
    # Pico SDK dependencies (ARM Cortex-M toolchain)
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    libstdc++-arm-none-eabi-newlib \
    # ESP32 SDK dependencies (Xtensa toolchain)
    flex \
    bison \
    gperf \
    libffi-dev \
    libssl-dev \
    dfu-util \
    libusb-1.0-0 \
    libudev-dev \
    # extra
    file \
    && rm -rf /var/lib/apt/lists/*

# Create SDK and build directories
RUN mkdir -p /app/sdks /app/build /app/release

# Create a non-root user for building
RUN useradd -m -s /bin/bash builder && \
    chown -R builder:builder /app

USER builder

WORKDIR /app

# Copy build script
COPY --chown=builder:builder docker-build.sh /app/
RUN chmod +x /app/docker-build.sh

# Set default entrypoint and command
ENTRYPOINT ["/app/docker-build.sh"]
CMD [""]
