/**
 * @file MockI2C.hpp
 * @brief Mock I2C Controller for QEMU Testing
 * 
 * This implementation doesn't access real hardware registers.
 * It simulates I2C behavior for testing in QEMU without peripherals.
 * 
 * Routes I2C addresses to appropriate mock devices:
 * - 0x48: TMP100 temperature sensor (MockTMP100)
 * - 0x50: 24FC256 EEPROM (MockEEPROM)
 * 
 * IMPORTANT:
 * MockI2C would be replaced with STM32's I2C controller on real hardware. 
 * For testing, test_logger.cpp implements a realistic I2C mock (RealI2CMock) that simulates device behavior.
 */

#pragma once
#include "II2CController.hpp"
#include "MockEEPROM.hpp"
#include <cstdint>

class MockI2C : public II2CController {
public:
    MockI2C() {
        // No hardware initialization needed
    }
    
    I2CStatus Write(uint8_t addr, const uint8_t* data, size_t len) override {
        // Route to appropriate mock device
        if (addr == 0x50) {
            // 24FC256 EEPROM
            return m_eeprom.Write(data, len);
        } else if (addr == 0x48) {
            // TMP100 temperature sensor
            return I2CStatus::Nack;  // No mock TMP100 yet
        }
        
        return I2CStatus::Nack;
    }
    
    I2CStatus Read(uint8_t addr, uint8_t* buffer, size_t len) override {
        // Route to appropriate mock device
        if (addr == 0x50) {
            // EEPROM doesn't support plain Read (needs WriteRead)
            return I2CStatus::Nack;
        } else if (addr == 0x48) {
            // TMP100 temperature sensor
            // Return dummy data
            for (size_t i = 0; i < len; i++) {
                buffer[i] = 0x00;
            }
            return I2CStatus::Nack;  // Mock always fails
        }
        
        return I2CStatus::Nack;
    }
    
    I2CStatus WriteRead(uint8_t addr, const uint8_t* tx, size_t txLen,
                       uint8_t* rx, size_t rxLen) override {
        // Route to appropriate mock device
        if (addr == 0x50) {
            // 24FC256 EEPROM: write address, then read data
            return m_eeprom.Read(tx, txLen, rx, rxLen);
        } else if (addr == 0x48) {
            // TMP100 temperature sensor
            // Return dummy data
            for (size_t i = 0; i < rxLen; i++) {
                rx[i] = 0x00;
            }
            return I2CStatus::Nack;  // Mock always fails
        }
        
        return I2CStatus::Nack;
    }
    
    // Test helper: access EEPROM mock directly
    MockEEPROM& GetEEPROMMock() {
        return m_eeprom;
    }
    
private:
    MockEEPROM m_eeprom;
};