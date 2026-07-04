#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <config-path>" >&2
  exit 1
fi

config_path=$1

require_line() {
  local expected=$1

  if ! grep -qxF "$expected" "$config_path"; then
    echo "missing required config line: $expected" >&2
    exit 1
  fi
}

require_line 'CONFIG_BPF=y'
require_line 'CONFIG_BPF_SYSCALL=y'
require_line 'CONFIG_BPF_JIT=y'
require_line 'CONFIG_KERNEL_CGROUPS=y'
require_line 'CONFIG_KERNEL_KPROBES=y'
require_line 'CONFIG_NET_INGRESS=y'
require_line 'CONFIG_NET_EGRESS=y'
require_line 'CONFIG_NET_SCH_INGRESS=m'
require_line 'CONFIG_NET_CLS_BPF=m'
require_line 'CONFIG_NET_CLS_ACT=y'
require_line 'CONFIG_KERNEL_BPF_STREAM_PARSER=y'
require_line 'CONFIG_KERNEL_DEBUG_INFO=y'
require_line 'CONFIG_KERNEL_DEBUG_INFO_REDUCED=n'
require_line 'CONFIG_KERNEL_DEBUG_INFO_BTF=y'
require_line 'CONFIG_KERNEL_KPROBE_EVENTS=y'
require_line 'CONFIG_KERNEL_BPF_EVENTS=y'
