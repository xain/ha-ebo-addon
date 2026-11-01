# EBO SE bridge add-on (x86_64 HAOS host): Python/ffmpeg/MediaMTX run natively,
# only the small ARM64 Android bridge process is translated by qemu-aarch64.
ARG BUILD_FROM=python:3.11-slim-bookworm
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ffmpeg jq curl ca-certificates qemu-user-static tini \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir fastapi "uvicorn[standard]" paho-mqtt

WORKDIR /opt/ebo

# MediaMTX: RTSP/WebRTC/HLS server (native arch)
ARG MEDIAMTX_VERSION=1.19.0
RUN set -e; \
    case "$(dpkg --print-architecture)" in \
      arm64) MT=arm64 ;; amd64) MT=amd64 ;; armhf) MT=armv7 ;; \
      *) echo "unsupported arch $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/bluenviron/mediamtx/releases/download/v${MEDIAMTX_VERSION}/mediamtx_v${MEDIAMTX_VERSION}_linux_${MT}.tar.gz" \
      | tar xz mediamtx

COPY ebo_app/ /opt/ebo/
COPY run.sh /run.sh
RUN chmod +x /run.sh /opt/ebo/run.sh /opt/ebo/mediamtx

CMD ["/run.sh"]
