#!/bin/sh

config="$1"

# set_config <CONFIG_NAME> <value|y|n|null>
set_config() {
	local prefix suffix
	if [ "$2" = "null" ]; then
		prefix='# '
		suffix=' is not set'
	else
		prefix=''
		suffix="=$2"
	fi
	sed -Ei "/^(# )?($1)[ =].*/{s|^(# )?($1).*|$prefix\\2$suffix|};
	1i\\$prefix$1$suffix" "$config"
}

set_config CONFIG_VERSION_DIST '"OpenWrt-BPF-Builder"'
set_config CONFIG_BUILD_LOG y
set_config CONFIG_MAKE_TOOLCHAIN null
set_config CONFIG_BPF_TOOLCHAIN_BUILD_LLVM null
set_config CONFIG_SDK_LLVM_BPF null
set_config CONFIG_USE_LLVM_BUILD null
set_config CONFIG_BPF_TOOLCHAIN_PREBUILT y

# DAE baseline from rebuild
set_config CONFIG_KERNEL_DEBUG_KERNEL y
set_config CONFIG_KERNEL_DEBUG_INFO y
set_config CONFIG_KERNEL_DEBUG_INFO_REDUCED n
set_config CONFIG_KERNEL_DEBUG_INFO_BTF y
set_config CONFIG_KERNEL_DEBUG_INFO_BTF_MODULES y
set_config CONFIG_KERNEL_MODULE_ALLOW_BTF_MISMATCH y
set_config CONFIG_BPF y
set_config CONFIG_BPF_SYSCALL y
set_config CONFIG_BPF_JIT y
set_config CONFIG_DWARVES y
set_config CONFIG_KERNEL_BPF_EVENTS y
set_config CONFIG_KERNEL_BPF_STREAM_PARSER y
set_config CONFIG_KERNEL_CGROUPS y
set_config CONFIG_KERNEL_KALLSYMS y
set_config CONFIG_KERNEL_KPROBES y
set_config CONFIG_KERNEL_KPROBE_EVENTS y
set_config CONFIG_KERNEL_XDP_SOCKETS y
set_config CONFIG_NET_INGRESS y
set_config CONFIG_NET_EGRESS y
set_config CONFIG_NET_CLS_ACT y
set_config CONFIG_NET_CLS_BPF m
set_config CONFIG_NET_ACT_BPF m
set_config CONFIG_NET_SCH_INGRESS m
set_config CONFIG_TARGET_ROOTFS_PARTSIZE "${ROOTFS_SIZE_MB:-4096}"
