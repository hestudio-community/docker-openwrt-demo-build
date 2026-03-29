#!/bin/sh
set -eu

ISO_PATH="/app/openwrt-x86-64-generic-image-efi.iso"

if [ ! -f "$ISO_PATH" ]; then
  echo "ISO not found: $ISO_PATH"
  exit 1
fi

OVMF_CODE=""
OVMF_VARS_TEMPLATE=""

for f in \
  /usr/share/OVMF/OVMF_CODE.fd \
  /usr/share/OVMF/OVMF_CODE_4M.fd \
  /usr/share/edk2/ovmf/OVMF_CODE.fd
do
  if [ -f "$f" ]; then
    OVMF_CODE="$f"
    break
  fi
done

for f in \
  /usr/share/OVMF/OVMF_VARS.fd \
  /usr/share/OVMF/OVMF_VARS_4M.fd \
  /usr/share/edk2/ovmf/OVMF_VARS.fd
do
  if [ -f "$f" ]; then
    OVMF_VARS_TEMPLATE="$f"
    break
  fi
done

if [ -z "$OVMF_CODE" ] || [ -z "$OVMF_VARS_TEMPLATE" ]; then
  echo "OVMF firmware files not found"
  exit 1
fi

cp "$OVMF_VARS_TEMPLATE" /tmp/OVMF_VARS.fd

ip link del veth-host 2>/dev/null || true
ip link del br-lan 2>/dev/null || true
ip tuntap del dev tap0 mode tap 2>/dev/null || true

ip link add br-lan type bridge
ip link set br-lan up

ip tuntap add dev tap0 mode tap
ip link set tap0 master br-lan
ip link set tap0 up

ip link add veth-host type veth peer name veth-br
ip link set veth-br master br-lan
ip link set veth-br up
ip addr add 192.168.1.2/24 dev veth-host
ip link set veth-host up

socat TCP-LISTEN:8080,bind=0.0.0.0,reuseaddr,fork TCP:192.168.1.1:80 &
socat TCP-LISTEN:8443,bind=0.0.0.0,reuseaddr,fork TCP:192.168.1.1:443 &
socat TCP-LISTEN:2222,bind=0.0.0.0,reuseaddr,fork TCP:192.168.1.1:22 &

echo "[INFO] bridge/tap/proxy ready"
ip -brief addr
echo "[INFO] starting qemu..."

exec qemu-system-x86_64 \
  -machine q35 \
  -m 256 \
  -smp 2 \
  -cpu max \
  -nographic \
  -serial mon:stdio \
  -boot d \
  -cdrom "$ISO_PATH" \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd \
  \
  -netdev tap,id=lan0,ifname=tap0,script=no,downscript=no \
  -device e1000,netdev=lan0,mac=52:54:00:12:34:56 \
  \
  -netdev user,id=wan0 \
  -device e1000,netdev=wan0,mac=52:54:00:12:34:57
