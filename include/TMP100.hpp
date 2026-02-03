/**
 * @file TMP100.hpp
 * @brief TMP100 temperature sensor driver
 * 
 * Specs: -55 to +125 deg C, 12-bit (0.0625 deg C resolution), I2C interface
 * 
 * Uses: 12-bit continuous mode, register-based I2C interface
 */

#pragma once
#include "II2CController.hpp"
#include <cstdint>

class TMP100 {
public:
    enum class Resolution : uint8_t {
        Bits_9  = 0x00,  
        Bits_10 = 0x20,  
        Bits_11 = 0x40,  
        Bits_12 = 0x60   // Used in this driver
    };
    
    /// Constructor takes I2C controller and device address
    TMP100(II2CController& i2c, uint8_t address);
    
    /// Initialize sensor to 12-bit continuous mode
    bool Init();
    
    /// Read temperature (returns -999.0f on I2C error)
    float ReadTemperature();

private:
    static constexpr uint8_t REG_TEMPERATURE = 0x00;
    static constexpr uint8_t REG_CONFIG      = 0x01;
    static constexpr uint8_t REG_TLOW        = 0x02;
    static constexpr uint8_t REG_THIGH       = 0x03;
    
    static constexpr uint8_t CFG_SHUTDOWN    = 0x01;
    static constexpr uint8_t CFG_ONESHOT     = 0x80;
    static constexpr uint8_t CFG_RESOLUTION  = 0x60;
    
    II2CController& m_i2c;
    uint8_t m_address;
    uint8_t m_configCache;
    
    bool WriteConfig(uint8_t value);
};

// Implementation: inline functions

inline TMP100::TMP100(II2CController& i2c, uint8_t address)
    : m_i2c(i2c), m_address(address), m_configCache(0) {
}

inline bool TMP100::Init() {
    // Config = 0x60: 12-bit mode, continuous conversion
    const uint8_t config = static_cast<uint8_t>(Resolution::Bits_12);

    /*
    Bit	Value	Meaning
    SD	0	continuous mode
    TM	0	comparator
    POL	0	active low
    Fault	0	1 fault
    R1:R0	11	12-bit
    OS	0	ignored
    */
    return WriteConfig(config);
}

inline bool TMP100::WriteConfig(uint8_t value) {
    uint8_t tx[2] = { REG_CONFIG, value };
    
    if (m_i2c.Write(m_address, tx, sizeof(tx)) == I2CStatus::OK) {
        m_configCache = value;
        return true;
    }
    return false;
}

inline float TMP100::ReadTemperature() {
    uint8_t regAddr = REG_TEMPERATURE;
    uint8_t rawData[2] = {0, 0};
    
    I2CStatus status = m_i2c.WriteRead(m_address, &regAddr, 1, rawData, 2);
    
    if (status != I2CStatus::OK) {
        return -999.0f;  // Error sentinel (outside valid range)
    }
    
    // Combine bytes (big-endian), shift to get 12-bit value
    int16_t rawTemp = static_cast<int16_t>((rawData[0] << 8) | rawData[1]);

    rawTemp >>= 4;
    
    // Convert to Celsius (LSB = 0.0625 deg C)
    return static_cast<float>(rawTemp) * (1.0f / 16.0f);

}
