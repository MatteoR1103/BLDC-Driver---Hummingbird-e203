# BLDC RTL

`BLDC_driver` is the stable SoC-facing wrapper. It keeps the same ICB and GPIO ports used by `e203_subsys_perips.v`, while the implementation is split into smaller blocks for registers, timing, commutation, and sine PWM.

The LUT is generated with:

```sh
python hardware/rtl/bldc/sine_LUT_generator.py --rows 16 --width 8
```

The SoC wrapper defaults to the Gowin pROM IP because that is the FPGA target path. The standalone unit test overrides `USE_GOWIN_PROM=0` so Icarus Verilog can use the portable `bldc_rom_sync` ROM instead.
