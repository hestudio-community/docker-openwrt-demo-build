FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      qemu-system-x86 \
      ovmf \
      iproute2 \
      socat \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY ./assets/start.sh /app/start.sh
COPY openwrt-x86-64-generic-image-efi.iso /app/openwrt-x86-64-generic-image-efi.iso
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
