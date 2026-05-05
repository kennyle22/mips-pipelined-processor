# mips-pipelined-processor

32-bit MIPS processor written in Verilog, synthesized on an Artix-7 FPGA using Vivado. Built for a computer architecture lab at UCI.

## What's in here

5-stage pipeline: IF, ID, EX, MEM, WB. Data forwarding handles most RAW hazards without stalling — load-use hazards still require a one-cycle bubble, which the hazard detection unit inserts. Branch resolution is at the EX/MEM boundary. Supported instructions: R-type, I-type, load/store, branch, and jump.

## Resource utilization (Artix-7 xc7a100tcsg324-1)

| Resource | Used | Available |
|----------|------|-----------|
| LUT      | 2318 | 41000     |
| FF       | 1297 | 82000     |
| DSP      | 3    | 240       |
| IO       | 34   | 300       |

## Timing

Constrained to 50 MHz (20 ns). Timing closure was not met. The critical path runs through the EX stage — forwarding MUX to ALU to Zero flag — and didn't fit within the period. Functional simulation passes; closing timing on hardware would mean either breaking the EX stage across an extra register or relaxing the constraint.

## Project structure

```
src/
├── top/            — top-level mips_32 module
├── stages/         — IF, ID, EX, MEM, WB
├── pipeline_regs/  — IF/ID, ID/EX, EX/MEM, MEM/WB registers
├── units/          — ALU, control unit, forwarding unit, hazard detection
└── memory/         — instruction ROM, data RAM
sim/                — testbenches and test programs (hex)
constraints/        — Vivado timing constraints (.xdc)
```

## Tools

Icarus Verilog and Vivado xsim for simulation. Vivado for synthesis and implementation.
