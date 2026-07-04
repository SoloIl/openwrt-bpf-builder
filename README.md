# OpenWrt BPF Builder

Minimal GitHub Actions build repo for stock OpenWrt x86/64 images with BPF and BTF support enabled.

This repo is meant for your exact use case:

- build on GitHub Actions, not on an old local Mac
- stay close to stock OpenWrt
- avoid custom third-party feeds and preinstalled package bundles
- produce a normal x86/64 EFI ext4 image

## What It Builds

Default workflow settings build:

- OpenWrt source ref: `v25.12.5`
- target: `x86/64`
- profile: `generic`
- image type: `combined-efi.img.gz`
- rootfs partition size: `4096` MB

The workflow also appends a small kernel config fragment for BPF/BTF-related options.

## Repository Layout

- `.github/workflows/build-openwrt.yml`: GitHub Actions workflow
- `config/x86-64-generic.seed`: base OpenWrt config seed
- `config/kernel-bpf-btf.fragment`: kernel options we care about
- `scripts/render-config.sh`: turns workflow inputs into a final `.config`

## How To Use

1. Create a new GitHub repo from this directory.
2. Push it to your GitHub account.
3. Open `Actions` and run `Build OpenWrt x86_64 BPF`.
4. For the first run, keep the defaults.

Suggested first-run inputs:

- `openwrt_ref`: `v25.12.5`
- `rootfs_size_mb`: `4096`
- `packages`: `luci luci-ssl kmod-ikconfig`

If you specifically want to try `einat-ebpf`, add it to `packages` later:

```text
luci luci-ssl kmod-ikconfig einat-ebpf
```

If a package is unavailable for the selected OpenWrt ref, remove it from the input rather than changing the workflow.

## Expected Artifacts

After a successful run, check the uploaded artifacts for files under:

```text
bin/targets/x86/64/
```

The main image to look for is typically:

```text
openwrt-...-x86-64-generic-ext4-combined-efi.img.gz
```

The workflow also uploads:

- `.config`
- `config.buildinfo`
- `feeds.buildinfo`
- `sha256sums`

## Notes

- This repo intentionally does not use `fantastic-packages` feeds or companion repos.
- Builds from source are slower than ImageBuilder, but they let us change kernel options.
- The config is intentionally small so future OpenWrt bumps are easier to maintain.
