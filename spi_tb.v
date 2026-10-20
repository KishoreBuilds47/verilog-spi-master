
`timescale 1ns/1ps

module spi_tb;

    parameter TOTAL_BYTES = 1024;
    parameter CPOL_VALUE = 0;
    parameter CPHA_VALUE = 0;

    reg clk_50MHZ = 0;
    reg reset = 1;
    reg start = 0;
    reg [7:0] tx_data = 0;
    reg miso_data = 0;
    reg cs = 1;
    reg CPOL=1;
    reg CPHA=0;

    wire cs_n;
    wire mosi;
    wire clk_1MHZ;
    wire busy;
    wire [7:0] rx_data;
    wire done;

    reg [7:0] tx_memory [0:TOTAL_BYTES-1];
    reg [7:0] rx_memory [0:TOTAL_BYTES-1];

    reg [7:0] tx_seen;

    integer i;
    integer bit_index;
    integer byte_index;
    integer tx_errors;
    integer rx_errors;
    integer miso_bit_pos;

    // 50 MHz clock: 20 ns period
    always #10 clk_50MHZ = ~clk_50MHZ;

    // Instantiate SPI master
    spi #(
        .TOTAL_BYTES(TOTAL_BYTES)
    ) dut (
        .clk_50MHZ(clk_50MHZ),
        .reset(reset),
        .start(start),
        .tx_data(tx_data),
        .miso_data(miso_data),
        .cs(cs),
        .CPOL(CPOL),
        .CPHA(CPHA),
        .cs_n(cs_n),
        .mosi(mosi),
        .clk_1MHZ(clk_1MHZ),
        .busy(busy),
        .rx_data(rx_data),
        .done(done)
    );

    initial begin

        CPOL = CPOL_VALUE;
        CPHA = CPHA_VALUE;

        // Initialize TX and RX data patterns
        for (i = 0; i < TOTAL_BYTES; i = i + 1) begin
            tx_memory[i] = (i * 37 + 8'hA5) & 8'hFF;
            rx_memory[i] = (i * 19 + 8'h5A) & 8'hFF;
        end

        tx_errors = 0;
        rx_errors = 0;
        tx_seen = 0;
        miso_bit_pos = 0;

        // Apply reset
        repeat (5) @(negedge clk_50MHZ);
        reset = 0;

        // Load the first TX byte
        tx_data = tx_memory[0];

        // Prepare the first MISO bit
        // CPHA=0 needs the first bit before the first sample edge
        if (CPHA == 0) begin
            miso_data = rx_memory[0][7];
            miso_bit_pos = 1;
        end
        else begin
            miso_data = 0;
            miso_bit_pos = 0;
        end

        // Assert start only once
        @(negedge clk_50MHZ);
        start = 1;

        @(negedge clk_50MHZ);
        start = 0;

        // Wait for transfer to begin
        wait (busy == 1'b1);

        $display("==============================================================");
        $display("          SPI MASTER FULL-DUPLEX VERIFICATION");
        $display("==============================================================");
        $display("TOTAL_BYTES = %0d", TOTAL_BYTES);
        $display("CPOL        = %0d", CPOL);
        $display("CPHA        = %0d", CPHA);
        $display("INPUT CLOCK = 50 MHz");
        $display("SPI CLOCK   = 1 MHz");
        $display("TX BITS     = %0d", TOTAL_BYTES * 8);
        $display("RX BITS     = %0d", TOTAL_BYTES * 8);
        $display("BIT ORDER   = MSB First");
        $display("--------------------------------------------------------------");
        $display("Byte | TX Expected | TX Seen | RX Expected | RX Data | Status");
        $display("--------------------------------------------------------------");

        // Check every transmitted and received byte
        for (byte_index = 0;
             byte_index < TOTAL_BYTES;
             byte_index = byte_index + 1) begin

            tx_seen = 8'b0;

            // Capture one complete transmitted byte
            for (bit_index = 0;
                 bit_index < 8;
                 bit_index = bit_index + 1) begin

                // Select the correct SPI sampling edge
                if (CPHA == 0) begin
                    if (CPOL == 0)
                        @(posedge clk_1MHZ);
                    else
                        @(negedge clk_1MHZ);
                end
                else begin
                    if (CPOL == 0)
                        @(negedge clk_1MHZ);
                    else
                        @(posedge clk_1MHZ);
                end

                #1;
                tx_seen = {tx_seen[6:0], mosi};

            end

            // Allow RX nonblocking assignments to settle
            #1;

            // Compare TX byte
            if (tx_seen !== tx_memory[byte_index])
                tx_errors = tx_errors + 1;

            // Compare reconstructed RX byte
            if (rx_data !== rx_memory[byte_index])
                rx_errors = rx_errors + 1;

            // Display both directions
            $display(
                "%0d | %02h | %02h | %02h | %02h | %s",
                byte_index,
                tx_memory[byte_index],
                tx_seen,
                rx_memory[byte_index],
                rx_data,
                ((tx_seen === tx_memory[byte_index]) &&
                 (rx_data === rx_memory[byte_index]))
                    ? "PASS" : "FAIL"
            );

            // Supply next TX byte before its load edge
            if (byte_index < TOTAL_BYTES-1)
                tx_data = tx_memory[byte_index + 1];

        end

        // Wait for final completion
        wait (done == 1'b1);
        #10;

        $display("==============================================================");
        $display("BYTES TRANSFERRED = %0d", byte_index);
        $display("TX BITS CHECKED   = %0d", TOTAL_BYTES * 8);
        $display("RX BITS SENT      = %0d", TOTAL_BYTES * 8);
        $display("TX ERRORS         = %0d", tx_errors);
        $display("RX ERRORS         = %0d", rx_errors);
        $display("BUSY              = %b", busy);
        $display("DONE              = %b", done);

        if ((tx_errors == 0) &&
            (rx_errors == 0) &&
            (busy == 0) &&
            (done == 1))
            $display("RESULT: TX AND RX PASSED");
        else
            $display("RESULT: SPI TEST FAILED");

        $display("==============================================================");

        $finish;
    end

    // Simulated SPI slave: drive MISO serially
    // CPHA=0: change MISO on trailing edges
    // CPHA=1: change MISO on leading edges
    always @(posedge clk_1MHZ or negedge clk_1MHZ) begin
        if (!reset && busy) begin

            if (((CPHA == 0) && (clk_1MHZ == CPOL)) ||
                ((CPHA == 1) && (clk_1MHZ != CPOL))) begin

                if (miso_bit_pos < TOTAL_BYTES * 8) begin

                    miso_data =
                        rx_memory[miso_bit_pos / 8]
                                 [7 - (miso_bit_pos % 8)];

                    miso_bit_pos = miso_bit_pos + 1;

                end
            end
        end
    end

    // Simulation timeout protection
    initial begin
        #12000000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
