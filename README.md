
# Verilog SPI Master

A Verilog-based SPI Master controller designed to transmit and receive serial data using the **Serial Peripheral Interface (SPI)** protocol. The project is simulated and verified using **AMD Vivado 2026.1 and XSim**.

## Features

- **SPI Clock Generation:** Generates a 1 MHz SPI clock from a 50 MHz input clock.
- **Configurable SPI Modes:** Supports all four SPI modes using `CPOL` and `CPHA` control inputs.
- **Serial Data Transmission:** Transmits 8-bit data serially through MOSI, MSB first.
- **Serial Data Reception:** Receives serial data through MISO and reconstructs the 8-bit received byte.
- **Full-Duplex Communication:** Supports simultaneous transmission and reception.
- **Continuous Data Transfer:** Designed to handle transfers of up to 1024 bytes.
- **Chip Select Control:** Controls the active-low chip-select output.
- **Status Signals:** Uses `busy` to indicate an active transfer and `done` to indicate completion.
- **Testbench Verification:** Uses a Verilog testbench to simulate SPI communication and check transmitted and received data.

## SPI Modes

The controller uses the `CPOL` and `CPHA` inputs to select the SPI operating mode.

| SPI Mode | CPOL | CPHA | Clock Idle State |
|---|---:|---:|---|
| Mode 0 | 0 | 0 | Low |
| Mode 1 | 0 | 1 | Low |
| Mode 2 | 1 | 0 | High |
| Mode 3 | 1 | 1 | High |

- **CPOL (Clock Polarity):** Determines the idle level of the SPI clock.
- **CPHA (Clock Phase):** Determines which clock edge is used to sample data.

## Hardware Interface

| Signal | Direction | Description |
|---|---|---|
| `clk_50MHZ` | Input | 50 MHz system clock |
| `reset` | Input | Resets the SPI controller |
| `start` | Input | Starts a data transfer |
| `tx_data[7:0]` | Input | Byte to be transmitted |
| `miso_data` | Input | Serial data received from the SPI slave |
| `cs` | Input | Chip-select request |
| `CPOL` | Input | SPI clock polarity selection |
| `CPHA` | Input | SPI clock phase selection |
| `cs_n` | Output | Active-low chip-select signal |
| `mosi` | Output | Master Out, Slave In |
| `clk_1MHZ` | Output | Generated SPI clock |
| `rx_data[7:0]` | Output | Received byte |
| `busy` | Output | Indicates an active transfer |
| `done` | Output | Indicates transfer completion |

## Tools Used

- Verilog HDL
- AMD Vivado 2026.1
- XSim simulator

## Simulation and Verification

The project uses a Verilog testbench to simulate the SPI master and an SPI slave data source.

The verification process includes:

1. Generating the system clock and reset.
2. Selecting the desired SPI mode.
3. Providing transmission data to the master.
4. Simulating incoming slave data on MISO.
5. Checking transmitted MOSI data against expected values.
6. Checking received `rx_data` against expected slave data.
7. Monitoring `busy`, `done`, and chip-select behavior.

The intended large-transfer test uses 1024 bytes, allowing continuous data transfers to be checked over a substantial number of clock edges.

> **Verification note:** Update the results section with the actual simulation output after the full-duplex testbench has passed for all four SPI modes.

## Project Structure

```text
verilog-spi-master/
├── spi.v             # SPI Master RTL design
├── spi_tb.v          # SPI testbench
└── README.md         # Project documentation
```

*Adjust the filenames above if your actual Vivado project uses different names.*

## Future Improvements

- Make the SPI clock frequency programmable using a configurable clock divider.
- Support variable transfer lengths instead of a fixed byte count.
- Add tests for reset during transfer, back-to-back transfers, and boundary conditions.
- Improve chip-select timing and support multiple SPI slave devices.
- Add optional parity or CRC-based error detection.
- Validate the design on an FPGA board using a logic analyzer or oscilloscope.
- Evaluate FPGA resource utilization, timing performance, and power consumption.

## Learning Outcomes

This project explores:

- SPI protocol fundamentals and timing.
- Clock division and edge detection in synchronous digital logic.
- Finite-state and counter-based control logic.
- Serial-to-parallel data reception and parallel-to-serial transmission.
- Verilog testbench development and simulation-based verification.
- Debugging timing differences between SPI operating modes.

## Author

Developed as a digital design project to explore SPI communication, Verilog RTL design, and simulation-based verification.

## License

This project is available for educational and learning purposes. Add a license file if you intend to distribute it under a specific open-source license.

