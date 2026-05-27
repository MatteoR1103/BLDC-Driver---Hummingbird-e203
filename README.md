# FPGA BLDC Motor Controller for Hummingbird E203

This repository contains a custom brushless DC motor-controller peripheral integrated into a Hummingbird E203 RISC-V SoC. The project targets a Gowin GW2A-18 FPGA and drives an external three-phase H-bridge through six GPIO outputs.

The design was built as an Intelligent Chip final project by Mattia Prandi and Matteo Rubini. The full original report is in [docs/final-report.pdf](docs/final-report.pdf).

## What It Does

- Exposes a BLDC driver as an E203 ICB memory-mapped peripheral at `0x1001_4000`.
- Generates six H-bridge control signals: `HS_U`, `LS_U`, `HS_V`, `LS_V`, `HS_W`, `LS_W`.
- Supports three motion modes:
  - static six-step commutation
  - six-step PWM with software-controlled duty cycle
  - three-phase sine PWM using a quarter-wave LUT
- Adds configurable dead time between high-side phase transitions.
- Implements active braking: when the `BREAK` input is deasserted, high-side outputs turn off and low-side outputs turn on.
- Provides a C firmware driver and demo for the E203 core.

## Repository Layout

```text
hardware/
  rtl/bldc/        Custom BLDC peripheral RTL, LUT, and unit testbench
  rtl/soc/         Hummingbird E203 SoC RTL with the BLDC peripheral wired in
firmware/
  bldc_demo/       E203 demo firmware and BLDC C driver
fpga/
  gowin/           Gowin project, constraints, and pROM IP wrapper
sim/
  filelists/       Icarus Verilog file lists
  *.sh             Simulation entry points
scripts/
  *.ps1            Windows-friendly simulation launchers
docs/
  final-report.*   Original project report
media/
  videos/          Local demo captures, ignored by Git
```

## Register Map

Base address: `BLDC_DRIVER_CTRL_ADDR = 0x1001_4000`.

| Offset | Name | Bits | Access | Description |
| --- | --- | --- | --- | --- |
| `0x000` | `CFG` | `[0]` | RW | Enable |
| `0x000` | `CFG` | `[1]` | RO | Brake status, `1` when brake is active |
| `0x000` | `CFG` | `[3:2]` | RW | Mode: `0` static, `1` PWM, `2` sine PWM |
| `0x000` | `CFG` | `[4]` | RW | Direction: `0` CCW, `1` CW |
| `0x000` | `CFG` | `[7:5]` | RO | Hall/input pins `{C, B, A}` |
| `0x000` | `CFG` | `[15:12]` | RW | Dead-zone ticks |
| `0x000` | `CFG` | `[31:16]` | RW | Motor period in slow-clock ticks |
| `0x004` | `TIMING` | `[15:0]` | RW | `time_1`, used as PWM compare value |
| `0x004` | `TIMING` | `[31:16]` | RW | `time_2`, phase spacing / compare value |

The slow motor-control clock is derived from the SoC clock with `SLOW_DIVIDER = 400`, giving about `33.75 kHz` from a `27 MHz` input clock.

## BLDC RTL

The peripheral wrapper remains `BLDC_driver` so the existing SoC integration keeps the same public interface. Internally it is split into focused modules:

- `bldc_icb_regs.v`: ICB register bank and read-only status fields.
- `bldc_clock_divider.v`: motor-control tick generator.
- `bldc_output_compare.v`: six-step/static and PWM phase generator.
- `bldc_sine_phase.v`: quarter-wave sine LUT mapper.
- `bldc_rom_sync.v`: portable LUT ROM for simulation.
- `bldc_sine_pwm.v`: sine PWM output generator.

## Firmware

The C driver lives in:

```text
firmware/bldc_demo/src/bsp/hbird-e200/drivers/bldc_driver/
```

The demo firmware:

1. initializes the board,
2. plays a short tick pattern with the motor,
3. waits for the input connected to Hall/Input A,
4. runs static mode,
5. runs PWM in the opposite direction,
6. runs sine PWM.

## Simulation

Install Icarus Verilog, then run from the repository root.

Linux/macOS:

```sh
./sim/run_bldc_unit.sh
./sim/sim_run_sys_tb.sh
```

Windows PowerShell:

```powershell
.\scripts\run_bldc_unit.ps1
.\scripts\run_e203_soc.ps1
```

Generated waveforms and compiled simulation images land under `build/sim/` and are ignored by Git.

## FPGA Build

Open [fpga/gowin/e203_basic_chip.gprj](fpga/gowin/e203_basic_chip.gprj) in Gowin EDA. The project uses relative paths back to the cleaned source tree.

The board constraints are in [fpga/gowin/src/e203_basic_chip.cst](fpga/gowin/src/e203_basic_chip.cst). The BLDC GPIO mapping used by the design is:

| Signal | GPIO | FPGA pin |
| --- | --- | --- |
| `HS_U` | `gpio_out[26]` | `J14` |
| `LS_U` | `gpio_out[27]` | `M15` |
| `HS_V` | `gpio_out[28]` | `J16` |
| `LS_V` | `gpio_out[29]` | `T12` |
| `HS_W` | `gpio_out[30]` | `M14` |
| `LS_W` | `gpio_out[31]` | `R11` |
| `HAL_C` | `gpio_in[20]` | `T3` |
| `HAL_B` | `gpio_in[21]` | `T2` |
| `HAL_A` | `gpio_in[22]` | `D7` |
| `BREAK` | `gpio_in[23]` | `T10` |

After place-and-route, load a generated bitstream with:

```sh
openFPGALoader -b tangprimer20k path/to/bitstream.fs
```

