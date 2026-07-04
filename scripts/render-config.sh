#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <openwrt-dir> <seed-config> <kernel-fragment>" >&2
  exit 1
fi

openwrt_dir=$1
seed_config=$2
kernel_fragment=$3

config_path="$openwrt_dir/.config"

cat "$seed_config" > "$config_path"
cat "$kernel_fragment" >> "$config_path"
printf 'CONFIG_TARGET_ROOTFS_PARTSIZE=%s\n' "${ROOTFS_SIZE_MB:-4096}" >> "$config_path"

sort -u "$config_path" -o "$config_path"
