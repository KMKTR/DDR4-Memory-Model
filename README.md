# 🧠 DDR4 Memory System in Verilog/SystemVerilog

This repository contains a complete simulation model of a **DDR4 SDRAM system**, including:
- ✅ Memory Controller
- ✅ DDR4 RTL core
- ✅ DFI Interface
- ✅ Top-level integration

The project demonstrates core DDR4 operations: mode register configuration, row activation, burst-based read/write, and precharge logic — all designed and simulated in Verilog/SystemVerilog.

---

## 📁 Files Included

| File                | Description                                 |
|---------------------|---------------------------------------------|
| `mem_controller.sv` | Generates commands (ACTIVATE, READ, WRITE) to DDR4 |
| `ddr4rtl.sv`        | Core DDR4 memory model with timing behavior |
| `dfiinterface.sv`   | DFI-style shell interface between controller and RTL |
| `ddr4_top.sv`       | Integrates all modules into a full system |
| `README.md`         | This file - documentation and overview |

---

## 🧠 Project Overview

### 🔹 What It Does
- Simulates **DDR4 behavior** including:
  - Mode Register Setting (MRS)
  - Row Activation
  - Burst READ / WRITE
  - Precharge cycle
  - DQ data masking
  - Bank group addressing
  - CAS latency emulation

### 🔹 Why This is Useful
- Understand timing and command flow of DDR4
- Practice state machine design for memory protocols
- Explore how burst lengths and access types affect memory throughput

---

## ⚙️ Module Descriptions

### 🟩 `mem_controller.sv`
Implements the FSM that:
- Initializes the memory
- Selects between READ and WRITE
- Controls RAS, CAS, WE, CS signals
- Issues PRECHARGE commands

### 🟦 `ddr4rtl.sv`
Core memory logic:
- Parses address into row, column, bank
- Loads Mode Registers (MR0, MR1)
- Handles burst logic: sequential & interleaved
- Responds to CAS latency and precharge delays
- Performs inout DQ bus operations

### 🟧 `dfiinterface.sv`
Simple shell for DFI-standard interface — forward control, address, and data lines.

### 🟥 `ddr4_top.sv`
Top module wiring:
- Connects `mem_controller`, `dfi_interface`, and `ddr4rtl`
- Routes address/data/control lines between modules
- Handles bidirectional DQ bus

---

