#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <kernel.config>" >&2
  exit 1
fi

config=$1

require_line() {
  local needle=$1
  if ! grep -qxF "$needle" "$config"; then
    echo "missing required kernel config line: $needle" >&2
    exit 1
  fi
}

require_line "CONFIG_BPF=y"
require_line "CONFIG_BPF_SYSCALL=y"
require_line "CONFIG_BPF_JIT=y"
require_line "CONFIG_CGROUPS=y"
require_line "CONFIG_KPROBES=y"
require_line "CONFIG_NET_INGRESS=y"
require_line "CONFIG_NET_EGRESS=y"
require_line "CONFIG_NET_SCH_INGRESS=m"
require_line "CONFIG_NET_CLS_BPF=m"
require_line "CONFIG_NET_CLS_ACT=y"
require_line "CONFIG_BPF_STREAM_PARSER=y"
require_line "CONFIG_DEBUG_INFO=y"
require_line "# CONFIG_DEBUG_INFO_REDUCED is not set"
require_line "CONFIG_DEBUG_INFO_BTF=y"
require_line "CONFIG_KPROBE_EVENTS=y"
require_line "CONFIG_BPF_EVENTS=y"

echo "kernel.config satisfies dae requirements"
