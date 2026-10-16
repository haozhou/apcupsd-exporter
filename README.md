# apcupsd-exporter
A Dockerfile for [apcupsd_exporter](https://github.com/mdlayher/apcupsd_exporter).
Images are built for `linux/amd64` and `linux/arm64` by GitHub Actions and
pushed to Docker Hub on every push to the default branch.

## An example of docker-compose.yml
```
apcupsd-exporter:
    container_name: apcupsd-exporter
    image: hhhzzzhou/apcupsd-exporter:latest
    restart: unless-stopped
    command: "-apcupsd.addr YOUR_APCUPSD_DAEMON_IP:3551"
    ports:
      - 9162:9162
```
