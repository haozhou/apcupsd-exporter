# Build arguments for easy version updates
ARG APCUPSD_VERSION=v0.3.0
ARG UPX_VERSION=5.0.2
ARG GO_VERSION=1.25

# Builder stage
FROM golang:${GO_VERSION}-alpine as builder

# Install build dependencies
RUN apk add --no-cache git xz

WORKDIR /tmp/

# Clone specific version with minimal history
RUN git clone --branch ${APCUPSD_VERSION} --depth 1 https://github.com/mdlayher/apcupsd_exporter.git

WORKDIR /tmp/apcupsd_exporter/cmd/apcupsd_exporter

# Download dependencies and build
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -trimpath -o main .

# Download and setup UPX
ADD https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz /tmp/upx.tar.xz
RUN xz -d -c /tmp/upx.tar.xz | tar -xOf - upx-${UPX_VERSION}-amd64_linux/upx > /bin/upx && \
    chmod a+x /bin/upx && \
    rm /tmp/upx.tar.xz

# Compress binary
RUN upx --best --lzma main

# Runtime stage - use distroless for minimal attack surface
FROM gcr.io/distroless/static-debian12:nonroot

# Metadata
LABEL maintainer="Henry Zhou <henryzhou2008@gmail.com>" \
      org.opencontainers.image.title="apcupsd-exporter" \
      org.opencontainers.image.description="Prometheus exporter for apcupsd UPS statistics" \
      org.opencontainers.image.source="https://github.com/mdlayher/apcupsd_exporter"

# Copy the compressed binary
COPY --from=builder /tmp/apcupsd_exporter/cmd/apcupsd_exporter/main /apcupsd_exporter

ENTRYPOINT ["/apcupsd_exporter"]
EXPOSE 9162/tcp
