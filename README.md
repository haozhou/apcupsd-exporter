# apcupsd-exporter
A Dockerfile for apcupsd_exporter

## An example of docker-composer.yml
```
apcupsd-exporter:
    container_name: apcupsd-exporter
    image: hhhzzzhou/apcupsd-exporter:latest
    restart: unless-stopped
    command: "-apcupsd.addr YOUR_APCUPSD_DAEMON_IP:3551"
    ports:
      - 9162:9162
```
