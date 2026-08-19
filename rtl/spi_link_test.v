// Phase-1 SPI mode-0 link test for STEPFPGA MachXO2.
//
// Transaction, MSB first:
//   master TX: 9f 00
//   slave  TX: 00 a5
//
// MOSI is sampled on rising SPISCK edges. MISO changes only on falling edges.
// SPISO is high impedance while chip select is inactive.
module spi_link_test (
    input  wire SPICS,
    input  wire SPISCK,
    input  wire SPISI,
    output wire SPISO
);

    reg [7:0] rx_shift;
    reg [7:0] command_byte;
    reg [7:0] tx_shift;
    reg [2:0] bit_count;
    reg       command_done;
    reg       command_strobe;
    reg       spiso_bit;

    assign SPISO = SPICS ? 1'bz : spiso_bit;

    // Receive path. Deasserting CS resets the complete transaction.
    always @(posedge SPISCK or posedge SPICS) begin
        if (SPICS) begin
            rx_shift       <= 8'h00;
            command_byte   <= 8'h00;
            bit_count      <= 3'd0;
            command_done   <= 1'b0;
            command_strobe <= 1'b0;
        end else begin
            command_strobe <= 1'b0;
            if (!command_done) begin
                rx_shift <= {rx_shift[6:0], SPISI};
                if (bit_count == 3'd7) begin
                    command_byte   <= {rx_shift[6:0], SPISI};
                    command_done   <= 1'b1;
                    command_strobe <= 1'b1;
                    bit_count      <= 3'd0;
                end else begin
                    bit_count <= bit_count + 3'd1;
                end
            end
        end
    end

    // Transmit path. The half-cycle between the command's final rising edge
    // and the dummy byte's first rising edge prepares response bit 7.
    always @(negedge SPISCK or posedge SPICS) begin
        if (SPICS) begin
            tx_shift  <= 8'h00;
            spiso_bit <= 1'b0;
        end else if (command_strobe) begin
            if (command_byte == 8'h9f) begin
                spiso_bit <= 1'b1;       // 8'ha5 bit 7
                tx_shift  <= 8'h4a;      // remaining response bits
            end else begin
                spiso_bit <= 1'b0;
                tx_shift  <= 8'h00;
            end
        end else begin
            spiso_bit <= tx_shift[7];
            tx_shift  <= {tx_shift[6:0], 1'b0};
        end
    end

endmodule
