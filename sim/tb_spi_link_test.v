`timescale 1ns/1ps

module tb_spi_link_test;
    reg  spics;
    reg  spisck;
    reg  spisi;
    wire spiso;

    integer failures;
    reg [7:0] rx0;
    reg [7:0] rx1;

    spi_link_test dut (
        .SPICS  (spics),
        .SPISCK (spisck),
        .SPISI  (spisi),
        .SPISO  (spiso)
    );

    task spi_byte;
        input  [7:0] tx;
        output [7:0] rx;
        integer bit_index;
        begin
            // Mode 0: change MOSI while SCK is low, sample MISO on rising SCK.
            for (bit_index = 7; bit_index >= 0; bit_index = bit_index - 1) begin
                spisi = tx[bit_index];
                #5;
                spisck = 1'b1;
                #1;
                rx[bit_index] = spiso;
                #4;
                spisck = 1'b0;
                #5;
            end
        end
    endtask

    task begin_transaction;
        begin
            spics = 1'b0;
            #5;
        end
    endtask

    task end_transaction;
        begin
            spics = 1'b1;
            spisi = 1'b0;
            #5;
        end
    endtask

    task expect_byte;
        input [7:0] actual;
        input [7:0] expected;
        input [8*48-1:0] label_text;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s expected %02x, got %02x", label_text,
                         expected, actual);
                failures = failures + 1;
            end
        end
    endtask

    task valid_transaction;
        begin
            begin_transaction;
            spi_byte(8'h9f, rx0);
            spi_byte(8'h00, rx1);
            end_transaction;
            expect_byte(rx0, 8'h00, "valid command phase");
            expect_byte(rx1, 8'ha5, "valid response phase");
        end
    endtask

    initial begin
        failures = 0;
        spics  = 1'b0;
        spisck = 1'b0;
        spisi  = 1'b0;

        // Generate an explicit CS rising edge to reset the transaction state.
        #2;
        spics = 1'b1;
        #10;

        // Valid command and explicit MSB-first response check.
        valid_transaction;

        // Invalid command must not produce the signature.
        begin_transaction;
        spi_byte(8'h3f, rx0);
        spi_byte(8'h00, rx1);
        end_transaction;
        expect_byte(rx0, 8'h00, "invalid command phase");
        expect_byte(rx1, 8'h00, "invalid response phase");
        if (rx1 === 8'ha5) begin
            $display("FAIL: invalid command returned the signature");
            failures = failures + 1;
        end

        // Abandon half a command. CS deassertion must discard it.
        begin_transaction;
        spisi = 1'b1; #5; spisck = 1'b1; #5; spisck = 1'b0; #5;
        spisi = 1'b0; #5; spisck = 1'b1; #5; spisck = 1'b0; #5;
        spisi = 1'b0; #5; spisck = 1'b1; #5; spisck = 1'b0; #5;
        spisi = 1'b1; #5; spisck = 1'b1; #5; spisck = 1'b0; #5;
        end_transaction;
        valid_transaction;

        // Back-to-back complete transactions.
        valid_transaction;
        valid_transaction;

        // Reversed bit order (f9 on the wire) must not be accepted as 9f.
        begin_transaction;
        spi_byte(8'hf9, rx0);
        spi_byte(8'h00, rx1);
        end_transaction;
        expect_byte(rx1, 8'h00, "MSB-first ordering rejection");

        if (failures == 0) begin
            $display("PASS: all SPI link tests completed");
            $finish;
        end else begin
            $display("FAIL: %0d check(s) failed", failures);
            $fatal(1);
        end
    end

endmodule
