# Single-Cycle RV32I RISC-V Processor

## Overview

This project implements a **single-cycle 32-bit RISC-V processor** in **SystemVerilog**. It supports a subset of the **RV32I base integer instruction set**, including arithmetic, logic, load/store, branch, jump, and upper-immediate instructions.
The goal of this project is to understand how a RISC-V CPU works at the RTL level, from instruction fetch to writeback.

## Features

* 32-bit single-cycle datapath
* RV32I instruction support
* Register file with 32 registers
* ALU with arithmetic, logic, comparison, and shift operations
* Immediate generator for I, S, B, U, and J formats
* Control unit and ALU control unit
* Branch and jump control
* 2 KiB data memory
* Load/store unit with byte, halfword, word, signed, unsigned, and misaligned access support
* Memory-mapped I/O for:

  * Red LEDs
  * Green LEDs
  * 7-segment displays
  * LCD
  * Switches

## Supported Instructions

The processor supports the main RV32I instructions:

```text
add, sub, and, or, xor
sll, srl, sra
slt, sltu
addi, andi, ori, xori
slli, srli, srai
slti, sltiu
lb, lh, lw, lbu, lhu
sb, sh, sw
beq, bne, blt, bge, bltu, bgeu
jal, jalr
lui, auipc
```
Environment instructions such as `ecall` and `ebreak` are not implemented.


## Architecture

The processor follows this basic flow:

```text
Instruction Memory
        ↓
Control Unit + Immediate Generator
        ↓
Register File
        ↓
ALU / Branch Control
        ↓
Data Memory or Memory-Mapped I/O
        ↓
Writeback
```

## Memory Map

```text
DMem:      0x0000_0000 - 0x0000_07FF
LEDR:      0x1000_0000
LEDG:      0x1000_1000
HEX0-3:    0x1000_2000
HEX4-7:    0x1000_3000
LCD:       0x1000_4000
Switches:  0x1001_0000
```

The data memory has:

```text
512 words × 4 bytes = 2048 bytes = 2 KiB
```

## Verification

The design was tested using SystemVerilog testbenches and VCS simulation.
Verified blocks include:

```text
Register File
ALU
ALU Control
Immediate Generator
Control Unit
PC Control Unit
LSU
DMem
Memory-Mapped I/O
PC + Instruction Memory
Full Top Integration
```

## Running Simulation

The instruction memory loads machine code from:

```text
program.hex
```

The file must be placed in the folder where `./simv` is executed.
Example:

```bash
./simv
```

## Example Program

```assembly
addi x1, x0, 5
addi x2, x0, 10
add  x3, x1, x2
sw   x3, 0(x0)
lw   x4, 0(x0)
nop
```

Expected result:

```text
x3 = 15
DMem[0] = 15
x4 = 15
```

## Status

The processor currently passes module-level and top-level simulation tests. Future improvements may include more instruction-group tests, cleaner memory initialization, FPGA implementation, and support for more RISC-V features.
