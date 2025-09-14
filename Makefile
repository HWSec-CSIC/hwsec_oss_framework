#==========================================================================
# INITIAL CONFIGURATION
#==========================================================================

TOP_MODULE 			= LED_counter
CLOCK_SIGNAL		= clk
MAX_SIM_TIME		= 1000
INIT_TIME_TRACES	= 0
END_TIME_TRACES		= $(MAX_SIM_TIME)
NUM_TRACES 			= 100


#==========================================================================
# Directories
#==========================================================================

RTL_DIR    	= rtl
SRC_DIR	   	= src
SIM_DIR		= sim
VOBJ_DIR    = $(SIM_DIR)/$(SRC_DIR)/obj_dir
FW_DIR		= fw
SYNTH_DIR	= synth
PNR_DIR		= pnr
PROG_DIR	= prog
TRACES_DIR  = traces

# This file will store the name of the last configuration used.
LAST_CONFIG_STAMP = $(VOBJ_DIR)/.last_config


#==========================================================================
# FPGA Target
#==========================================================================

BOARD			= ice40hx8k
FPGA_VARIANT 	= hx8k
FPGA_PACKAGE	= ct256
CLOCK_FREQUENCY = 12 


#==========================================================================
# RTL/SW/FW Files
#==========================================================================

# Firmware Name
FW = firmware

# Linker Name
LD = riscv.ld

# Additional Technology Libraries
TECHLIBS_DIR = /home/navarro/Desktop/FPGA/yosys/techlibs/xilinx

# Gather all source files (Verilog/SystemVerilog header and source files)
RTL_FILES = $(shell find $(RTL_DIR) -name '*.vh') \
			$(shell find $(RTL_DIR) -name '*.svh') \
            $(shell find $(RTL_DIR) -name '*.v') \
            $(shell find $(RTL_DIR) -name '*.sv')
				
# Gather all source files (C++ files)
CPP_FILES = $(SIM_DIR)/$(SRC_DIR)/testbench.cpp $(SIM_DIR)/$(SRC_DIR)/sim_utils.cpp

CPPH_FILES = $(SIM_DIR)/$(SRC_DIR)/sim_utils.h

# TECHLIB_FILES = $(TECHLIBS_DIR)/cells_sim.v 

# Derived variable for the simulation binary, built by Verilator
SIM_BIN = $(VOBJ_DIR)/V$(TOP_MODULE)

#==========================================================================
# TVLA Configuration
#==========================================================================

READ_VCD = $(TRACES_DIR)/$(SRC_DIR)/readvcd


#==========================================================================
# Waveform Configuration
#==========================================================================
# This variable controls the output format of the simulation waveform.
# Supported values:
#   - fst: Fast Signal Trace (default, smaller files, faster simulation)
#   - vcd: Value Change Dump (standard, more compatible, but very large files)

WAVEFORM_TYPE			= fst
VERILATOR_TRACE_FLAG   	= --trace-fst
CPP_DEFINES       		= -DWAVEFORM_TYPE_FST

# Automatically determine the full waveform filename based on the type
WAVEFORM_FILE          	= $(SIM_DIR)/waveform.$(WAVEFORM_TYPE)

sim: CFG=sim
sim: VERILATOR_TRACE_FLAG 		:= --trace-fst
sim: CPP_DEFINES     			:= 

waves: CFG=waves
waves: VERILATOR_TRACE_FLAG 	:= --trace-fst
waves: CPP_DEFINES     			:= -DWAVEFORM_TYPE_FST

traces: CFG=traces
traces: WAVEFORM_TYPE 			:= vcd
traces: VERILATOR_TRACE_FLAG 	:= --trace-vcd -O3 --x-assign fast --x-initial fast 
traces: CPP_DEFINES    			:= -DWAVEFORM_TYPE_VCD -O3 -march=native
traces: WAVEFORM_FILE        	:= $(SIM_DIR)/waveform.vcd


#==========================================================================
# PHONY Targets
#==========================================================================

.PHONY: sim waves lint firmware synth-ice40 synth-xilinx synth-generic nextpnr-ice40 traces clean dirs _check_config

#==========================================================================
# Simulation and Build Rules
#==========================================================================

# "sim" produces a VCD by running the simulation binary
sim: _check_config $(SIM_BIN)
	@echo
	@echo "### SIMULATING ###"
	@$(SIM_BIN)

