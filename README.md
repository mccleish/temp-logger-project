# Temperature Data Logger

A C++ simulation of a STM32 embedded system that reads temperature every 10 minutes from a TMP100 sensor and stores readings to a 24FC256 EEPROM. 

**Built for:** STM32F103 microcontroller  
**Test environment:** QEMU, makefile for powershell
**Language:** C++17

## Quick Start

```bash
make clean && make              # Build firmware
make test                        # Run test suite (47 tests)
make run                         # Run in QEMU
```

**Testing:** test suite validates all 10-minute logging intervals and EEPROM operations without real hardware. For real hardware, an extra STM I2C and SysTick file would need to be created and main would need to be changed. This could be as simple as importing a library. 

## gdb debugging example:

# Terminal 1
   qemu-system-arm -M netduinoplus2 -nographic -kernel build/temp-logger.elf -s -S
   
   
# Terminal 2
   arm-none-eabi-gdb build/temp-logger.elf
   (gdb) target remote :1234
   (gdb) load
   (gdb) break main
   (gdb) continue
   (gdb) next
   (gdb) print g_sampleCount
   (gdb) print g_lastTemperature
   (gdb) print g_lastEncoded  # temperature encoding
### **Embedded Platform**
- **STM32F103 (ARM Cortex-M3)** chosen
- Bare-metal (no RTOS/OS)
- QEMU-compatible for testing
- File: `Makefile` specifies `-mcpu=cortex-m3 -mthumb`

### **TMP100 I2C Temperature Sensor**
- Custom driver: `include/TMP100.hpp`
- I2C address: 0x48 (ADD0 pin to GND)
- 12-bit resolution (0.0625°C)
- Continuous conversion mode
- No pre-written driver used

### **Microchip 24FC256 EEPROM**
- Custom driver: `include/EEPROM24FC256.hpp`
- I2C address: 0x50
- 32 KB storage (32,768 bytes)
- 64-byte pages with page boundary protection
- ACK polling for write completion
- Datasheet-compliant (Section 6.0 write, Section 8.0 read)
- No pre-written driver used

### **Logging**
- Timer interface: `include/ITimer.hpp`
- MockTimer for testing: `include/MockTimer.hpp`
- For real deployment, SysTick could be used, which could be as simple as including a library. As I have no access to the physical devices, MockTimer was used.
- Checks for 600-second intervals in main() with a for loop simulating timer ticks. (the ticks are not actually at 1Hz for QEMU testing, but this could be implemented).
- Tested with 47 unit tests (including 6 timer-specific tests)

### **Safety**
- No dynamic memory allocation
- Bounds checking on EEPROM addresses (32,768 byte limit)
- Page boundary protection (64-byte pages)
- Error checking on all I2C transactions
- Type-safe with `enum class I2CStatus`
- Const-correct code throughout
- No unbounded loops/recursion

### **Code Design**
- Separation of concerns:
  - I2C abstraction (II2CController interface)
  - Sensor drivers (TMP100, EEPROM24FC256)
  - Timer abstraction (ITimer interface)
  - Application logic (main.cpp)

## Assumptions
- No other I2C masters on bus
- Single-threaded execution
- Able to use MockTimer, MockI2C for testing
- Fixed 64-byte EEPROM pages
- Continuous conversion acceptable
- Oldest data can be overwritten (circular buffer)

## Testing

- 47 unit tests covering:
  - TMP100 temperature reading (various ranges)
  - EEPROM write/read operations
  - Circular buffer management
  - Page boundary handling
  - Fixed-point Q12.4 encoding/decoding
  - 10-minute interval detection
  - Timer functionality

## Datasheet Compliance

### TMP100 (TI Datasheet)
- Continuous conversion mode
- I2C random read (Section 8.2)
- 12-bit temperature register (8.1.3)
- Address bits configurable via ADD0 pin

### 24FC256 (Microchip Datasheet)
- Byte write operations (Section 6.1)
- Page boundary protection (Section 6.2)
- ACK polling for write detection (Section 4.5)
- Control byte format with R/W bit
- Random read with address (Section 8.2)

## Build & Test

```bash
make clean && make              # Builds firmware
make test                        # Runs 47 tests (PASS)
make run                         # Runs in QEMU
```

## Hardware Deployment Path

The code is limited because it is a simulation.
To deploy on real STM32F103:
1. Replace MockI2C (limitation)
2. Replace MockTimer (limitation)
3. Add linker script for flash/RAM layout (limitation)
4. Add startup code (already in src/startup.s) (limitation)
5. Flash build/temp-logger.elf to microcontroller


## Design Choices

### Fixed-Point Storage (Not Float)
- 2 bytes vs 4 bytes saves 50% storage  
- Eliminates floating-point rounding errors
- Matches sensor precision (0.0625 deg C)
- Faster encode/decode (multiply/divide by 16)

### Continuous Conversion Mode (Not One-Shot)
- Simplifies code, power acceptable  
- Temperature always ready
- No conversion trigger needed
- 50 microAmp difference negligible for wall-powered system

### ACK Polling for Write Completion
- Reliable and efficient  
- Returns immediately when write finishes (~3ms)
- Datasheet-recommended approach
- More reliable than fixed delay

### Circular Buffer (Wrap at End)
- Infinite logging, simple design  
- Never need to manage "full" condition
- Oldest data silently overwritten
- Acceptable for facility monitoring
