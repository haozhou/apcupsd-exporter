# Build arguments for easy version updates.
# Upstream's last tag is v0.3.0 (2022); this commit (2025-08) adds the output
# amps metric and a newer apcupsd module. A tag name also works here.
ARG APCUPSD_REF=28b7412171d865777a1bb8c9358df081d50f2bba
ARG UPX_VERSION=5.2.1
ARG GO_VERSION=1.27.2

# Builder stage: runs natively on the CI host and cross-compiles for each
# target platform, so multi-arch builds don't need QEMU emulation.
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine3.24 AS builder

# ARGs declared before the first FROM must be re-declared to be visible here.
ARG APCUPSD_REF
ARG UPX_VERSION
ARG TARGETOS
ARG TARGETARCH
ARG BUILDARCH

# Install build dependencies
RUN apk add --no-cache git xz

# Fetch only the pinned upstream revision (works for both tags and commits)
WORKDIR /src
RUN git init -q && \
    git remote add origin https://github.com/mdlayher/apcupsd_exporter.git && \
    git fetch -q --depth 1 origin "${APCUPSD_REF}" && \
    git checkout -q FETCH_HEAD

# Download dependencies and build a static binary for the target platform
RUN go mod download && \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/apcupsd_exporter ./cmd/apcupsd_exporter

# Download UPX for the build host (it can compress binaries for any target arch)
ADD https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-${BUILDARCH}_linux.tar.xz /tmp/upx.tar.xz
RUN xz -d -c /tmp/upx.tar.xz | tar -xOf - upx-${UPX_VERSION}-${BUILDARCH}_linux/upx > /bin/upx && \
    chmod a+x /bin/upx && \
    rm /tmp/upx.tar.xz

# Compress the binary, then verify the compressed file decompresses cleanly
RUN upx --best --lzma /out/apcupsd_exporter && upx -t /out/apcupsd_exporter

# Runtime stage - use distroless for minimal attack surface
FROM gcr.io/distroless/static-debian13:nonroot

# Metadata
LABEL maintainer="Henry Zhou <henryzhou2008@gmail.com>" \
      org.opencontainers.image.title="apcupsd-exporter" \
      org.opencontainers.image.description="Prometheus exporter for apcupsd UPS statistics" \
      org.opencontainers.image.source="https://github.com/haozhou/apcupsd-exporter"

# Copy the compressed binary
COPY --from=builder /out/apcupsd_exporter /apcupsd_exporter

ENTRYPOINT ["/apcupsd_exporter"]
EXPOSE 9162/tcp
