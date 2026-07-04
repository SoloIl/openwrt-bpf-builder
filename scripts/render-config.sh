#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <openwrt-dir> <base-config> <kernel-fragment>" >&2
  exit 1
fi

openwrt_dir=$1
base_config=$2
kernel_fragment=$3

config_path="$openwrt_dir/.config"

cat "$base_config" > "$config_path"
printf '\n' >> "$config_path"
cat "$kernel_fragment" >> "$config_path"
printf 'CONFIG_TARGET_ROOTFS_PARTSIZE=%s\n' "${ROOTFS_SIZE_MB:-4096}" >> "$config_path"
