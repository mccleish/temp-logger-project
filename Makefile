##############################################################################
# Makefile for Temperature Data Logger
#
# Targets:
#   all     - Build firmware (default)
#   clean   - Remove build artifacts
#   test    - Run unit tests
#   run     - Run in QEMU
#   debug   - Start QEMU with GDB server
#   help    - Show available targets
##############################################################################

# Project name
PROJECT = temp-logger

# Toolchain
PREFIX = arm-none-eabi-
CC = $(PREFIX)gcc
CXX = $(PREFIX)g++
AS = $(PREFIX)as
LD = $(PREFIX)ld
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump
SIZE = $(PREFIX)size
GDB = $(PREFIX)gdb

# Directories
SRC_DIR = src
INC_DIR = include
BUILD_DIR = build

# Source files
C_SOURCES = 
CXX_SOURCES = $(SRC_DIR)/main.cpp \
              $(SRC_DIR)/runtime.cpp

ASM_SOURCES = $(SRC_DIR)/startup.s

# Include directories
INCLUDES = -I$(INC_DIR)

# CPU and architecture flags
CPU = -mcpu=cortex-m3
ARCH = -mthumb

# C/C++ flags
COMMON_FLAGS = $(CPU) $(ARCH)
COMMON_FLAGS += -Wall -Wextra -Werror
COMMON_FLAGS += -ffunction-sections -fdata-sections  # Enable garbage collection
COMMON_FLAGS += -fno-exceptions  # Disable exceptions (saves code size)
COMMON_FLAGS += -fno-rtti  # Disable RTTI (saves code size)
COMMON_FLAGS += -fno-use-cxa-atexit  # Don't use __cxa_atexit for destructors
COMMON_FLAGS += -g3  # Full debugging info
COMMON_FLAGS += -O2  # Optimize for size/speed balance (-Os for pure size)

# C-specific flags
CFLAGS = $(COMMON_FLAGS)
CFLAGS += -std=c11

# C++-specific flags
CXXFLAGS = $(COMMON_FLAGS)
CXXFLAGS += -std=c++14  # C++14 (could use c++11 or c++17)
CXXFLAGS += -fno-threadsafe-statics  # No thread-safe static init (saves code)

# Assembly flags
ASFLAGS = $(CPU) $(ARCH) -g

# Linker flags
LDFLAGS = $(CPU) $(ARCH)
LDFLAGS += -T linker.ld  # Linker script
LDFLAGS += -nostartfiles  # Don't use standard startup files
LDFLAGS += -nostdlib  # Don't use standard library
LDFLAGS += -Wl,--gc-sections  # Remove unused sections
LDFLAGS += -Wl,-Map=$(BUILD_DIR)/$(PROJECT).map  # Generate map file
LDFLAGS += -Wl,--print-memory-usage  # Show memory usage

