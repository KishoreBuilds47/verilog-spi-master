
`timescale 1ns/1ps

module spi(
    input wire clk_50MHZ,
    input wire reset,
    input wire start,
    input wire [7:0] tx_data,
    input wire miso_data,
    input wire cs,
    input wire CPOL,
    input wire CPHA,

    output wire cs_n,
    output reg mosi,
    output reg clk_1MHZ,
    output reg busy,
    output reg [7:0] rx_data,
    output reg done
);

    reg [7:0] temp;
    reg [4:0] clk_count = 0;
    reg [2:0] bit_count = 0;
    reg [10:0] byte_count = 0;
    reg next_byte_pending;
    reg[7:0] rx_temp;

    wire edge_tick;
    wire leading_tick;
    wire trailing_tick;
    wire sample_tick;
    wire change_tick;

    parameter TOTAL_BYTES = 10; //Total bytes for tcl console to display

    //spi clock generation
    always @(posedge clk_50MHZ) begin
        if (reset) begin
            clk_count <= 0;
            clk_1MHZ <= CPOL;
        end
        else if (clk_count == 24) begin
            clk_count <= 0;
            clk_1MHZ <= ~clk_1MHZ; //(50/2*25) = 1MHz
        end
        else begin
            clk_count <= clk_count + 1'b1;
        end
    end

    assign edge_tick = (clk_count == 24);

    assign leading_tick = edge_tick && (clk_1MHZ == CPOL);

    assign trailing_tick = edge_tick && (clk_1MHZ != CPOL);

    assign sample_tick = (CPHA == 0) ? leading_tick : trailing_tick;

    assign change_tick = (CPHA == 0) ? trailing_tick : leading_tick;

    //chip select logic
    assign cs_n = ~(cs || busy);

    always @(posedge clk_50MHZ) begin
        if (reset) begin
            temp <= 8'b0;
            mosi <= 1'b0;
            bit_count <= 3'b0;
            byte_count <= 11'b0;
            next_byte_pending <= 1'b0;
            rx_data <= 8'b0;
            rx_temp <= 8'b0;
            busy <= 1'b0;
            done <= 1'b0;
        end
        else if (start && !busy) begin
            temp <= {tx_data[6:0], 1'b0};
            mosi <= tx_data[7];

            bit_count <= 3'b0;
            byte_count <= 11'b0;
            next_byte_pending <= 1'b0;

            busy <= 1'b1;
            done <= 1'b0;
            rx_temp <= 8'b0;
        end
        else if (edge_tick && busy) begin

            if (sample_tick) begin
                rx_temp <= {rx_temp[6:0], miso_data};

                if (bit_count == 3'b111) begin
                    bit_count <= 3'b000;
                    rx_data <= {rx_temp[6:0], miso_data};

                    if (byte_count == TOTAL_BYTES - 1) begin
                        byte_count <= byte_count + 1'b1;
                        busy <= 1'b0;
                        done <= 1'b1;
                    end
                    else begin
                        byte_count <= byte_count + 1'b1;
                        next_byte_pending <= 1'b1;
                    end
                end
                else begin
                    bit_count <= bit_count + 1'b1;
                end
            end

            else if (change_tick) begin
                if (next_byte_pending) begin
                    temp <= {tx_data[6:0], 1'b0};
                    mosi <= tx_data[7];
                    next_byte_pending <= 1'b0;
                end
                else if (bit_count != 3'b000) begin
                    mosi <= temp[7];
                    temp <= {temp[6:0], 1'b0};
                end
            end
        end
    end

endmodule