# Build the simulation binary
build: $(SIM_BIN)

# "waves" simulate and opens GTKWave with the generated VCD/FST file
waves: _check_config $(SIM_BIN)
	@echo
	@echo "### SIMULATING ###"
	@$(SIM_BIN)
	@echo
	@echo "### WAVES ###"
	gtkwave $(WAVEFORM_FILE) -a $(SIM_DIR)/waveform.gtkw

# Build the simulation binary
$(SIM_BIN): $(RTL_FILES) $(CPP_FILES) $(CPPH_FILES) Makefile
	@echo
	@echo "### VERILATING ###"
	verilator -Wno-fatal $(VERILATOR_TRACE_FLAG) --timescale-override /100ps -Mdir $(VOBJ_DIR) -cc $(RTL_FILES) $(TECHLIB_FILES) --exe $(CPP_FILES) \
	--top $(TOP_MODULE) -j `nproc` -I$(TECHLIBS_DIR) -CFLAGS "$(CPP_DEFINES) -DTOP_HEADER='\"V$(TOP_MODULE).h\"' -DTOP_MODULE=$(TOP_MODULE) \
	-DMAX_SIM_TIME=$(MAX_SIM_TIME) -DINIT_TIME_TRACES=$(INIT_TIME_TRACES) -DEND_TIME_TRACES=$(END_TIME_TRACES) -DCLOCK_SIGNAL=$(CLOCK_SIGNAL)"
	@echo
	@echo "### BUILDING SIM ###"
	$(MAKE) -C $(VOBJ_DIR) -f V$(TOP_MODULE).mk V$(TOP_MODULE)


#==========================================================================
# Linting Rule (for Verilator lint-only check)
#==========================================================================

lint: $(RTL_FILES)
	verilator --lint-only -Wall --top-module $(TOP_MODULE) $(RTL_FILES) $(TECHLIB_FILES) -I$(TECHLIBS_DIR) 


#==========================================================================
# Firmware Rule
#==========================================================================

firmware:
	@echo
	@echo "### BUILDING FIRMWARE ###"
	$(MAKE) -C $(FW_DIR)


#==========================================================================
# Create SYNTH_DIR, PNR_DIR, PROG_DIR, and TRACES directories
#==========================================================================

dirs:
	@mkdir -p $(SYNTH_DIR) $(PNR_DIR) $(PROG_DIR) $(TRACES_DIR)/fixed $(TRACES_DIR)/random $(TRACES_DIR)/tvla


#==========================================================================
# Synthesis Rules
#==========================================================================

synth-ice40: dirs $(SYNTH_DIR)/$(TOP_MODULE).json
$(SYNTH_DIR)/$(TOP_MODULE).json: $(RTL_FILES)
	yosys -ql $(SYNTH_DIR)/$(TOP_MODULE).log -p "synth_ice40 -top $(TOP_MODULE) -json $(SYNTH_DIR)/$(TOP_MODULE).json; json -noscopeinfo -o $(SYNTH_DIR)/$(TOP_MODULE).json; tee -o $(SYNTH_DIR)/stat.txt stat" $(RTL_FILES)

synth-xilinx: dirs $(RTL_FILES)
	yosys -ql $(SYNTH_DIR)/$(TOP_MODULE).log -p "synth_xilinx -family xc7 -top $(TOP_MODULE) -json $(SYNTH_DIR)/$(TOP_MODULE).json; json -noscopeinfo -o $(SYNTH_DIR)/$(TOP_MODULE).json; tee -o $(SYNTH_DIR)/stat.txt stat" $(RTL_FILES)

synth-generic: dirs $(RTL_FILES)
	yosys -ql $(SYNTH_DIR)/$(TOP_MODULE).log -p "synth -top $(TOP_MODULE); tee -o $(SYNTH_DIR)/stat.txt stat" $(RTL_FILES) $(TECHLIB_FILES)


#==========================================================================
# Place & Route Rule
#==========================================================================

