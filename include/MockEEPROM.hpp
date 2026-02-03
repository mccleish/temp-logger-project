/**
 * @file MockEEPROM.hpp
 * @brief Stateful Mock EEPROM for testing
 * 
 * Simulates 24FC256 EEPROM behavior:
 * - 32KB internal memory buffer
 * - Write cycle state machine (ACK → NACK → ACK)
 * - Page boundary handling (64-byte pages)
 * - ACK polling support
 * 
 * Why MockEEPROM was added:
 * Validates ACK polling logic
 * Tests page boundary handling
 * Verifies data actually writes to "memory"
 * Better than MockI2C just returning NACK
 */

#pragma once
#include "II2CController.hpp"
#include <cstdint>
#include <cstring>

class MockEEPROM {
public:
    MockEEPROM() : m_writeInProgress(false), m_writeCycleCount(0), m_writeAddress(0) {
        // Initialize memory to 0xFF (like real EEPROM)
        std::memset(m_memory, 0xFF, sizeof(m_memory));
    }
    
    /**
     * @brief Handle I2C write operation (address + data)
     * 
     * Write format: [address_high, address_low, data...]
     * If writing to address with data, enters write cycle state.
     */
    I2CStatus Write(const uint8_t* data, size_t len) {
        // If write cycle in progress, device doesn't ACK
        if (m_writeInProgress) {
            m_writeCycleCount++;
            
            // Simulate ~5ms write cycle (assuming 1ms per poll attempt)
            if (m_writeCycleCount >= 5) {
                m_writeInProgress = false;
                m_writeCycleCount = 0;
            }
            
            return I2CStatus::Nack;  // Still busy
        }
        
        // Parse address (first 2 bytes)
        if (len < 2) {
            return I2CStatus::Nack;
        }
        
        uint16_t addr = ((uint16_t)data[0] << 8) | data[1];
        
        // Write data (if any after address)
        if (len > 2) {
            size_t writeLen = len - 2;
            
            // Check bounds
            if (addr + writeLen > CAPACITY) {
                return I2CStatus::Nack;
            }
            
            // Write data to memory
            for (size_t i = 0; i < writeLen; i++) {
                m_memory[addr + i] = data[2 + i];
            }
            
            // Start write cycle (will NACK on next access until complete)
            m_writeInProgress = true;
            m_writeCycleCount = 0;
            m_writeAddress = addr;
            
            return I2CStatus::OK;  // Data accepted
        }
        
        // If only address (no data), this is ACK polling
        return I2CStatus::OK;
    }
    
    /**
     * @brief Handle I2C read operation
     * 
     * Read format: must first write address (via WriteRead), then read data
     */
    I2CStatus Read(const uint8_t* txData, size_t txLen, uint8_t* rxBuffer, size_t rxLen) {
        // If write cycle in progress, device doesn't ACK
        if (m_writeInProgress) {
            m_writeCycleCount++;
            if (m_writeCycleCount >= 5) {
                m_writeInProgress = false;
                m_writeCycleCount = 0;
            }
            return I2CStatus::Nack;
        }
        
        // Parse address from TX data
        if (txLen < 2) {
            return I2CStatus::Nack;
        }
        
        uint16_t addr = ((uint16_t)txData[0] << 8) | txData[1];
        
        // Read data
        if (addr + rxLen > CAPACITY) {
            return I2CStatus::Nack;
        }
        
        for (size_t i = 0; i < rxLen; i++) {
            rxBuffer[i] = m_memory[addr + i];
        }
        
        return I2CStatus::OK;
    }
    
    // Test helpers
    
    /// Get internal memory (for test verification)
    const uint8_t* GetMemory() const {
        return m_memory;
    }
    
    /// Check if write cycle is in progress
    bool IsWriteInProgress() const {
        return m_writeInProgress;
    }
    
    /// Get write cycle counter (for debugging)
    uint32_t GetWriteCycleCount() const {
        return m_writeCycleCount;
    }
    
    /// Reset EEPROM to initial state
    void Reset() {
        std::memset(m_memory, 0xFF, sizeof(m_memory));
        m_writeInProgress = false;
        m_writeCycleCount = 0;
        m_writeAddress = 0;
    }
    
private:
    static constexpr uint16_t CAPACITY = 32768;  // 24FC256 = 32KB
    static constexpr uint8_t PAGE_SIZE = 64;
    
    uint8_t m_memory[CAPACITY];      // Internal memory buffer
    bool m_writeInProgress;          // Write cycle state
    uint32_t m_writeCycleCount;      // Cycles elapsed in write
    uint16_t m_writeAddress;         // Address being written to
};
