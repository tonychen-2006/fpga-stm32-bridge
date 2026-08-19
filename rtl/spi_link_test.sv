// SPI Mode-0 link test
//
// STM32 = SPI master
// FPGA  = SPI slave
//
// Test transaction, MSB first:
//
// STM32 TX:  9F 00
// FPGA TX:   00 A5
//
// SPI Mode 0:
// CPOL = 0
// CPHA = 0
//
// MOSI sampled on rising SCK edge.
// MISO changes on falling SCK edge.

module spi_link_test (
    input  logic SPICS,     // Active-low chip select from STM32
    input  logic SPISCK,    // SPI clock from STM32
    input  logic SPISI,     // MOSI: STM32 -> FPGA
    output wire  SPISO      // MISO: FPGA -> STM32
);

    logic [7:0] rx_shift;
    logic [7:0] command_byte;
    logic [7:0] tx_shift;

    logic [2:0] bit_count;

    logic command_strobe;
    logic command_received;
    logic response_loaded;

    logic spiso_bit;


    // ------------------------------------------------------------
    // MISO output
    //
    // High impedance whenever chip-select is inactive.
    // ------------------------------------------------------------

    assign SPISO = SPICS ? 1'bz : spiso_bit;


    // ------------------------------------------------------------
    // SPI RECEIVE
    //
    // Mode 0 samples MOSI on rising SCK edges.
    // ------------------------------------------------------------

    always_ff @(posedge SPISCK or posedge SPICS) begin

        if (SPICS) begin

            rx_shift         <= 8'h00;
            command_byte     <= 8'h00;

            bit_count        <= 3'd0;

            command_strobe   <= 1'b0;
            command_received <= 1'b0;

        end else begin

            command_strobe <= 1'b0;

            // Shift MOSI into receive register
            rx_shift <= {
                rx_shift[6:0],
                SPISI
            };


            // Completed one byte
            if (bit_count == 3'd7) begin

                bit_count <= 3'd0;


                // First byte of transaction is interpreted
                // as the command byte.
                if (!command_received) begin

                    command_byte <= {
                        rx_shift[6:0],
                        SPISI
                    };

                    command_received <= 1'b1;
                    command_strobe   <= 1'b1;

                end

            end else begin

                bit_count <= bit_count + 3'd1;

            end
        end
    end


    // ------------------------------------------------------------
    // SPI TRANSMIT
    //
    // Mode 0 updates MISO on falling SCK edges.
    // ------------------------------------------------------------

    always_ff @(negedge SPISCK or posedge SPICS) begin

        if (SPICS) begin

            tx_shift        <= 8'h00;
            spiso_bit       <= 1'b0;
            response_loaded <= 1'b0;

        end else begin

            // Command byte has just been received.
            if (command_strobe && !response_loaded) begin

                case (command_byte)

                    // Command 0x9F returns 0xA5
                    8'h9F: begin

                        tx_shift  <= 8'hA5;

                        // First bit of A5 = 1
                        spiso_bit <= 1'b1;

                    end


                    // Unknown command
                    default: begin

                        tx_shift  <= 8'h00;
                        spiso_bit <= 1'b0;

                    end

                endcase

                response_loaded <= 1'b1;

            end


            // Shift response MSB first
            else if (response_loaded) begin

                tx_shift <= {
                    tx_shift[6:0],
                    1'b0
                };

                spiso_bit <= tx_shift[6];

            end


            // During command byte FPGA returns 0x00
            else begin

                spiso_bit <= 1'b0;

            end
        end
    end

endmodule