# 32-bit Five-Stage Pipelined RISC-V Processor

## Project Overview

Designed and implemented a 32-bit RISC-V (RV32I) processor using Verilog HDL with a five-stage pipelined architecture. The project focuses on understanding processor architecture, RTL design, instruction execution, pipeline operation, and hazard handling.

## Architecture

The processor consists of five pipeline stages:

1. **Instruction Fetch (IF):** Fetches instructions from instruction memory.
2. **Instruction Decode (ID):** Decodes instructions and reads source registers.
3. **Execute (EX):** Performs arithmetic, logical, and address calculation operations.
4. **Memory Access (MEM):** Performs data memory read and write operations.
5. **Write Back (WB):** Writes the execution or memory result back to the register file.

## Features

- 32-bit RV32I processor architecture
- Five-stage pipelined datapath
- 32 general-purpose registers
- Arithmetic and logical operations
- Data forwarding unit
- Hazard detection unit
- Load-use hazard stall handling
- Branch instructions: BEQ, BNE, BLT, BGE, BLTU and BGEU
- Jump instructions: JAL and JALR
- Load and store operations: LB, LBU, LH, LHU, LW, SB, SH and SW
- Pipeline flushing for control-flow changes

## RTL Design Modules

The processor is implemented using modular Verilog HDL components, including:

- ALU and ALU control unit
- Control unit
- Register file
- Instruction memory and data memory
- Program counter and immediate generator
- Forwarding unit and hazard detection unit
- Branch unit and PC update logic
- IF/ID, ID/EX, EX/MEM and MEM/WB pipeline registers
- Writeback unit

## Verification

Developed SystemVerilog testbenches and verified the processor in Xilinx Vivado Simulator (XSim).

| Verification Stage | Test Coverage | Result |
|---|---|---|
| Stage 1 | Basic instruction execution | PASS |
| Stage 2 | Data forwarding and load-use hazards | PASS |
| Stage 3 | Branch and jump instructions | PASS |
| Stage 4 | Arithmetic and logical operations | PASS |
| Stage 5 | Load and store operations | PASS |

**Verification Summary:** All five verification stages completed with zero reported testbench errors for the tested instruction sequences.

## Tools and Technologies

- Verilog HDL
- SystemVerilog
- Xilinx Vivado
- Vivado Simulator (XSim)

## Repository Structure

```text
riscv-5stage-processor/
│
├── rtl/
│   └── Verilog design source files
│
├── testbench/
│   └── SystemVerilog testbenches
│
├── constraints/
│   └── FPGA constraint files (if applicable)
│
├── reports/
│   └── Synthesis and implementation reports (to be added)
│
├── README.md
└── .gitignore
```

## Project Status

- RTL design completed.
- Five functional verification stages completed.
- FPGA synthesis and implementation are planned as the next step.

## Author

**Anji Babu**

M.Tech – VLSI Design

**Area of Interest:** RTL Design, ASIC/SoC Design and Functional Verification