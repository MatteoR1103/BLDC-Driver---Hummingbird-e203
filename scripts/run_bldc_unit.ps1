$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$build = Join-Path $root "build\sim"

New-Item -ItemType Directory -Force -Path $build | Out-Null
Set-Location $root

iverilog -g2005-sv -o (Join-Path $build "bldc_unit_tb.vvp") -f "sim/filelists/bldc_unit.f"
vvp (Join-Path $build "bldc_unit_tb.vvp")
