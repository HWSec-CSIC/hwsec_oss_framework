# HWSEC OSS FRAMEWORK

Welcome to the HWSEC OSS Framework – a comprehensive open source framework for hardware security research.  This repository integrates a complete digital design flow, from Verilator-based simulation and side-channel analysis to full FPGA implementation, providing a unified environment to model, test, and deploy hardware designs.

## Introduction

This framework simplifies hardware security research with a configurable workflow for simulation, synthesis, firmware development, and side-channel trace generation. All core design parameters are now configured directly within the Makefile, streamlining the setup process. The framework supports a complete open-source toolchain, enabling a seamless path from RTL to FPGA bitstream and analysis.

### Prerequisites

Install these tools to use the framework:

1. [**Verilator (v5.035):**](https://github.com/verilator/verilator) Verilog/SystemVerilog simulator.  
2. [**GTKWave (v3.3.116):**](https://github.com/gtkwave/gtkwave) Waveform visualization tool.  
3. [**Yosys (v0.51):**](https://github.com/YosysHQ/yosys) RTL synthesis framework.  
4. [**Nextpnr (v0.6):**](https://github.com/YosysHQ/nextpnr) Vendor-neutral FPGA place-and-route tool.  
5. [**Project Icestorm:**](https://github.com/YosysHQ/icestorm) Tools for Lattice iCE40 FPGA bitstream generation.  
6. [**RISC‑V GNU toolchain (v14.2.0):**](https://github.com/riscv-collab/riscv-gnu-toolchain) RISC-V C/C++ cross-compiler for firmware.  


## Repository Structure

The content of the repository is depicted in the next container tree:

    .
    ├── fw                          # Firmware code for RISC‑V bare‑metal targets
    │   ├── Makefile                # Firmware build rules
    │   ├── bin                     # Compiled firmware binaries
    │   ├── ld               
    │   │   └── riscv.ld            # Linker script
    │   └── src                     # Firmware source code
    │       ├── firmware.c       
    │       └── start.s          
    ├── pnr                         # Place-and-Route outputs
    ├── prog                        # FPGA programming files
    ├── rtl                         # RTL (Verilog/SystemVerilog) sources and constraint files.
    │   ├── LED_counter.pcf         # FPGA pin constraints
    │   └── LED_counter.v           # Top module (example)
    ├── sim                         # Simulation setup
    │   ├── src
    │   │   ├── testbench.cpp       # Demo C++ testbench (to be updated/modified for your design)
    │   │   ├── sim_utils.cpp       # Auxiliary simulation functions.
    │   │   └── sim_utils.h         # Declarations for simulation utilities.
    │   └── waveform.gtkw           # Optional GTKWave session file.
    ├── synth                       # Synthesis outputs: JSON files, synthesis logs, and statistics.
    │── traces                      # Side-channel analysis traces and tools
    │   ├── fixed                   # Output for fixed-input traces
    │   ├── random                  # Output for random-input traces
    │   ├── src 
    │   │   └── readvcd.c           # Tool to convert VCD to power traces
    │   └── tvla                    # TVLA analysis results
    │       └── TVLA.ipynb          # Jupyter notebook for TVLA analysis
    ├── Makefile                    # Main Makefile for all workflows
    └── README.md                   # This documentation

## Overview

This simulation framework is designed to help you quickly simulate your digital designs. The key steps are:

1. **Replace RTL Files With Your Own:**  
   Place your Verilog/SystemVerilog source files in the **rtl** folder. The provided demo files (e.g., `LED_counter.v`) are provided only as examples and can be overwritten.
   > *Note:* The top module file must be named according to the top module in the makefile. 

2. **Configure the Environment:**  
   All primary configuration is now done at the top of the main Makefile. Open the Makefile and edit the **INITIAL CONFIGURATION** section: 
   - **`TOP_MODULE`**: Set this to the name of your top-level Verilog module (e.g., LED_counter).
   - **`CLOCK_SIGNAL`**: Set this to the name of your top-level Clock signal (e.g., clk).
   - **`MAX_SIM_TIME`**: Define the total simulation time in clock cycles for standard simulations.
   - **`INIT_TIME_TRACES / END_TIME_TRACES`**: Set the range of clock cyles to record the traces for Side-Channel Analysis.
   - **`NUM_FIXED_TRACES / NUM_RANDOM_TRACES`**: Set the number of traces to generate for side-channel analysis.

3. **Customize the Testbench:**  
   Inside the **src** folder, modify the testbench file to provide your own simulation stimulus. You can port your Verilog testbench to C++ using the provided auxiliary functions in `sim_utils.h` and `sim_utils.cpp`.  
   - **Auxiliary Functions:**  
     - **`verilog_delay`** – Inserts delays into the simulation.  
     - **`verilog_display`** – Outputs formatted simulation messages.  
     - **`verilog_monitor`** – Monitors simulation signals.  
     
   > *Note:* To enable monitoring, it is necessary to modify the `sim_step` function inside `sim_utils.cpp`.

4. **Simulate Your Design:**  
   The Makefile automates the build and simulation process:
   - Compile the simulation using Verilator.
   - Run the simulation.
   - Open the waveform in GTKWave.

5. **Synthesize Your Design:**  
   Use Yosys to synthesize your design. Multiple synthesis flows are available:  
   - For Lattice iCE40 devices (e.g., ice40HX8K): execute `make synth-ice40`.  
   - For Xilinx boards: execute `make synth-xilinx`.  
   - For a generic gate-level synthesis flow: execute `make synth-generic`.  
   The synthesis process generates a JSON representation of your design along with synthesis logs and statistics in the `synth` folder, which can help you analyze and refine your implementation.

6. **Place and Route:**  
   After synthesis, run the place and route process using Nextpnr. Simply execute:  
   ```bash
   make nextpnr-ice40
   ```
   This target uses the synthesized JSON file and the constraints file (such as picosoc.pcf in the rtl folder) to map and route your design onto the FPGA. It subsequently invokes icetime to generate timing reports, providing insights into the performance and closure of your design.

7. **Program the Board:** 
   The final step is to program your FPGA board (at the moment only ice40 devices are implemented). Use the target:
   ```bash
   make prog-ice40
   ```
   This target packages your design with icepack to generate a binary image and then programs the device using iceprog.

8. **Compile the Firmware:**
   If your design includes firmware for RISC‑V bare‑metal targets, compile it by running:
   ```bash
   make firmware
   ```
   Ensure that the RISC‑V GNU toolchain is installed prior to compiling the firmware. This step generates the binary firmware (including hexadecimal representation) required to interface with your FPGA design.

9. **Side-Channel Analysis:** 
   If your research involves evaluating the side-channel resilience of your design, the framework provides an integrated flow for generating power traces. This process models power consumption by calculating the Hamming distance of signal toggles during simulation. To generate a full set of traces for analysis, run:
   ```bash
   make traces
   ```
   Ensure that you have configured the desired number of traces (NUM_FIXED_TRACES and NUM_RANDOM_TRACES) in the Makefile. This target automatically handles recompiling the simulator for VCD output, running multiple simulations with fixed and random inputs, and processing each waveform to produce a compact binary trace file in the traces/fixed/ and traces/random/ directories. These traces can then be used with the included TVLA notebook or other analysis tools.
   
## How to Configure and Use the Framework

### Customize the Testbench

Open the testbench file in the **sim/src** folder (`testbench.cpp`) and modify it as needed:

- **Port your own test vectors and simulation stimulus.**
- **Configure simulation parameters** in `Makefile`
- **Leverage auxiliary functions** in `sim_utils.h`/`sim_utils.cpp` to handle delays, formatted output, and signal monitoring.


### Build/Simulate the Design 

- **`make lint`**: Runs a lint-only check on your RTL sources using Verilator.  

- **`make sim`**: Builds and runs the simulation.  

- **`make waves`**: Builds and runs the simulation, generating a .fst waveform. Opens GTKWave to view the generated waveform, using the session file in sim (.gtkw).

### Synthesize the Design

- **`make synth-ice40`**: Synthesis for Lattice ice40.   

- **`make synth-xilinx`**: Synthesis for Xilinx.

- **`make synth-generic`**: Synthesis using logic gates.

### Place and Route

- **`make nextpnr-ice40`**: P&R for Lattice ice40. 

### Programming

- **`make prog-ice40`**: Programming Lattice ice40. 

### Firmware

- **`make firmware`**: Compiles the RISC-V firmware located in the fw/ directory (if your design uses it).

### Side-Channel Trace Generation

- **`make traces`**: Runs multiple simulations with fixed and random inputs. For each run, it generates a .vcd file, processes it with the readvcd tool to create a binary power trace, and cleans up the intermediate .vcd file. Output traces are stored in `traces/fixed/` and `traces/random/`.
> *Note:*  Open and run the traces/tvla/TVLA.ipynb Jupyter Notebook to perform a Test Vector Leakage Assessment (TVLA) on the generated traces.

## Final Remarks

This framework streamlines the process of developing and analyzing secure hardware by integrating simulation, side-channel analysis, synthesis, physical implementation, and firmware development into a single, coherent flow. Whether you are prototyping cryptographic cores or evaluating hardware countermeasures, the HWSEC OSS Framework is designed to accelerate your research and development efforts.

For further details, please refer to:

- [Verilator Documentation](https://veripool.org/verilator/documentation/)
- [GTKWave Documentation](https://gtkwave.sourceforge.net/)
- [Yosys Documentation](https://yosyshq.net/yosys/documentation.html)
- [Nextpnr Documentation](https://github.com/YosysHQ/nextpnr)
- [Icestorm Project](https://clifford.fm/icestorm)
- [RISC‑V GNU Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)

Happy simulating and designing!

## Contact

**ANONYMOUS SUBMISSION**


## Developers

**ANONYMOUS SUBMISSION**
