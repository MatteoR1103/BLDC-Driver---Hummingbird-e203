#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/sim"

mkdir -p "$BUILD_DIR"
cd "$ROOT_DIR"

iverilog -g2005-sv -o "$BUILD_DIR/bldc_unit_tb.vvp" -f sim/filelists/bldc_unit.f
vvp "$BUILD_DIR/bldc_unit_tb.vvp"
