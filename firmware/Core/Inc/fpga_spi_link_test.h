#ifndef FPGA_SPI_LINK_TEST_H
#define FPGA_SPI_LINK_TEST_H

#include "stm32f4xx_hal.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    volatile uint32_t pass_count;
    volatile uint32_t failure_count;
    volatile uint32_t hal_error_count;
    volatile uint8_t last_tx[2];
    volatile uint8_t last_rx[2];
    volatile HAL_StatusTypeDef last_hal_status;
} fpga_spi_link_stats_t;

extern volatile fpga_spi_link_stats_t g_fpga_spi_link_stats;

void fpga_spi_link_test_init(GPIO_TypeDef *cs_port, uint16_t cs_pin,
                             GPIO_TypeDef *led_port, uint16_t led_pin);

HAL_StatusTypeDef fpga_spi_link_test_run(SPI_HandleTypeDef *spi,
                                         GPIO_TypeDef *cs_port,
                                         uint16_t cs_pin,
                                         GPIO_TypeDef *led_port,
                                         uint16_t led_pin);

#ifdef __cplusplus
}
#endif

#endif
