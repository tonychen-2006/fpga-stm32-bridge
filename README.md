# FPGA–STM32 capture bridge

This repository is being developed as a phased digital signal-capture system
using a STEPFPGA MachXO2-4000HC board and an STM32F411CE Black Pill.

## Current status

Phase 1 (SPI electrical bring-up) is implemented. The FPGA recognizes command
`0x9f` and returns `0xa5` in the following byte over SPI mode 0. The STM32 test
uses blocking HAL SPI calls and exposes debugger-visible counters.

Later register, capture, DMA, USB, and host-software phases are intentionally
not started until the blocking SPI link is verified on physical hardware.

See [docs/hardware_bringup.md](docs/hardware_bringup.md) for wiring, build,
simulation, programming, and oscilloscope checks.
