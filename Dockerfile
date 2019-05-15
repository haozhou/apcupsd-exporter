FROM golang:latest as builder
WORKDIR /tmp/
RUN git clone https://github.com/mdlayher/apcupsd_exporter.git
WORKDIR /tmp/apcupsd_exporter/cmd/apcupsd_exporter
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -a -installsuffix cgo .
RUN apt-get update && apt-get install -y upx-ucl
RUN upx -9 apcupsd_exporter

FROM gcr.io/distroless/static
LABEL maintainer="Henry Zhou <henryzhou2008@gmail.com>"
COPY --from=builder /tmp/apcupsd_exporter/cmd/apcupsd_exporter/apcupsd_exporter /

ENTRYPOINT ["/apcupsd_exporter"]
EXPOSE 9162/tcp
