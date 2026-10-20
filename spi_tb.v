
`timescale 1ns/1ps

module spi_tb;

    reg clk_50MHZ = 0;
    reg reset = 1;
    reg start = 0;
    reg [7:0] tx_data = 0;
    reg miso_data = 0;
    reg cs = 1;

    wire cs_n;
    wire mosi;
    wire clk_1MHZ;
    wire busy;
    wire [7:0] rx_data;
    wire done;

    reg [7:0] memory [0:1023];
    reg [7:0] tx_seen;

    integer i;
    integer bit_index;
    integer byte_index;
    integer errors;

    // 50 MHz clock: 20 ns period
    always #10 clk_50MHZ = ~clk_50MHZ;

    // Instantiate SPI master
    spi #(
        .TOTAL_BYTES(1024)
    ) dut (
        .clk_50MHZ(clk_50MHZ),
        .reset(reset),
        .start(start),
        .tx_data(tx_data),
        .miso_data(miso_data),
        .cs(cs),
        .cs_n(cs_n),
        .mosi(mosi),
        .clk_1MHZ(clk_1MHZ),
        .busy(busy),
        .rx_data(rx_data),
        .done(done)
    );

    initial begin

        // Initialize 1024 bytes of test data
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = (i * 37 + 8'hA5) & 8'hFF;

        errors = 0;
        tx_seen = 0;
        bit_index = 0;
        byte_index = 0;

        // Apply reset
        repeat (5) @(negedge clk_50MHZ);
        reset = 0;

        // Load the first byte before starting
        tx_data = memory[0];

        // Assert start only once
        @(negedge clk_50MHZ);
        start = 1;

        @(negedge clk_50MHZ);
        start = 0;

        // Wait for the transfer to begin
        wait (busy == 1'b1);

        $display("========================================");
        $display("      SPI 1024-BYTE TRANSFER TEST");
        $display("========================================");

        // Capture each transmitted byte
        for (byte_index = 0;
             byte_index < 1024;
             byte_index = byte_index + 1) begin

            tx_seen = 8'b0;

            for (bit_index = 0;
                 bit_index < 8;
                 bit_index = bit_index + 1) begin

                // SPI Mode 0: capture MOSI on rising SCLK
                @(posedge clk_1MHZ);
                #1;

                tx_seen = {tx_seen[6:0], mosi};

            end

            // Compare the complete transmitted byte
            if (tx_seen !== memory[byte_index]) begin
                errors = errors + 1;

                $display(
                    "FAIL Byte %0d | Expected=%02h Seen=%02h",
                    byte_index,
                    memory[byte_index],
                    tx_seen
                );
            end
            else if (byte_index < 10 ||
                     byte_index == 1023) begin

                // Print first 10 bytes and the final byte
                $display(
                    "PASS Byte %0d | TX=%02h",
                    byte_index,
                    tx_seen
                );
            end

            // Supply the next byte before its load edge
            if (byte_index < 1023)
                tx_data = memory[byte_index + 1];

        end

        // Verify completion
        wait (done == 1'b1);
        #10;

        $display("----------------------------------------");
        $display("Bytes checked = %0d", byte_index);
        $display("Byte errors   = %0d", errors);
        $display("BUSY          = %b", busy);
        $display("DONE          = %b", done);

        if (errors == 0 && busy == 0 && done == 1)
            $display("RESULT: ALL 1024 BYTES PASSED");
        else
            $display("RESULT: SPI TEST FAILED");

        $display("========================================");

        $finish;
    end

    // Simulation timeout protection
    initial begin
        #12000000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
