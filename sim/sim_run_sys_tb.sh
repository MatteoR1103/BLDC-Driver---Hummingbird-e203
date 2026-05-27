#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/sim"

mkdir -p "$BUILD_DIR"
cd "$ROOT_DIR"

iverilog -g2005-sv -o "$BUILD_DIR/e203_soc_tb.vvp" -f sim/filelists/e203_soc.f
vvp "$BUILD_DIR/e203_soc_tb.vvp"
