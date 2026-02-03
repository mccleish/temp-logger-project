/**
 * @file II2CController.hpp
 * @brief I2C bus communication interface
 * 
 * Abstract interface for I2C operations. Allows:
 * - Mock implementations for testing
 * - Easy swapping between bit-bang and hardware I2C
 * - Device drivers that don't depend on I2C implementation
 */

#pragma once
#include <cstdint>
#include <cstddef>

/// Status codes for I2C operations
enum class I2CStatus {
    OK,       ///< Success
    Error,    ///< General error (bus error, invalid params)
    Nack,     ///< Device did not acknowledge (not present or busy)
    Timeout   ///< Operation timed out
};

/// Abstract I2C controller interface
class II2CController {
public:
    virtual ~II2CController() = default;
    
    /// Write data to I2C device
    /// Transaction: START - ADDR+W - DATA[0..len-1] - STOP
    virtual I2CStatus Write(uint8_t addr, const uint8_t* data, size_t len) = 0;
    
    /// Read data from I2C device
    /// Transaction: START - ADDR+R - DATA[0..len-1] - STOP
    virtual I2CStatus Read(uint8_t addr, uint8_t* buffer, size_t len) = 0;
    
    /// Write then read (combined transaction with repeated START)
    /// Transaction: START - ADDR+W - TX[0..txLen-1] - REPEATED_START - ADDR+R - RX[0..rxLen-1] - STOP
    virtual I2CStatus WriteRead(uint8_t addr, 
                               const uint8_t* tx, size_t txLen,
                               uint8_t* rx, size_t rxLen) {
        // Default: separate Write then Read (some devices need true repeated START)
        if (Write(addr, tx, txLen) != I2CStatus::OK) {
            return I2CStatus::Error;
        }
        return Read(addr, rx, rxLen);
    }
};
