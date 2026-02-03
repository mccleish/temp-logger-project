/**
 * @file ITimer.hpp
 * @brief Abstract timer interface for 10-minute logging intervals
 * 
 * Allows swapping between:
 * - STM32Timer: Real hardware using SysTick
 * - MockTimer: Testing without hardware (manual tick control)
 */

#pragma once
#include <cstdint>

class ITimer {
public:
    virtual ~ITimer() = default;
    
    /**
     * @brief Initialize the timer
     * 
     * For STM32Timer: Configure SysTick for 1 Hz (1 second per tick)
     * For MockTimer: No-op
     */
    virtual void Init() = 0;
    
    /**
     * @brief Get elapsed seconds since initialization
     * 
     * @return Elapsed time in seconds (uint32_t, wraps at ~136 years)
     */
    virtual uint32_t GetElapsedSeconds() const = 0;
};
