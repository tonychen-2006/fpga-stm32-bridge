# Phase 1 hardware bring-up

## Scope and verification state

This phase tests only a blocking, two-byte SPI mode-0 transaction. RTL and a
self-checking testbench are present. No physical hardware result is claimed.

The STEPFPGA mappings below were checked against the STEP-MXO2-LPC schematic
for the LCMXO2-4000HC-132MG board. STM32 alternate functions were checked
against ST's STM32F411 datasheet. The optional PC13 LED polarity was checked
against the WeAct Studio MiniF4 V3.1 schematic; verify clones separately.

## Wiring

| STM32F411CE Black Pill | Direction | STEPFPGA J1 | Signal | FPGA package pin |
|---|---:|---:|---|---:|
| PB12 GPIO | → | 25 | SPICS | P3 |
| PB13 SPI2_SCK AF5 | → | 24 | SPISCK | M4 |
| PB14 SPI2_MISO AF5 | ← | 23 | SPISO | N4 |
| PB15 SPI2_MOSI AF5 | → | 22 | SPISI | P13 |
| GND | — | 20 or 21 | GND | — |

Both boards may be powered independently from USB. Connect the common ground
and the four SPI signals only. **Do not connect either board's 5 V or 3.3 V
rail to the other board.** All signals are 3.3 V logic.

## FPGA simulation

Icarus Verilog was not installed in the development environment. Install it,
then run this exact command from the repository root:

```sh
iverilog -g2005 -Wall -s tb_spi_link_test \
  -o /tmp/tb_spi_link_test.vvp \
  rtl/spi_link_test.v sim/tb_spi_link_test.v && \
vvp /tmp/tb_spi_link_test.vvp
```

Expected final line:

```text
PASS: all SPI link tests completed
```

The testbench checks valid and invalid commands, CS reset after an interrupted
command, back-to-back transactions, and MSB-first bit ordering.

## FPGA build and programming

1. Create a Lattice Diamond project for `LCMXO2-4000HC`, speed grade `-4`,
   package `MG132`.
2. Add `rtl/spi_link_test.v` and `constraints/stepfpga.lpf`.
3. Set `spi_link_test` as the top-level module.
4. Run synthesis, map, place-and-route, and JEDEC generation. Review all pin,
   timing, multiple-driver, and latch warnings; do not ignore errors.
5. Copy the generated `.jed` file to the STEPLink mass-storage device and wait
   for programming to finish before wiring or testing.

Diamond is not installed in the current environment, so synthesis and LPF
acceptance have not been run locally.

## STM32 build and test

1. Generate an STM32CubeIDE project for the exact `STM32F411CEUx` device.
2. Apply the SPI2/GPIO settings in `firmware/README.md`.
3. Add the Phase 1 source and header to the project and make the two calls shown
   there after HAL peripheral initialization.
4. Confirm PB12 is high while idle before connecting the FPGA.
5. Start with SPI2 prescaler 256. Record the generated SPI2 peripheral clock
   and confirm measured SCK is that clock divided by 256.
6. Connect ground first, then PB12–PB15, with both boards unpowered. Power the
   boards independently by USB.
7. Run under the debugger and inspect `g_fpga_spi_link_stats`.

Expected values after a successful call:

| Field | Expected |
|---|---:|
| `last_tx` | `{0x9f, 0x00}` |
| `last_rx` | `{0x00, 0xa5}` |
| `last_hal_status` | `HAL_OK` |
| `pass_count` | increments by 1 |
| `failure_count` | unchanged |
| `hal_error_count` | unchanged |

On a verified WeAct V3.1 board, PC13 illuminates on success. It is active-low.

## Expected oscilloscope or logic-analyzer signals

- SPICS/PB12 idles high and remains low for exactly 16 SCK cycles.
- SPISCK/PB13 idles low. Data is sampled on rising edges and changes on falling
  edges.
- SPISI/PB15 sends `1001_1111 0000_0000` (hex `9f 00`), MSB first.
- SPISO/PB14 is `0000_0000 1010_0101` (hex `00 a5`) while CS is low.
- At prescaler 256, measured SCK equals the verified SPI2 peripheral clock
  divided by 256. No absolute frequency is claimed until the generated clock
  configuration is available.

If the first byte is not zero but the second byte is `a5`, the electrical link
is functional and the first-byte discrepancy likely reflects sampling or
idle-line behavior; this implementation drives zero throughout the first byte,
so investigate wiring and capture timing before relaxing the test.

## Stop/go criterion

Do not begin the register bridge, capture engine, DMA, USB, or host phases until
multiple hardware transactions increment `pass_count` with no failures and the
waveforms above have been confirmed.

## Source documents

- STEPFPGA board schematic: <https://wiki.stepfpga.com/_media/step-mxo2-lpc.pdf>
- STEPFPGA technical documentation: <https://d3s5r33r268y59.cloudfront.net/datasheets/28515/2022-11-13-03-28-37/STEFPGATechnicalDocumentation_Rev1.0.pdf>
- STM32F411 datasheet: <https://www.st.com/resource/en/datasheet/stm32f411re.pdf>
- WeAct MiniF4 V3.1 schematic: <https://github.com/WeActStudio/WeActStudio.MiniSTM32F4x1/blob/master/Hardware/MiniF4x1Cx_V31%20SchDoc.pdf>
