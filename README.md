# AHB
AMBA AHB-Lite Pipelined Verification Environment

SystemVerilog implementation and verification environment for an AMBA AHB-Lite slave, demonstrating pipelined bus operation and verification of address-data phase overlap.

Overview

This project implements an AMBA AHB-Lite slave along with a verification environment designed to validate pipelined transfers and protocol compliance.

The goal of this project is to:

Understand AHB pipelined architecture

Implement AHB-Lite slave logic

Verify address and data phase overlap

Build structured verification components

Architecture
Design Components
| Module         | Description                             |
| -------------- | --------------------------------------- |
| `ahb_slave.sv` | AHB-Lite slave implementation           |
| `ahb_if.sv`    | AHB interface defining protocol signals |

Verification Components
| Component       | Description                                               |
| --------------- | --------------------------------------------------------- |
| `tb_classes.sv` | Transaction, driver, monitor classes                      |
| `tb_top.sv`     | Testbench top connecting DUT and verification environment |


AHB Features Implemented

AHB-Lite protocol support

Pipelined transfers

Address and data phase separation

Read and write transactions

HREADY and HRESP handling

Basic burst support (if applicable)

Verification Methodology

Verification flow:

Transactions generated in testbench

Driver applies stimulus to DUT

Monitor samples bus activity

Results validated using console output and waveform analysis

Verification checks include:

Correct pipelined operation

Proper handshake behavior

Accurate data transfer



Simulation
Tools Used

ModelSim / QuestaSim / Vivado Simulator

Steps

Compile SystemVerilog files

Run simulation using tb_top

Observe waveform for pipelined transfers

Expected behavior:

Address phase followed by data phase overlap

Correct read/write operations

Valid handshake signaling



Results

Successful verification of pipelined transfers

Correct protocol timing observed

Data integrity maintained across transactions



