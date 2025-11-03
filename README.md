# FPGA-Low latency market compute

## Project Overview  
This repository contains a learning project designed to implement a simple FPGA‑based system for real‑time market‑data feed handling.
The project receives simulated UDP market‑data packets (symbol, price, volume), parses them in hardware, and outputs a buy trigger based on a threshold condition.  
Developed as part of my self‑guided FPGA and hardware‑software integration exploration, this design demonstrates low‑latency data processing and FPGA pipeline concepts relevant to high‑performance trading systems.

## Key Features  
- UDP packet reception (Python simulation) and hardware feed input via Ethernet/UDP interface.  
- Verilog modules implementing packet parsing from Ethernet → IPv4 → UDP → payload.  
- Hardware decision logic: if `price < THRESHOLD`, generate a “BUY” trigger via LED/GPIO.  
- Basic latency measurement: timestamping or cycle‑count tracking to compare hardware vs software baseline.  
- Modular and parameterised Verilog design that can be extended to more complex trading logic.  
- Clean structure and simulation‑ready testbenches for parser and decision logic.
- New feature will be added along the way.

## Module Descriptions  

###  Feed Simulator (Python)  
A simple Python script (`udp_feed_simulator.py`) generates UDP packets with fields: symbol (ASCII), price (floating or fixed‑point), and volume (uint). The script runs on PC to simulate market‑data feed.  
**Usage:** Configure symbol, price, volume, send rate.  
**Purpose:** Provides software baseline and feed input for FPGA design.

###  Packet Parsing Pipeline (Verilog)  
The core hardware logic comprises a chain of modules:  
- `eth_rx.v`: Ethernet MAC/frame receiver interface (or simplified input model)  
- `ip_udp_parser.v`: Parses IPv4 header and UDP header to extract payload stream  
- `payload_parser.v`: Parses payload fields (symbol, price, volume) and outputs structured data  
These modules form the low‑latency ingress path for market data.

###  Decision Logic (Verilog)  
`decision_logic.v` implements a simple trigger mechanism: when the parsed `price` is below a compile‑time (or runtime) threshold, `buy_trigger` is asserted. Trigger output is mapped to LED/GPIO or sent over UART for demonstration.  
**Latency Measurement:** A counter or timestamp captures arrival vs trigger output latency in cycles or microseconds.

## Usage Notes  
1. Clone the repository:  
   ```bash
   git clone https://github.com/roshandubey13/fpga‑low‑latency‑market‑feed.git