nextpnr-ice40: dirs $(PNR_DIR)/$(TOP_MODULE).asc
$(PNR_DIR)/$(TOP_MODULE).asc: $(SYNTH_DIR)/$(TOP_MODULE).json $(RTL_DIR)/$(TOP_MODULE).pcf
	nextpnr-ice40 --force --timing-allow-fail --json  $(SYNTH_DIR)/$(TOP_MODULE).json --pcf $(RTL_DIR)/$(TOP_MODULE).pcf --asc $(PNR_DIR)/$(TOP_MODULE).asc --freq $(CLOCK_FREQUENCY) --$(FPGA_VARIANT) --package $(FPGA_PACKAGE) --pcf-allow-unconstrained --opt-timing
	icetime -p $(RTL_DIR)/$(TOP_MODULE).pcf -P $(FPGA_PACKAGE) -r $(PNR_DIR)/$(TOP_MODULE).timings -d $(FPGA_VARIANT) -t $(PNR_DIR)/$(TOP_MODULE).asc


#==========================================================================
# Program Rule
#==========================================================================

prog_ice40: dirs $(PNR_DIR)/$(TOP_MODULE).asc $(FW_DIR)/bin/$(FW).bin
	icepack $(PNR_DIR)/$(TOP_MODULE).asc $(PROG_DIR)/$(TOP_MODULE).bin
	iceprog $(PROG_DIR)/$(TOP_MODULE).bin
# iceprog -o 1M $(FW_DIR)/bin/$(FW).bin


#==========================================================================
# TVLA Rules
#==========================================================================

$(READ_VCD): $(TRACES_DIR)/$(SRC_DIR)/readvcd.c
	@echo "Building readvcd tool..."
	gcc -Wall -O3 $(TRACES_DIR)/$(SRC_DIR)/readvcd.c -o $(TRACES_DIR)/$(SRC_DIR)/readvcd

traces: _check_config $(READ_VCD) $(SIM_BIN) dirs
	@echo
	@echo "### TOGGLE COVERAGE ANALYSIS ###"
	@echo "Generating traces and converting to binary format..."
	@echo "  Fixed  traces: $(NUM_TRACES)"
	@echo "  Random traces: $(NUM_TRACES)\n"
	@# Generate traces (VCD files will be auto-converted to binary and removed)
	@for i in $$(seq 0 $$(($(NUM_TRACES) - 1))); do \
		printf " Simulating fixed  trace %d/$(NUM_TRACES)...\r" $$i; \
		./$(SIM_DIR)/$(SRC_DIR)/obj_dir/V$(TOP_MODULE) --trace_index $$i; \
		./$(TRACES_DIR)/$(SRC_DIR)/readvcd $(SIM_DIR)/waveform_$$i.vcd NULL $(TRACES_DIR)/fixed/trace_$$i.bin; \
		rm $(SIM_DIR)/waveform_$$i.vcd;\
		printf " Simulating random trace %d/$(NUM_TRACES)...\r" $$i; \
		./$(SIM_DIR)/$(SRC_DIR)/obj_dir/V$(TOP_MODULE) --trace_index $$i --trace_random; \
		./$(TRACES_DIR)/$(SRC_DIR)/readvcd $(SIM_DIR)/waveform_$$i.vcd NULL $(TRACES_DIR)/random/trace_$$i.bin; \
		rm $(SIM_DIR)/waveform_$$i.vcd;\
	done


#==========================================================================
# Check Previous Configuration 
#==========================================================================

_check_config:
	@mkdir -p $(VOBJ_DIR)
	@if [ ! -f "$(LAST_CONFIG_STAMP)" ] || [ "$$(cat $(LAST_CONFIG_STAMP))" != "$(CFG)" ]; then \
		echo "Configuration changed to '$(CFG)'. Forcing a rebuild."; \
		rm -rf $(VOBJ_DIR)/*; \
		echo "$(CFG)" > $(LAST_CONFIG_STAMP); \
	fi


#==========================================================================
# Clean generated files
#==========================================================================

clean:
	rm -rf $(VOBJ_DIR)
	rm -rf $(SIM_DIR)/waveform.fst*
	rm -rf $(SIM_DIR)/waveform.vcd*
	rm -rf $(SIM_DIR)/waveform_*
	rm -rf $(FW_DIR)/bin/*
	rm -rf $(SYNTH_DIR)/*
	rm -rf $(PNR_DIR)/*
	rm -rf $(PROG_DIR)/*
	rm -rf $(TRACES_DIR)/$(SRC_DIR)/readvcd
	rm -rf $(TRACES_DIR)/fixed/*
	rm -rf $(TRACES_DIR)/random/*

 
