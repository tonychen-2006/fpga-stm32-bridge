#include "fpga_spi_link_test.h"

#define FPGA_SPI_TIMEOUT_MS 100U

volatile fpga_spi_link_stats_t g_fpga_spi_link_stats;

static void set_optional_active_low_led(GPIO_TypeDef *led_port,
                                        uint16_t led_pin,
                                        GPIO_PinState illuminated)
{
    if (led_port != NULL) {
        HAL_GPIO_WritePin(led_port, led_pin,
                          (illuminated == GPIO_PIN_SET) ? GPIO_PIN_RESET
                                                       : GPIO_PIN_SET);
    }
}

void fpga_spi_link_test_init(GPIO_TypeDef *cs_port, uint16_t cs_pin,
                             GPIO_TypeDef *led_port, uint16_t led_pin)
{
    /* Force a low-to-high edge so the FPGA starts from a reset transaction. */
    HAL_GPIO_WritePin(cs_port, cs_pin, GPIO_PIN_RESET);
    HAL_GPIO_WritePin(cs_port, cs_pin, GPIO_PIN_SET);
    set_optional_active_low_led(led_port, led_pin, GPIO_PIN_RESET);
}

HAL_StatusTypeDef fpga_spi_link_test_run(SPI_HandleTypeDef *spi,
                                         GPIO_TypeDef *cs_port,
                                         uint16_t cs_pin,
                                         GPIO_TypeDef *led_port,
                                         uint16_t led_pin)
{
    uint8_t tx[2] = {0x9fU, 0x00U};
    uint8_t rx[2] = {0x00U, 0x00U};
    HAL_StatusTypeDef status;

    g_fpga_spi_link_stats.last_tx[0] = tx[0];
    g_fpga_spi_link_stats.last_tx[1] = tx[1];

    HAL_GPIO_WritePin(cs_port, cs_pin, GPIO_PIN_RESET);
    status = HAL_SPI_TransmitReceive(spi, tx, rx, 2U, FPGA_SPI_TIMEOUT_MS);
    HAL_GPIO_WritePin(cs_port, cs_pin, GPIO_PIN_SET);

    g_fpga_spi_link_stats.last_hal_status = status;
    g_fpga_spi_link_stats.last_rx[0] = rx[0];
    g_fpga_spi_link_stats.last_rx[1] = rx[1];

    if (status != HAL_OK) {
        g_fpga_spi_link_stats.hal_error_count++;
        g_fpga_spi_link_stats.failure_count++;
        set_optional_active_low_led(led_port, led_pin, GPIO_PIN_RESET);
    } else if ((rx[0] == 0x00U) && (rx[1] == 0xa5U)) {
        g_fpga_spi_link_stats.pass_count++;
        set_optional_active_low_led(led_port, led_pin, GPIO_PIN_SET);
    } else {
        g_fpga_spi_link_stats.failure_count++;
        set_optional_active_low_led(led_port, led_pin, GPIO_PIN_RESET);
    }

    return status;
}
