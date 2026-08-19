# STM32F411CE Black Pill firmware

The CubeIDE project is rooted in this directory and targets STM32F411CEUx.

Phase 1 uses blocking SPI2 mode 0 at 62.5 kbit/s with the current 16 MHz APB1
clock and `/256` prescaler. PB12 is software-controlled `FPGA_CS`; PB13, PB14,
and PB15 are SPI2 SCK, MISO, and MOSI. The WeAct PC13 LED is active-low.

Build and debug the `stm32` project in STM32CubeIDE. Inspect
`g_fpga_spi_link_stats` in the debugger. A correct link produces `last_rx` of
`{0x00, 0xa5}` and increments `pass_count` every 250 ms.

If Cube code is regenerated, verify that `SPI2.BaudRatePrescaler` remains
`SPI_BAUDRATEPRESCALER_256` in `stm32.ioc`. The test calls in `main.c` are
inside Cube `USER CODE` sections and should be retained.
