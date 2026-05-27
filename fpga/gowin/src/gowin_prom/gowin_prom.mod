-series GW2A
-device GW2A-18
-device_version C
-package PBGA256
-part_number GW2A-LV18PG256C8/I7


-mod_name Gowin_pROM
-file_name gowin_prom
-path fpga/gowin/src/gowin_prom/
-type RAM_ROM
-file_type vlg
-pROM true
-depth 16
-width 8
-read_mode bypass
-reset_mode sync
-init_file ../../hardware/rtl/bldc/sine_LUT.mi
