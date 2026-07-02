FROM rust:slim AS builder

ARG TARGET=aarch64-apple-darwin

RUN apt-get update && apt-get install -y --no-install-recommends \
      wget xz-utils git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Zig is used as the macOS cross-linker — no macOS SDK required for pure Rust
RUN set -e; \
    ARCH="$(uname -m)"; \
    wget -q "https://ziglang.org/download/0.13.0/zig-linux-${ARCH}-0.13.0.tar.xz" \
    && tar xf "zig-linux-${ARCH}-0.13.0.tar.xz" \
    && mv "zig-linux-${ARCH}-0.13.0" /usr/local/zig \
    && rm "zig-linux-${ARCH}-0.13.0.tar.xz"
ENV PATH="/usr/local/zig:$PATH"

RUN cargo install cargo-zigbuild
RUN rustup target add "${TARGET}"

RUN git clone https://github.com/teamclouday/adb-wireless /build
WORKDIR /build
RUN cargo zigbuild --release --target "${TARGET}"

# Export stage: contains only the binary so the build script can docker cp it out
FROM scratch
ARG TARGET=aarch64-apple-darwin
COPY --from=builder /build/target/${TARGET}/release/adb-wireless /adb-wireless
