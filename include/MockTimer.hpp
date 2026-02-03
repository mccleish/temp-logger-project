/**
 * @file MockTimer.hpp
 * @brief Mock timer for unit testing without hardware
 * 
 * Allows manual control of time progression:
 * - Tests can advance time without waiting
 * - Verifies 10-minute logging interval logic
 * - Does not actually wait 10 minutes. Time is simulated. Real hardware would use SysTick / interrupts.
 * 
 * Usage in tests:
 *   MockTimer timer;
 *   timer.Init();
 *   
 *   // Simulate 601 seconds passing
 *   for (int i = 0; i < 601; i++) {
 *       timer.Tick();
 *   }
 *   
 *   // Verify logging happened
 *   assert(timer.GetElapsedSeconds() == 601);
 */

#pragma once
#include "ITimer.hpp"
#include <cstdint>

class MockTimer : public ITimer {
public:
    MockTimer() : m_tickCount(0) {
    }
    
    void Init() override {
        m_tickCount = 0;
    }
    
    uint32_t GetElapsedSeconds() const override {
        return m_tickCount;
    }
    
    /**
     * @brief Manually advance time by 1 second
     * 
     * Called from test code to simulate timer ticks
     */
    void Tick() {
        m_tickCount++;
    }
    
    /**
     * @brief Advance time by N seconds (helper)
     * 
     * @param seconds Number of seconds to advance
     */
    void AdvanceTime(uint32_t seconds) {
        m_tickCount += seconds;
    }
    
    /**
     * @brief Reset timer to 0 (for multiple test cases)
     */
    void Reset() {
        m_tickCount = 0;
    }
    
private:
    uint32_t m_tickCount;
};
