# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

32-bit MIPS pipelined processor implemented in Verilog, targeting the Artix-7 FPGA (xc7a100tcsg324-1) using Xilinx Vivado. Supports R-type, I-type, Store/Load, and Branch instructions with full data forwarding and hazard detection.

## Module Hierarchy

```
mips_32 (top)
├── IF_pipe_stage       — Instruction fetch, PC logic
├── pipe_reg_IF_ID      — IF/ID pipeline register
├── ID_pipe_stage       — Decode, register file read, control signals
├── pipe_reg_ID_EX      — ID/EX pipeline register
├── EX_pipe_stage       — ALU, forwarding MUX selection
│   └── EX_Forwarding_unit
├── pipe_reg_EX_MEM     — EX/MEM pipeline register
├── MEM_pipe_stage      — Data memory read/write
├── pipe_reg_MEM_WB     — MEM/WB pipeline register
├── WB_pipe_stage       — Write-back to register file
├── hazard_detection    — Stall logic for load-use hazards
├── data_memory         — Synchronous data RAM
└── instruction_mem     — ROM loaded from hex file
```

## Key Design Decisions

- Pipeline registers are parameterized (`pipe_reg.v` base module) for signal width flexibility
- Forwarding unit resolves RAW hazards in EX stage; hazard detection unit handles load-use stalls (insert bubble)
- Timing critical path runs through EX stage (ALU + forwarding MUX) — the `.xdc` constraint targets 50MHz to achieve timing closure on Artix-7
- Data memory is synchronous write, asynchronous read

## Instruction Support

| Type | Instructions |
|------|-------------|
| R-type | ADD, SUB, AND, OR, SLT, SLL, SRL |
| I-type | ADDI, ANDI, ORI, SLTI, LUI |
| Load/Store | LW, SW |
| Branch | BEQ, BNE |
| Jump | J |

## Simulation

Run testbench with any Verilog simulator (e.g., Vivado xsim, ModelSim, or Icarus Verilog):

```bash
# Icarus Verilog
iverilog -o sim/out sim/tb_mips_32.v src/**/*.v
vvp sim/out

# Vivado (run from project directory)
# Use vivado/project_setup.tcl to recreate the project
```

## Vivado Project

Recreate the Vivado project from the TCL script:
```
vivado -source vivado/project_setup.tcl
```

Target part: `xc7a100tcsg324-1` (Artix-7). Timing constraint: 20ns clock period (50MHz) in `constraints/timing.xdc`.
