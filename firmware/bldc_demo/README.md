# BLDC Demo Firmware

The demo runs on the Hummingbird E203 firmware environment and controls the BLDC peripheral through `BLDC_DRIVER_CTRL_ADDR = 0x1001_4000`.

Key files:

- `src/main.c`: startup demo sequence.
- `src/bsp/hbird-e200/drivers/bldc_driver/bldc_driver.c`: register-level and high-level motor API.
- `src/bsp/hbird-e200/include/headers/devices/bldc_driver.h`: device register offsets.
- `src/bsp/hbird-e200/env/platform.h`: memory map entry for the BLDC peripheral.

The old IDE `Debug/` output is intentionally ignored. Recreate firmware build products with your local E203/RISC-V toolchain.

