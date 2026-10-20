# Verilog SPI Master Controller

A Verilog-based SPI (Serial Peripheral Interface) master controller designed for serial data communication and verified using AMD/Xilinx Vivado 2026.1 and XSim. The project currently demonstrates continuous transmission of 1024 bytes using a 1 MHz SPI clock, with automated testbench verification.

The design is being extended to support manually configurable Clock Polarity (CPOL) and Clock Phase (CPHA), enabling operation across all four standard SPI modes.

## Features

- 50 MHz input clock
- 1 MHz SPI clock
- 1024-byte continuous data transmission
- Manually configurable CPOL and CPHA (implementation in progress)
- Support planned for SPI Modes 0, 1, 2, and 3
- 8-bit serial data transmission through MOSI
- Most Significant Bit (MSB) first transmission
- Active-low chip select (`cs_n`)
- Start, busy, and done control signals
- Automated testbench verification
- Behavioral simulation using Vivado XSim

## SPI Configuration

| Parameter | Value |
|---|---|
| Interface | SPI Master |
| Input Clock | 50 MHz |
| SPI Clock | 1 MHz |
| Data Width | 8 bits |
| Transfer Length | 1024 bytes |
| Data Order | MSB first |
| CPOL | Configurable input (planned) |
| CPHA | Configurable input (planned) |
| Simulation Tool | AMD/Xilinx Vivado 2026.1 |

## SPI Modes

The SPI mode is selected by the combination of Clock Polarity (CPOL) and Clock Phase (CPHA).

| SPI Mode | CPOL | CPHA | Clock Idle State | Sampling Edge |
|---|---:|---:|---|---|
| Mode 0 | 0 | 0 | Low | Rising |
| Mode 1 | 0 | 1 | Low | Falling |
| Mode 2 | 1 | 0 | High | Falling |
| Mode 3 | 1 | 1 | High | Rising |

- **CPOL:** Determines the idle level of the SPI clock.
- **CPHA:** Determines which clock edge is used to sample data.

Configurable CPOL and CPHA allow the controller to communicate with SPI peripherals that require different clocking modes. All four modes must be individually verified after the configurable timing logic is implemented.

## How It Works

The SPI master controller receives an 8-bit data byte and transmits it serially through MOSI. The controller manages the SPI clock, bit counter, byte counter, chip select, and transfer status.

1. **Reset:** Initializes the controller and its internal registers.
2. **Start:** Initiates the data transfer.
3. **Data transmission:** Sends each byte serially, most-significant bit first.
4. **Continuous transfer:** Progresses through the 1024-byte test sequence.
5. **Busy status:** Indicates that the transfer is in progress.
6. **Completion:** Asserts `done` when the transfer finishes and deasserts `busy`.

The testbench stores test data in a simulated memory array, supplies the data to the controller, captures the transmitted MOSI bits, and compares each reconstructed byte with the expected value.

## Project Structure

```text
verilog-spi-master/
├── spi.v
├── spi_tb.v
├── README.md
└── waveforms/
    ├── spi_full_transfer.png
    ├── spi_timing_detail.png
    └── spi_1024_byte.wcfg
```

- `spi.v` — SPI master controller RTL design.
- `spi_tb.v` — Testbench for verifying the 1024-byte transmission.
- `README.md` — Project documentation.
- `waveforms/` — Optional waveform screenshots and Vivado waveform configuration.

The waveform files are optional. Add them only after creating the actual files; otherwise, omit the `waveforms/` folder from the repository structure.

## Simulation and Verification

The design was simulated using Vivado XSim in behavioral simulation mode.

### Test Configuration

- Simulation top module: `spi_tb`
- Input clock: 50 MHz
- SPI clock: 1 MHz
- Transfer length: 1024 bytes
- Currently verified mode: SPI Mode 0

### Simulation Output

The following output was obtained from the successful 1024-byte transmission test.

```text
========================================
      SPI 1024-BYTE TRANSFER TEST
========================================

PASS Byte 0 | TX=a5
PASS Byte 1 | TX=ca
PASS Byte 2 | TX=ef
PASS Byte 3 | TX=14
PASS Byte 4 | TX=39
PASS Byte 5 | TX=5e
PASS Byte 6 | TX=83
PASS Byte 7 | TX=a8
PASS Byte 8 | TX=cd
PASS Byte 9 | TX=f2
PASS Byte 1023 | TX=80

----------------------------------------
Bytes checked = 1024
Byte errors   = 0
BUSY          = 0
DONE          = 1

RESULT: ALL 1024 BYTES PASSED
========================================
```

### Verification Summary

| Test Parameter | Result |
|---|---|
| Total bytes checked | 1024 |
| MOSI byte mismatches | 0 |
| BUSY after transfer | 0 |
| DONE after transfer | 1 |
| Overall result | PASS |

**Result:** All 1024 transmitted bytes matched the expected test data, with zero MOSI mismatches. The controller completed the transfer and asserted the `done` signal.

The reported simulation completion time was approximately 8.192 ms, consistent with transmitting 8192 bits at a 1 MHz SPI clock, excluding controller overhead.

**Verification scope:** This test verifies MOSI transmission against the expected test data. MISO reception and received-data correctness have not yet been verified by this testbench.

The results above apply to the previously verified Mode 0 implementation. The configurable CPOL/CPHA implementation should be tested separately for all four modes.

## Tools Used

- Verilog HDL
- AMD/Xilinx Vivado 2026.1
- XSim behavioral simulator
- Git
- GitHub

## Future Improvements

- Complete manually configurable CPOL and CPHA support.
- Verify SPI Modes 0, 1, 2, and 3 independently.
- Verify MISO reception using a simulated SPI slave.
- Add received-data comparison and error detection.
- Support configurable transfer lengths.
- Implement a programmable SPI clock divider.
- Develop a reusable SPI master interface for other digital systems.

## Author

**KishoreBuilds47**

GitHub: [KishoreBuilds47](https://github.com/KishoreBuilds47)

---

*This project was developed as a digital design, serial communication, and RTL verification learning project.*
