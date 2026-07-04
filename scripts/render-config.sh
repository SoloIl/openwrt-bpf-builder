#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: $0 <openwrt-dir> <seed-config> <kernel-fragment> <packages>" >&2
  exit 1
fi

openwrt_dir=$1
seed_config=$2
kernel_fragment=$3
packages=$4

config_path="$openwrt_dir/.config"

cat "$seed_config" > "$config_path"
cat "$kernel_fragment" >> "$config_path"
printf 'CONFIG_TARGET_ROOTFS_PARTSIZE=%s\n' "${ROOTFS_SIZE_MB:-4096}" >> "$config_path"

for pkg in $packages; do
  if [ -z "$pkg" ]; then
    continue
  fi

  negate=
  if [[ "$pkg" == -* ]]; then
    negate=1
    pkg=${pkg#-}
  fi

  symbol=${pkg//-/_}
  if [ -n "$negate" ]; then
    printf '# CONFIG_PACKAGE_%s is not set\n' "$symbol" >> "$config_path"
  else
    printf 'CONFIG_PACKAGE_%s=y\n' "$symbol" >> "$config_path"
  fi
done

sort -u "$config_path" -o "$config_path"
