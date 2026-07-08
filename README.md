# OpenWrt BPF Builder

OpenWrt BPF Builder creates reproducible OpenWrt x86/64 EFI images with the
kernel features required by modern eBPF networking software. Its primary use
case is running [DAE](https://github.com/daeuniverse/dae), a transparent proxy
and traffic-splitting engine that uses eBPF inside the Linux kernel.

Mainstream desktop Linux distributions commonly enable BPF and BTF features by
default. OpenWrt keeps many optional kernel features and modules out of standard
images to reduce their size. This project builds a custom **OpenWrt eBPF** image
with BPF, BTF, TC classifiers/actions, ingress qdiscs, and the networking modules
needed by DAE and this router's VPN and policy-routing stack.

The build runs entirely in GitHub Actions, so a powerful local Linux machine is
not required. It follows an official OpenWrt source tag and uses official
OpenWrt package feeds; third-party feeds and signing keys are intentionally not
added.

> [!IMPORTANT]
> This repository prepares the kernel and system packages for an **OpenWrt DAE install**,
> but it does not install or configure the DAE binary itself. Deploy DAE and
> its configuration separately after the image is installed and the kernel
> capabilities have been verified.

## Scope

This is a personal project built for one x86/64 mini PC and its production
networking requirements. It is not intended to publish images for the full
range of devices supported by OpenWrt.

Default build target:

- OpenWrt source ref: `v25.12.5`
- target: `x86/64`
- profile: `generic`
- image: `ext4-combined-efi.img.gz`
- root filesystem partition: `4096` MiB

If you need another architecture, device profile, or package set, fork the
project and adapt the workflow and configuration for that target. Do not flash
the published x86/64 image onto unrelated hardware.

## Included Capabilities

The kernel configuration enables the DAE baseline, including:

- BPF syscall and JIT support;
- BTF debug information for the kernel and modules;
- TC BPF classifiers and actions;
- ingress and egress networking hooks;
- ingress/`clsact` qdisc support;
- cgroups, kprobes, and BPF events;
- XDP sockets.

The production package baseline also embeds:

- `kmod-sched-bpf`, `tc-full`, and `ip-full`;
- TUN and WireGuard support;
- nftables socket, TPROXY, NFQUEUE, and XFRM modules;
- strongSwan/IKEv2 and the required crypto modules;
- LuCI, DNS-over-HTTPS, collectd statistics, and recovery tools.

See [`config/router-packages.list`](config/router-packages.list) for the exact
package list and [`config/kernel-post-defconfig.fragment`](config/kernel-post-defconfig.fragment)
for the explicit kernel requirements.

## Quick Start

### 1. Fork or clone the repository

Use the **Fork** button on GitHub, or clone the project and push it to your own
repository:

```sh
git clone https://github.com/SoloIl/openwrt-bpf-builder.git
cd openwrt-bpf-builder
```

GitHub Actions must be enabled in the destination repository. The workflow
needs `contents: write` permission because successful builds publish release
assets.

### 2. Adjust the build if necessary

The main customization points are:

- `.github/workflows/build-openwrt.yml` — workflow defaults and artifact
  publishing;
- `config/router-packages.list` — packages embedded in the image;
- `config/buildinfo.sh` — image and high-level kernel settings;
- `config/kernel-post-defconfig.fragment` — kernel options enforced after
  `make defconfig`.

Package names prefixed with `-` in `router-packages.list` are excluded from the
image. For example, the baseline replaces `dnsmasq` with `dnsmasq-full`.

### 3. Run the workflow

Open **Actions → Build OpenWrt x86_64 BPF → Run workflow** and set:

- `openwrt_ref`: an official OpenWrt source tag such as `v25.12.5`;
- `rootfs_size_mb`: root partition size in MiB, normally `4096`;
- `packages`: optional additional space-separated packages.

Leave `packages` empty to use only the version-controlled production baseline.
The workflow fails early if a required package is unavailable or is not
embedded in the image.

### 4. Download and verify the output

Use the ext4 EFI image for this target:

```text
openwrt-bpf-builder-<version>-x86-64-generic-ext4-combined-efi.img.gz
```

Verify it against the `sha256sums` file from the same build:

```sh
sha256sum --ignore-missing -c sha256sums
```

On macOS:

```sh
shasum -a 256 openwrt-bpf-builder-*-ext4-combined-efi.img.gz
```

Compare the result with the matching entry in `sha256sums` before copying or
flashing the image.

## Upgrade an Existing x86/64 Router

> [!WARNING]
> A combined image can rewrite the partition table and the entire system disk.
> Keep physical recovery access, a verified rollback image, and complete
> off-router backups. Never rely on a settings-only backup for custom binaries,
> VPN identities, or files outside `/etc`.

Copy the image to the router:

```sh
scp -O openwrt-bpf-builder-25.12.5-x86-64-generic-ext4-combined-efi.img.gz \
  root@192.168.1.1:/tmp/
```

Verify the copied file and run the non-destructive compatibility test:

```sh
ssh root@192.168.1.1
cd /tmp
sha256sum openwrt-bpf-builder-25.12.5-x86-64-generic-ext4-combined-efi.img.gz
sysupgrade -T openwrt-bpf-builder-25.12.5-x86-64-generic-ext4-combined-efi.img.gz
```

Do not continue if the checksum or `sysupgrade -T` fails. When the backup and
recovery plan are ready, upgrade while preserving the files selected by
OpenWrt:

```sh
sysupgrade -v /tmp/openwrt-bpf-builder-25.12.5-x86-64-generic-ext4-combined-efi.img.gz
```

Use `sysupgrade -n` only when a clean installation is intentional. After first
boot, verify LAN/WAN mapping and kernel/module support before starting DAE,
transparent proxies, VPN tunnels, or custom policy routing.

## Verify the Kernel for DAE

The workflow validates the generated kernel configuration automatically. On a
running router, inspect the effective configuration and module state:

```sh
zcat /proc/config.gz | grep -E \
  'CONFIG_(BPF|BPF_SYSCALL|BPF_JIT|DEBUG_INFO_BTF|NET_CLS_BPF|NET_ACT_BPF|NET_SCH_INGRESS)='

lsmod | grep -E 'cls_bpf|sch_ingress'
mount | grep /sys/fs/bpf
```

A typical DAE deployment should also show JIT-compiled TC filters after DAE is
started:

```sh
tc filter show dev br-lan ingress
```

Do not copy kernel modules from another OpenWrt build. Every kmod must match the
exact kernel ABI of the installed image.

## Matching Kernel Package Bundle

The official OpenWrt repository cannot provide kmods for a kernel whose config
changes its ABI. To keep future module installation possible, this workflow
builds all standard OpenWrt kmods and publishes the matching package directory
for the same kernel.

Build outputs include:

- `target-packages.tar.zst`;
- `target-packages.tar.zst.sha256`;
- the signed `packages.adb` index inside the archive;
- a GitHub Actions artifact containing the unpacked target package directory.

The image and package index are produced by the same build, so the image already
trusts the signing key used for its companion package bundle. Keep the image,
bundle, checksums, kernel config, and build reports together.

## Build Outputs

Successful runs upload and publish:

- ext4 and squashfs EFI images;
- `sha256sums`;
- `.config` and `openwrt.final.config`;
- `kernel.config`;
- `config.buildinfo` and `feeds.buildinfo`;
- `requested-packages.txt`;
- the matching target package bundle and checksum.

The kernel validation step stops the workflow if a required DAE BPF/BTF option
is missing.

## Root Partition Size

The default image uses a 4096 MiB root partition. This keeps the image practical
to build and flash. On a larger SSD, expand the partition and ext4 filesystem
after installation by following the official OpenWrt x86 documentation:

- [OpenWrt on x86 hardware](https://openwrt.org/docs/guide-user/installation/openwrt_x86)
- [Expanding the root partition and filesystem](https://openwrt.org/docs/guide-user/advanced/expand_root)

Back up the router and record the partition start sector and PARTUUID before
changing disk geometry.

## Repository Layout

```text
.
├── .github/workflows/build-openwrt.yml
├── config/buildinfo.sh
├── config/kernel-post-defconfig.fragment
├── config/router-packages.list
├── scripts/validate-kernel-config.sh
└── README.md
```

## License and Support

This repository contains build automation and configuration for a personal
OpenWrt deployment. OpenWrt, DAE, and included packages retain their respective
licenses. Review the generated package manifest and upstream licenses before
redistributing images.

Issues and pull requests are welcome when they relate to the existing x86/64
workflow, but support for additional router models and architectures is outside
the current project scope.
