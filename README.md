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
- production router package baseline from `config/router-packages.list`

The workflow also appends a small kernel config fragment for BPF/BTF-related
options. The package baseline includes the matching WireGuard, TUN, TC/BPF,
nftables TPROXY/NFQUEUE, XFRM/IPsec, and crypto kernel modules needed by the
router. Additional packages supplied through the workflow input are added to
this baseline.

## Repository Layout

- `.github/workflows/build-openwrt.yml`: GitHub Actions workflow
- `config/x86-64-generic.seed`: base OpenWrt config seed
- `config/kernel-post-defconfig.fragment`: kernel options we care about
- `config/router-packages.list`: required production and recovery packages
- `config/buildinfo.sh`: applies the BPF/BTF and image settings

## How To Use

1. Create a new GitHub repo from this directory.
2. Push it to your GitHub account.
3. Open `Actions` and run `Build OpenWrt x86_64 BPF`.
4. For the first run, keep the defaults.

Suggested run inputs:

- `openwrt_ref`: `v25.12.5`
- `rootfs_size_mb`: `4096`
- `packages`: leave empty unless an additional package is required

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
- `requested-packages.txt`
- `apk-build-key.pub` (public package-signing key; never the private key)
- the matching target package directory containing kernel-module APKs and index
- `target-packages.tar.zst` and its SHA-256 file as durable release assets

The build fails if any package in `config/router-packages.list` or the
additional `packages` input is unavailable or dropped by `make defconfig`.

The image and target package index are produced by the same build. The image
trusts that build's package-signing key; the exported public key is retained for
offline recovery and verification. Third-party feed keys, including Fantastic
Packages keys, are intentionally not added.

`CONFIG_ALL_KMODS=y` keeps ordinary OpenWrt kernel modules available as matching
APKs even when they are not embedded in the image. The release package bundle
therefore acts as the companion kmod repository for that exact custom kernel
ABI. A new image is required only when a future feature needs a kernel option
that is not available as a module in the saved package bundle.

## Notes

- This repo intentionally does not use `fantastic-packages` feeds or companion repos.
- Builds from source are slower than ImageBuilder, but they let us change kernel options.
- The config is intentionally small so future OpenWrt bumps are easier to maintain.
