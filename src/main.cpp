/**
 * @file main.cpp
 * @brief Temperature logger - logs every 10 minutes
 * 
 * Uses MockI2C and MockTimer for testing in QEMU - main is for gdb, test_logger is for unit testing
 * test_logger shows a complete test suite with realistic I2C behavior and should be run for evidence of correctness.
 */

#include "MockI2C.hpp"
#include "MockTimer.hpp"
#include "TMP100.hpp"
#include "EEPROM24FC256.hpp"
#include <cstdint>

// Global variables visible in GDB
volatile uint32_t g_sampleCount = 0;
volatile float g_lastTemperature = 0.0f;
volatile uint16_t g_eepromAddress = 0;
volatile bool g_initSuccess = false;
volatile bool g_readSuccess = false;
volatile bool g_writeSuccess = false;
volatile int16_t g_lastEncoded = 0;

// Status string (view in GDB: x/s g_status)
const char* g_status = "Starting...";

int main() {
    g_status = "Creating I2C controller";
    MockI2C i2cBus;
    
    g_status = "Creating timer";
    MockTimer timer;
    timer.Init();
    
    g_status = "Creating TMP100 sensor";
    TMP100 tempSensor(i2cBus, 0x48);
    // TMP100 I2C address is 0x48
    
    g_status = "Creating EEPROM logger";
    EEPROM24FC256 dataLogger(i2cBus, 0x50);
    //   EEPROM I2C address is 0x50
    
    g_status = "Initializing TMP100";
    g_initSuccess = tempSensor.Init();
    
    uint16_t eepromAddress = 0;
    uint32_t lastLogTime = 0;
    g_status = "Entering main loop";
    
    // sample for max capacity of EEPROM w/ 2 byte samples (16384 times)
    while (g_sampleCount < 16384) {
        uint32_t currentTime = timer.GetElapsedSeconds();
        
        // Check if 10 minutes (600 seconds) have elapsed from 1Hz tick simulation
        if (currentTime - lastLogTime >= 600) {
            g_status = "Reading temperature";
            float temperature = tempSensor.ReadTemperature();
            
            if (temperature < -900.0f) {
                // Simulate read failure
                g_readSuccess = false;
                temperature = 20.0f + (float)(g_sampleCount * 0.01f);
                // Provide dummy temperature for testing
            } else {
                g_readSuccess = true;
            }
            
            g_lastTemperature = temperature;
            
            g_status = "Encoding temperature";
            int16_t encoded = (int16_t)(temperature * 16.0f);
            // Store last encoded value for inspection
            g_lastEncoded = encoded;
            
            g_status = "Writing to EEPROM";
            g_writeSuccess = dataLogger.LogData(eepromAddress, temperature);
            
            g_status = "Updating address";
            
            // Update EEPROM address (circular buffer)
            eepromAddress += 2;
            if (eepromAddress >= 32766) {
                eepromAddress = 0;  // Wrap around
            }
            
            g_eepromAddress = eepromAddress;
            
            g_status = "Incrementing counter";
            g_sampleCount++;
            
            // Update last log time for next 10-minute interval
            lastLogTime = currentTime;
            
            // For QEMU testing: advance timer quickly
            // In real hardware: this loop would block/sleep until next interrupt
            timer.AdvanceTime(600);
        }
    }
    
    g_status = "Done";
    
    while (1) {
        for (volatile uint32_t i = 0; i < 0x00100000; i++);
    }
    
    return 0;
}

extern "C" void SystemInit(void) {
}
// Minimal SystemInit for bare-metal (no clock setup needed for simulation)