# Object files
OBJECTS = $(addprefix $(BUILD_DIR)/, $(notdir $(C_SOURCES:.c=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/, $(notdir $(CXX_SOURCES:.cpp=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/, $(notdir $(ASM_SOURCES:.s=.o)))

# Dependency files
DEPS = $(OBJECTS:.o=.d)

# QEMU settings
QEMU = qemu-system-arm
QEMU_MACHINE = netduinoplus2
QEMU_FLAGS = -nographic -serial null

# Default target
.PHONY: all
all: $(BUILD_DIR)/$(PROJECT).elf $(BUILD_DIR)/$(PROJECT).bin $(BUILD_DIR)/$(PROJECT).hex
	@echo "Build complete!"
	@$(SIZE) $(BUILD_DIR)/$(PROJECT).elf

ifeq ($(OS),Windows_NT)
    MKDIR = mkdir build 2>nul || exit 0

else
    MKDIR = mkdir -p build
endif

build:
	$(MKDIR)

# Compile C++ source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	@echo "Compiling $<..."
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -MMD -MP -c $< -o $@

# Compile C source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	@echo "Compiling $<..."
	@$(CC) $(CFLAGS) $(INCLUDES) -MMD -MP -c $< -o $@

# Assemble assembly files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s | $(BUILD_DIR)
	@echo "Assembling $<..."
	@$(AS) $(ASFLAGS) $< -o $@

# Link ELF file
$(BUILD_DIR)/$(PROJECT).elf: $(OBJECTS) linker.ld
	@echo "Linking $@..."
	@$(CXX) $(OBJECTS) $(LDFLAGS) -lc -lgcc -o $@

# Create binary file (for programming)
$(BUILD_DIR)/$(PROJECT).bin: $(BUILD_DIR)/$(PROJECT).elf
	@echo "Creating binary: $@"
	@$(OBJCOPY) -O binary $< $@

# Create hex file (alternative format)
$(BUILD_DIR)/$(PROJECT).hex: $(BUILD_DIR)/$(PROJECT).elf
	@echo "Creating hex file: $@"
	@$(OBJCOPY) -O ihex $< $@

# Include dependency files
-include $(DEPS)

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning..."
	@powershell -Command "if (Test-Path '$(BUILD_DIR)') { Remove-Item -Recurse -Force '$(BUILD_DIR)' }"

# Run in QEMU
.PHONY: run
run: $(BUILD_DIR)/$(PROJECT).elf
	@echo "Running in QEMU..."
	@echo "Note: QEMU doesn't have actual TMP100/EEPROM devices by default"
	@echo "Press Ctrl-A then X to exit QEMU"
	@$(QEMU) -M $(QEMU_MACHINE) $(QEMU_FLAGS) -kernel $<



# Debug in QEMU (start GDB server)
.PHONY: debug
debug: $(BUILD_DIR)/$(PROJECT).elf
	@echo "Starting QEMU with GDB server on port 1234..."
	@echo "In another terminal, run: make gdb"
	@$(QEMU) -M $(QEMU_MACHINE) $(QEMU_FLAGS) \
		-kernel $< \
		-s -S  # -s = GDB server on :1234, -S = halt at startup

# Connect GDB client
.PHONY: gdb
gdb: $(BUILD_DIR)/$(PROJECT).elf
	@echo "Connecting GDB to localhost:1234..."
	@$(GDB) $< \
		-ex "target remote :1234" \
		-ex "load" \
		-ex "break main" \
		-ex "continue"

# Show memory usage
.PHONY: size
size: $(BUILD_DIR)/$(PROJECT).elf
	@echo "Memory usage:"
	@$(SIZE) -B $<
	@echo ""
	@echo "Section sizes:"
	@$(SIZE) -A $<



# Show help
.PHONY: help
help:
	@echo "Temperature Data Logger - Makefile Help"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build firmware (default)"
	@echo "  clean     - Remove build artifacts"
	@echo "  test      - Build and run unit tests"
	@echo "  run       - Run in QEMU emulator"
	@echo "  debug     - Start QEMU with GDB server (port 1234)"
	@echo "  gdb       - Connect GDB client to debug session"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make              # Build firmware"
	@echo "  make test         # Run unit tests"
	@echo "  make clean all    # Clean rebuild"
	@echo "  make run          # Run in QEMU"
	@echo "  make debug        # Start debug session (terminal 1)"
	@echo "  make gdb          # Connect debugger (terminal 2)"
	@echo ""
	@echo "Requirements:"
	@echo "  - arm-none-eabi-gcc toolchain"
	@echo "  - qemu-system-arm emulator"
	@echo "  - (optional) arm-none-eabi-gdb for debugging"

# Build and run tests (native - not cross-compiled)
.PHONY: test
test:
	@echo "Building test suite (native compilation)..."
	@echo "Compiling test_logger.cpp..."
	@g++ -std=c++14 -Wall -Wextra -Werror \
		-I$(INC_DIR) \
		src/test_logger.cpp \
		src/TMP100.cpp \
		src/EEPROM24FC256.cpp \
		-o $(BUILD_DIR)/test_logger.exe
	@echo ""
	@echo "Running tests..."
	@$(BUILD_DIR)/test_logger.exe


