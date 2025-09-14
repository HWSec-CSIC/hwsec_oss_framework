#==============================================================================
#
#  Firmware Makefile for the SE-QUBIP PicoRV32 SoC
#
#  This Makefile handles the compilation of C and Assembly source files
#  into a final firmware binary (.bin) and memory initialization file (.hex).
#  It uses an efficient two-stage compilation process (source -> object -> elf)
#  with automatic header dependency generation.
#
#==============================================================================

#------------------------------------------------------------------------------
# Project Configuration
#------------------------------------------------------------------------------
# Firmware Name (used for output files)
FW = firmware

# Linker Script Filename
LD = riscv.ld

# Key Directories
SRC_DIR = src
LD_DIR  = ld
LIB_DIR = lib
OBJ_DIR = bin/obj
BIN_DIR = bin

# Global Debug Flag
# Set to 1 to enable debug features (like printf) in the C code.
# Set to 0 for a smaller, optimized release build.
ENABLE_DEBUG = 0


#------------------------------------------------------------------------------
# RISC-V Toolchain Configuration
#------------------------------------------------------------------------------
# The prefix for the RISC-V GCC toolchain commands.
XCHAIN  = riscv64-unknown-elf-

# Application Binary Interface (ABI) and Architecture.
# These must match the hardware implementation of the PicoRV32 core.
ABI     = ilp32
ARCH    = rv32imc


#------------------------------------------------------------------------------
# Compiler and Linker Flags
#------------------------------------------------------------------------------
# CFLAGS: Flags passed to the compiler for EVERY .c and .s file.
CFLAGS  = 	-Os -Wall -mabi=$(ABI) -march=$(ARCH) \
			-DENABLE_DEBUG=$(ENABLE_DEBUG) \
			-nostdlib -fno-pic -fno-stack-protector -ffreestanding \
          	-MMD -MP # These two flags enable automatic header dependency generation

# LDFLAGS: Flags passed to the linker during the final .elf creation step.
LDFLAGS = -Wl,-Bstatic,--build-id=none,-T,$(LD_DIR)/$(LD),-Map,$(BIN_DIR)/$(FW).map,--strip-debug#,--no-relax

# Path to the required GCC library (libgcc.a), which provides software
# implementations for operations not supported in hardware (e.g., 64-bit division).
RVTOOLCHAIN_GCC_LIB_DIR = /opt/riscv/lib/gcc/riscv64-unknown-elf/14.2.0/$(ARCH)/$(ABI)/
LIBS := $(RVTOOLCHAIN_GCC_LIB_DIR)libgcc.a
# LIBS := $(wildcard $(LIB_DIR)/*.a)


#------------------------------------------------------------------------------
# Source File Discovery and Object File Generation
#------------------------------------------------------------------------------
# Find all C and Assembly source files recursively within the source directory.
C_FILES := $(wildcard $(SRC_DIR)/*.c) $(wildcard $(SRC_DIR)/*/*.c) 
S_FILES := $(wildcard $(SRC_DIR)/*.S) $(wildcard $(SRC_DIR)/*/*.S)
s_FILES := $(wildcard $(SRC_DIR)/*.s) $(wildcard $(SRC_DIR)/*/*.s)

# Automatically generate the corresponding object file (.o) and dependency file (.d)
# names based on the source file lists. These will be placed in the OBJ_DIR.
C_OBJS := $(patsubst $(SRC_DIR)/%.c, $(OBJ_DIR)/%.o, $(C_FILES))
S_OBJS := $(patsubst $(SRC_DIR)/%.S, $(OBJ_DIR)/%.o, $(S_FILES))
s_OBJS := $(patsubst $(SRC_DIR)/%.s, $(OBJ_DIR)/%.o, $(s_FILES))
OBJS   := $(C_OBJS) $(S_OBJS) $(s_OBJS)
DEPS   := $(OBJS:.o=.d)


#==============================================================================
# Main Build Targets
#==============================================================================

# The default target, executed when 'make' is run without arguments.
# It builds all final firmware artifacts.
all: $(BIN_DIR)/$(FW).hex $(BIN_DIR)/$(FW).bin $(BIN_DIR)/$(FW).dis


# --- Rule to link the final executable (.elf) from all object files ---
# This is the final linking stage. It depends on all object files, the linker
# script, and the Makefile itself (so changes to CFLAGS/LDFLAGS trigger a re-link).
$(BIN_DIR)/$(FW).elf: $(OBJS) $(LD_DIR)/$(LD) Makefile
	$(XCHAIN)gcc $(CFLAGS) $(LDFLAGS) $(OBJS) $(LIBS) -o $@
	$(XCHAIN)size -t $(OBJS)
	$(XCHAIN)size -t $@


# --- Pattern Rules to compile source files (.c, .s) into object files (.o) ---
# These rules teach Make how to build a single .o file from a single source file.
# This enables efficient, incremental builds.

# Rule for C files: Compiles a .c file into a .o file.
# Also generates a .d dependency file thanks to the -MMD flag.
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c Makefile
	@mkdir -p $(dir $@)
	$(XCHAIN)gcc $(CFLAGS) -c $< -o $@

# Rule for Assembly files: Assembles a .s file into a .o file.
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.S Makefile
	@mkdir -p $(dir $@)
	$(XCHAIN)gcc $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.s Makefile
	@mkdir -p $(dir $@)
	$(XCHAIN)gcc $(CFLAGS) -c $< -o $@


# --- Rules for generating final firmware formats from the .elf file ---

# Rule to generate a disassembly file for debugging.
$(BIN_DIR)/$(FW).dis: $(BIN_DIR)/$(FW).elf
	$(XCHAIN)objdump -g -d -l -S --source-comment='#' $< > $@

# Rule to generate a raw binary file for programming.
$(BIN_DIR)/$(FW).bin: $(BIN_DIR)/$(FW).elf
	$(XCHAIN)objcopy -O binary $< $@

# Rule to generate a Verilog-compatible hex memory file from the binary.
# $(BIN_DIR)/$(FW).hex: $(BIN_DIR)/$(FW).elf
# 	$(XCHAIN)objcopy -O verilog $< $@
$(BIN_DIR)/$(FW).hex: $(BIN_DIR)/$(FW).bin
	hexdump -v -e '1/4 "%08x\n"' $< > $@


#==============================================================================
# Utility Targets
#==============================================================================

# This rule ensures the output directory exists before trying to place files in it.
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

# Rule to clean up all generated files.
clean:
	rm -rf $(BIN_DIR)

# --- Include Automatic Dependencies ---
# This line includes all the .d files generated by the compiler.
# These files contain rules that tell Make which .o files depend on which .h files.
# The '-' prefix prevents Make from erroring if the .d files don't exist yet (e.g., on a clean build).
-include $(DEPS)

# --- Phony Targets ---
# This tells Make that 'all' and 'clean' are command names, not actual files.
# This ensures they run every time they are called.
.PHONY: all clean