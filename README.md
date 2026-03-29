# Docker OpenWrt Demo Build

This project is designed for OpenWrt developers to easily debug their own OpenWrt builds and conveniently demonstrate their OpenWrt systems externally.

### How It Works

Start a QEMU virtual machine and interact with OpenWrt via the serial port, mapping LuCI and SSH ports for easy demonstration and debugging. A basic network environment is set up internally to facilitate functional testing.

### How to Use

Build a LiveCD for your OpenWrt, place `openwrt-x86-64-generic-image-efi.iso` in the root directory of this project, and then perform the Docker build operation.
