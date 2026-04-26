# 8-bit DA1

Verilog project for an 8-bit processor design.

## Contents

- `ALU/`: 8-bit ALU and arithmetic modules.
- `ProgramCounter/`: 6-bit program counter.
- `InstructionRegister/`: instruction register and ROM test data.
- `DataMemory/`: 8-bit data memory.
- `GPIOs/`: output register module.
- `control.v`, `datapath.v`, `main8.v`: top-level control, datapath, and main design files.
- `*_tb.v`: testbenches for simulation.
- `Report.pptx`: project report.

## Simulation

Use Icarus Verilog to compile and run individual testbenches, for example:

```sh
iverilog -o main8 main8.v main8_tb.v
vvp main8
```
