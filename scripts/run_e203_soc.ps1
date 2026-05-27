$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$build = Join-Path $root "build\sim"

New-Item -ItemType Directory -Force -Path $build | Out-Null
Set-Location $root

iverilog -g2005-sv -o (Join-Path $build "e203_soc_tb.vvp") -f "sim/filelists/e203_soc.f"
vvp (Join-Path $build "e203_soc_tb.vvp")
