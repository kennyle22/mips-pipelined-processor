# MIPS Pipelined Processor

A 32-bit MIPS pipelined processor implemented in Verilog, synthesized on an Artix-7 FPGA using Xilinx Vivado.

## Features

- Full 5-stage pipeline: IF → ID → EX → MEM → WB
- Data forwarding unit to resolve RAW hazards without stalling
- Hazard detection unit for load-use stall insertion
- Supports R-type, I-type, Load/Store, Branch, and Jump instructions
- Parameterized pipeline register modules

## Resource Utilization (Artix-7 xc7a100tcsg324-1)

| Resource | Used | Available |
|----------|------|-----------|
| LUT | 2318 | 41000 |
| FF | 1297 | 82000 |
| DSP | 3 | 240 |
| IO | 34 | 300 |

## Project Structure

```
src/
├── top/          — Top-level mips_32 module
├── stages/       — IF, ID, EX, MEM, WB stage modules
├── pipeline_regs/— Pipeline register modules (IF/ID, ID/EX, EX/MEM, MEM/WB)
├── units/        — ALU, control unit, forwarding unit, hazard detection
└── memory/       — Instruction ROM, data RAM
sim/              — Testbenches and test programs (hex)
constraints/      — Vivado timing constraints (.xdc)
vivado/           — TCL project setup script
```

## Tools

- **Simulator:** Icarus Verilog / Xilinx Vivado xsim
- **Synthesis:** Xilinx Vivado
- **Target FPGA:** Artix-7 (xc7a100tcsg324-1)
